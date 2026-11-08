#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_executable "$MONGOSH"
build_auth_args
failures=0

echo "========== Replica Process and Ping Checks =========="
for item in \
    "Node1:27117:$LAB/config/node1.conf" \
    "Node2:27118:$LAB/config/node2.conf" \
    "Node3:27119:$LAB/config/node3.conf"
do
    name=${item%%:*}
    rest=${item#*:}
    port=${rest%%:*}
    config=${rest#*:}
    pid=$(expected_pid mongod "$config")
    if assert_single_pid "$pid" && wait_for_ping "$port" 2; then
        echo "$name port=$port pid=$pid: PASS"
    else
        echo "$name port=$port: FAIL"
        failures=$((failures + 1))
    fi
done

echo "========== Replica Topology =========="
if mongo_eval 27117 '
    const s = rs.status();
    const members = s.members.map(m => ({name:m.name, state:m.stateStr, health:m.health}));
    printjson(members);
    const primary = members.filter(m => m.state === "PRIMARY" && m.health === 1).length;
    const secondary = members.filter(m => m.state === "SECONDARY" && m.health === 1).length;
    quit(primary === 1 && secondary === 2 ? 0 : 3);
'; then
    echo "REPLICA_TOPOLOGY: PASS"
else
    echo "REPLICA_TOPOLOGY: FAIL"
    failures=$((failures + 1))
fi

echo "========== Data Synchronization Sample =========="
counts=()
for port in 27117 27118 27119; do
    if count=$(mongo_eval "$port" '
        db.getMongo().setReadPref("secondaryPreferred");
        print(db.getSiblingDB("library_b_test").sync_test.countDocuments({}));
    ' 2>/dev/null | tail -n 1) && [[ "$count" =~ ^[0-9]+$ ]]; then
        counts+=("$count")
        echo "port=$port sync_test_count=$count"
    else
        echo "port=$port sync_test_count=READ_FAILED"
        failures=$((failures + 1))
    fi
done
if [ "${#counts[@]}" -eq 3 ] && \
    [ "${counts[0]}" = "${counts[1]}" ] && [ "${counts[1]}" = "${counts[2]}" ]; then
    echo "REPLICA_DATA_CONSISTENCY: PASS"
else
    echo "REPLICA_DATA_CONSISTENCY: FAIL"
    failures=$((failures + 1))
fi

if [ "$failures" -eq 0 ]; then
    echo "========== REPLICA_ACCEPTANCE_PASS =========="
else
    echo "========== REPLICA_ACCEPTANCE_FAIL count=$failures =========="
    exit 1
fi
