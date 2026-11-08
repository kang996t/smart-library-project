#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_executable "$MONGOSH"
build_auth_args
[ "${#MONGO_AUTH_ARGS[@]}" -gt 0 ] || die \
    "Set MONGO_ADMIN_USER and MONGO_ADMIN_PASSWORD"
[ "${ALLOW_RS_RECONFIG:-}" = "YES" ] || die \
    "Set ALLOW_RS_RECONFIG=YES to confirm remove/re-add of localhost:27119"

primary_host=""
for port in 27117 27118 27119; do
    if candidate=$(mongo_eval "$port" 'print(db.hello().primary || "")' \
        2>/dev/null | tail -n 1) && [ -n "$candidate" ]; then
        primary_host="$candidate"
        break
    fi
done
[ -n "$primary_host" ] || die "Cannot determine current PRIMARY"
primary_port=${primary_host##*:}
[ "$primary_port" != "27119" ] || die \
    "Node3 is the current PRIMARY; restore a different PRIMARY before removing Node3"

echo "========== Remove Node3 =========="
mongo_eval "$primary_port" '
    const host="localhost:27119";
    if (rs.conf().members.some(m => m.host === host)) {
      printjson(rs.remove(host));
    } else {
      print("NODE3_ALREADY_REMOVED");
    }
'
sleep 5
mongo_eval "$primary_port" 'printjson(rs.status().members.map(m => ({name:m.name,state:m.stateStr,health:m.health})))'

echo "========== Re-add Node3 =========="
mongo_eval "$primary_port" '
    const host="localhost:27119";
    if (!rs.conf().members.some(m => m.host === host)) {
      printjson(rs.add({host:host, priority:1}));
    } else {
      print("NODE3_ALREADY_PRESENT");
    }
'

rejoined=0
for attempt in $(seq 1 120); do
    if mongo_eval "$primary_port" '
        const m=rs.status().members.find(x => x.name === "localhost:27119");
        quit(m && m.health === 1 && m.stateStr === "SECONDARY" ? 0 : 1);
    ' >/dev/null 2>&1; then
        rejoined=1
        break
    fi
    sleep 1
done
[ "$rejoined" -eq 1 ] || die "Node3 did not rejoin as SECONDARY"
mongo_eval "$primary_port" 'printjson(rs.status().members.map(m => ({name:m.name,state:m.stateStr,health:m.health})))'
echo "========== MEMBER_CHANGE_DRILL_PASS =========="
