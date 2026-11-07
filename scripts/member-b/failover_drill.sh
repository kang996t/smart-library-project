#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_root
require_executable "$MONGOSH"
build_auth_args
[ "${#MONGO_AUTH_ARGS[@]}" -gt 0 ] || die \
    "Set MONGO_ADMIN_USER and MONGO_ADMIN_PASSWORD before the failover drill"
[ "${ALLOW_FAILOVER_DRILL:-}" = "YES" ] || die \
    "Set ALLOW_FAILOVER_DRILL=YES to confirm the controlled PRIMARY shutdown"

declare -A CONFIG_BY_PORT=(
    [27117]="$LAB/config/node1.conf"
    [27118]="$LAB/config/node2.conf"
    [27119]="$LAB/config/node3.conf"
)

primary_host=$(mongo_eval 27117 'print(db.hello().primary || "")' | tail -n 1)
primary_port=${primary_host##*:}
[[ "$primary_port" =~ ^2711[789]$ ]] || die "Cannot determine PRIMARY: $primary_host"

old_config=${CONFIG_BY_PORT[$primary_port]}
old_pid=$(expected_pid mongod "$old_config")
assert_single_pid "$old_pid" || die "Cannot identify PRIMARY process for port $primary_port"

started_epoch=$(date +%s)
started_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "FAILOVER_START_UTC=$started_iso"
echo "OLD_PRIMARY=$primary_host pid=$old_pid"
kill -TERM "$old_pid"

new_primary=""
for attempt in $(seq 1 90); do
    for port in 27117 27118 27119; do
        [ "$port" = "$primary_port" ] && continue
        if candidate=$(mongo_eval "$port" 'print(db.hello().isWritablePrimary ? db.hello().me : "")' \
            2>/dev/null | tail -n 1) && [ -n "$candidate" ]; then
            new_primary="$candidate"
            break 2
        fi
    done
    sleep 1
done
[ -n "$new_primary" ] || die "No new PRIMARY elected within 90 seconds"

elected_epoch=$(date +%s)
elected_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)
election_seconds=$((elected_epoch - started_epoch))
new_port=${new_primary##*:}
echo "NEW_PRIMARY=$new_primary"
echo "NEW_PRIMARY_UTC=$elected_iso"
echo "ELECTION_SECONDS=$election_seconds"

token="member-b-$(date -u +%Y%m%dT%H%M%SZ)"
mongo_eval "$new_port" "
    const c = db.getSiblingDB('library_b_test').failover_evidence;
    c.insertOne(
      {token:'$token', oldPrimary:'$primary_host', newPrimary:'$new_primary',
       electionSeconds:$election_seconds, createdAt:new Date()},
      {writeConcern:{w:'majority', wtimeout:10000}}
    );
    printjson(c.findOne({token:'$token'}));
"
echo "MAJORITY_WRITE_AND_READ: PASS"

start_component RecoveredNode "$primary_port" mongod "$old_config"
rejoined=0
for attempt in $(seq 1 90); do
    if mongo_eval "$new_port" "
        const m=rs.status().members.find(x => x.name.endsWith(':$primary_port'));
        quit(m && m.health === 1 && m.stateStr === 'SECONDARY' ? 0 : 1);
    " >/dev/null 2>&1; then
        rejoined=1
        break
    fi
    sleep 1
done
[ "$rejoined" -eq 1 ] || die "Recovered node did not return as SECONDARY"

echo "RECOVERED_NODE_ROLE=SECONDARY"
echo "========== FAILOVER_DRILL_PASS =========="
