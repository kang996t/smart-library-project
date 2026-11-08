#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_executable "$MONGOSH"
build_auth_args
[ "${#MONGO_AUTH_ARGS[@]}" -gt 0 ] || die \
    "Set MONGO_ADMIN_USER and MONGO_ADMIN_PASSWORD for acceptance verification"

failures=0
echo "========== Component Acceptance =========="
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
        echo "$name port=$port pid=$pid user=$MONGO_SERVICE_USER: PASS"
    else
        echo "$name port=$port: FAIL"
        failures=$((failures + 1))
    fi
done

echo "========== Authenticated Router and Shards =========="
if mongo_eval 27200 '
    const hello=db.hello();
    const auth=db.runCommand({connectionStatus:1}).authInfo.authenticatedUsers;
    const r=db.adminCommand({listShards:1});
    const names=new Set(r.shards.map(s => s._id));
    printjson({router:hello.msg, authenticatedUsers:auth, shards:r.shards});
    quit(hello.msg === "isdbgrid" && auth.length > 0 && names.has("shard1RS") &&
      names.has("shard2RS") ? 0 : 5);
'; then
    echo "ROUTER_AUTH_AND_SHARDS: PASS"
else
    echo "ROUTER_AUTH_AND_SHARDS: FAIL"
    failures=$((failures + 1))
fi

echo "========== Config Server Identity =========="
if mongo_eval 27219 '
    const h=db.hello();
    printjson({setName:h.setName, configsvr:h.configsvr, primary:h.primary});
    quit(h.setName === "configRS" && h.configsvr === 2 ? 0 : 6);
'; then
    echo "CONFIG_SERVER_IDENTITY: PASS"
else
    echo "CONFIG_SERVER_IDENTITY: FAIL"
    failures=$((failures + 1))
fi

if [ "$failures" -eq 0 ]; then
    echo "========== SHARDED_CLUSTER_ACCEPTANCE_PASS =========="
else
    echo "========== SHARDED_CLUSTER_ACCEPTANCE_FAIL count=$failures =========="
    exit 1
fi
