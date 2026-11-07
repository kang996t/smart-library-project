#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_executable "$MONGOSH"
build_auth_args
failures=0

echo "=================================="
echo " Smart Library - Cluster Health"
echo "=================================="
hostname
grep PRETTY_NAME /etc/os-release

echo "========== Component Status =========="
for item in \
    "ConfigServer:27219:mongod:$LAB/config/configsvr.conf" \
    "Shard1:27211:mongod:$LAB/config/shard1.conf" \
    "Shard2:27212:mongod:$LAB/config/shard2.conf" \
    "Mongos:27200:mongos:$LAB/config/mongos.conf"
do
    name=${item%%:*}
    rest=${item#*:}
    port=${rest%%:*}
    rest=${rest#*:}
    program=${rest%%:*}
    config=${rest#*:}
    pid=$(expected_pid "$program" "$config")
    if assert_single_pid "$pid" && wait_for_ping "$port" 2; then
        echo "$name port=$port pid=$pid: RUNNING PING_OK"
    else
        echo "$name port=$port: FAILED"
        failures=$((failures + 1))
    fi
done

echo "========== Router Topology =========="
if mongo_eval 27200 '
    const h=db.hello();
    const r=db.adminCommand({listShards:1});
    printjson({router:h.msg, shards:r.shards || [], ok:r.ok});
    const names=new Set((r.shards || []).map(s => s._id));
    quit(h.msg === "isdbgrid" && names.has("shard1RS") && names.has("shard2RS") ? 0 : 2);
'; then
    echo "ROUTER_TOPOLOGY: PASS"
elif [ "${#MONGO_AUTH_ARGS[@]}" -eq 0 ]; then
    echo "ROUTER_TOPOLOGY: NOT_CHECKED (set MONGO_ADMIN_USER and MONGO_ADMIN_PASSWORD)"
else
    echo "ROUTER_TOPOLOGY: FAIL"
    failures=$((failures + 1))
fi

echo "========== Memory =========="
free -h

if [ "$failures" -eq 0 ]; then
    echo "========== CLUSTER_HEALTH_PASS =========="
else
    echo "========== CLUSTER_HEALTH_FAIL count=$failures =========="
    exit 1
fi
