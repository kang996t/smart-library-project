#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_root
require_executable "$MONGOSH"

for port in 27219 27211 27212 27200; do
    wait_for_ping "$port" 5 || die "Component $port is not ready; run start_cluster.sh first"
done

# Initial rs.initiate calls rely on MongoDB's localhost exception. If the
# components are already initialized and protected, these calls are skipped.
MONGO_AUTH_ARGS=()

init_single_member_rs() {
    local port="$1"
    local set_name="$2"
    local role="$3"
    echo "========== Initialize $role ($set_name) =========="
    if mongo_eval "$port" 'quit(rs.status().ok === 1 ? 0 : 1)' >/dev/null 2>&1; then
        echo "$set_name: ALREADY_INITIALIZED"
        return
    fi
    build_auth_args
    if [ "${#MONGO_AUTH_ARGS[@]}" -gt 0 ] && \
        mongo_eval "$port" 'quit(rs.status().ok === 1 ? 0 : 1)' >/dev/null 2>&1; then
        echo "$set_name: ALREADY_INITIALIZED"
        MONGO_AUTH_ARGS=()
        return
    fi
    MONGO_AUTH_ARGS=()
    mongo_eval "$port" "rs.initiate({_id:'$set_name',members:[{_id:0,host:'localhost:$port'}]})"
    ready=0
    for attempt in $(seq 1 60); do
        if mongo_eval "$port" 'quit(db.hello().isWritablePrimary ? 0 : 1)' \
            >/dev/null 2>&1; then
            ready=1
            break
        fi
        sleep 1
    done
    [ "$ready" -eq 1 ] || die "$set_name did not become PRIMARY"
}

init_single_member_rs 27219 configRS ConfigServer
init_single_member_rs 27211 shard1RS Shard1
init_single_member_rs 27212 shard2RS Shard2

echo "========== Configure mongos Administrator =========="
if [ -n "${MONGO_ADMIN_USER:-}" ] || [ -n "${MONGO_ADMIN_PASSWORD:-}" ]; then
    [ -n "${MONGO_ADMIN_USER:-}" ] || die "MONGO_ADMIN_USER is required"
    [ -n "${MONGO_ADMIN_PASSWORD:-}" ] || die "MONGO_ADMIN_PASSWORD is required"
    if "$MONGOSH" --quiet --host 127.0.0.1 --port 27200 \
        --eval '
          const admin=db.getSiblingDB("admin");
          const username=process.env.MONGO_ADMIN_USER;
          if (admin.getUser(username) === null) {
            admin.createUser({user:username,pwd:process.env.MONGO_ADMIN_PASSWORD,
              roles:[{role:"root",db:"admin"}]});
            print("ADMIN_CREATED");
          } else { print("ADMIN_ALREADY_EXISTS"); }
        '; then
        :
    else
        echo "Administrator may already exist; retrying with authentication..."
    fi
fi

build_auth_args

echo "========== Register Shards =========="
mongo_eval 27200 '
    const existing=db.adminCommand({listShards:1});
    if (!existing.ok) throw new Error("listShards failed");
    const names=new Set(existing.shards.map(s => s._id));
    if (!names.has("shard1RS")) printjson(sh.addShard("shard1RS/localhost:27211"));
    else print("shard1RS: ALREADY_REGISTERED");
    if (!names.has("shard2RS")) printjson(sh.addShard("shard2RS/localhost:27212"));
    else print("shard2RS: ALREADY_REGISTERED");
'

mongo_eval 27200 '
    const r=db.adminCommand({listShards:1});
    printjson(r.shards.map(s => ({name:s._id,host:s.host,state:s.state})));
    const names=new Set(r.shards.map(s => s._id));
    quit(r.ok === 1 && names.has("shard1RS") && names.has("shard2RS") ? 0 : 4);
'
echo "========== SHARDED_CLUSTER_BOOTSTRAP_COMPLETE =========="
