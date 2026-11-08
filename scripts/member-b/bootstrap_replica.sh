#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_root
require_executable "$MONGOSH"

for port in 27117 27118 27119; do
    wait_for_ping "$port" 5 || die "Replica node $port is not ready; run start_replica.sh first"
done

echo "========== Replica Set Initialization =========="
MONGO_AUTH_ARGS=()
if mongo_eval 27117 'quit(rs.status().ok === 1 ? 0 : 1)' >/dev/null 2>&1; then
    echo "libraryRS: ALREADY_INITIALIZED"
else
    build_auth_args
    if [ "${#MONGO_AUTH_ARGS[@]}" -gt 0 ] && \
        mongo_eval 27117 'quit(rs.status().ok === 1 ? 0 : 1)' >/dev/null 2>&1; then
        echo "libraryRS: ALREADY_INITIALIZED"
    else
        # A fresh deployment has no users yet, so rs.initiate must use the
        # localhost exception even if future admin credentials are exported.
        MONGO_AUTH_ARGS=()
        mongo_eval 27117 '
            rs.initiate({
              _id: "libraryRS",
              members: [
                {_id: 0, host: "localhost:27117", priority: 2},
                {_id: 1, host: "localhost:27118", priority: 1},
                {_id: 2, host: "localhost:27119", priority: 1}
              ]
            })
        '
    fi
fi

echo "Waiting for PRIMARY..."
primary_ready=0
for attempt in $(seq 1 60); do
    if mongo_eval 27117 'quit(db.hello().isWritablePrimary ? 0 : 1)' \
        >/dev/null 2>&1; then
        primary_ready=1
        break
    fi
    sleep 1
done
[ "$primary_ready" -eq 1 ] || die "libraryRS did not elect Node1 as PRIMARY within 60 seconds"

if [ -n "${MONGO_ADMIN_USER:-}" ]; then
    echo "Ensuring replica-set administrator exists..."
    mongo_eval 27117 '
        const admin = db.getSiblingDB("admin");
        const username = process.env.MONGO_ADMIN_USER;
        if (admin.getUser(username) === null) {
          admin.createUser({
            user: username,
            pwd: process.env.MONGO_ADMIN_PASSWORD,
            roles: [{role: "root", db: "admin"}]
          });
          print("ADMIN_CREATED");
        } else {
          print("ADMIN_ALREADY_EXISTS");
        }
    '
    build_auth_args
else
    echo "WARNING: administrator creation skipped; set MONGO_ADMIN_USER and MONGO_ADMIN_PASSWORD"
fi

echo "========== REPLICA_BOOTSTRAP_COMPLETE =========="
