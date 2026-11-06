#!/bin/bash
set -euo pipefail
LAB=/opt/smart-library-b
BIN=/export/servers/mongodb-8.3.11/bin
SHELL_BIN=/export/servers/mongosh-2.12.0/bin/mongosh
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Please run as root"
    exit 1
fi
start_one() {
    name="$1"
    port="$2"
    program="$3"
    config="$4"
    echo "========== $name ($port) =========="
    if ss -lnt | grep -q ":$port "; then
        echo "$name: ALREADY_RUNNING"
    else
        echo "Starting $name..."
        runuser -u mongolab -- \
            "$BIN/$program" --config "$config"
    fi
    ready=0
    for attempt in $(seq 1 20); do
        if "$SHELL_BIN" --quiet \
            --host 127.0.0.1 \
            --port "$port" \
            --eval 'quit(db.adminCommand({ping:1}).ok === 1 ? 0 : 1)' \
            >/dev/null 2>&1; then
            ready=1
            break
        fi
        sleep 1
    done
    if [ "$ready" -eq 1 ]; then
        echo "$name: PING_OK"
    else
        echo "ERROR: $name PING_FAILED"
        exit 1
    fi
}
echo "========== MongoDB Cluster Startup =========="
start_one ConfigServer 27219 mongod "$LAB/config/configsvr.conf"
start_one Shard1 27211 mongod "$LAB/config/shard1.conf"
start_one Shard2 27212 mongod "$LAB/config/shard2.conf"
start_one Mongos 27200 mongos "$LAB/config/mongos.conf"
echo "========== ALL_COMPONENTS_READY =========="
