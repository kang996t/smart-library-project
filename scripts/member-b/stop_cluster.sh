#!/bin/bash
set -euo pipefail
LAB=/opt/smart-library-b
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Please run as root"
    exit 1
fi
stop_one() {
    local name="$1"
    local port="$2"
    local program="$3"
    local config="$4"
    echo "========== Stop $name ($port) =========="
    local pid
    pid=$(ps -eo pid=,user=,comm=,args= | \
        awk -v u="mongolab" -v p="$program" \
            -v c="$config" \
        '$2==u && $3==p && index($0,c)>0 {print $1}')
    if [ -z "$pid" ]; then
        if ss -lnt | grep -q ":$port "; then
            echo "ERROR: port occupied by unknown process"
            exit 1
        fi
        echo "$name: ALREADY_STOPPED"
        return
    fi
    if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid or multiple PIDs: $pid"
        exit 1
    fi
    kill -TERM "$pid"
    local i
    for i in $(seq 1 30); do
        if ! kill -0 "$pid" 2>/dev/null; then
            echo "$name: STOPPED"
            return
        fi
        sleep 1
    done
    echo "ERROR: $name stop timeout"
    exit 1
}
echo "========== MongoDB Cluster Shutdown =========="
stop_one Mongos 27200 mongos \
    "$LAB/config/mongos.conf"
stop_one Shard2 27212 mongod \
    "$LAB/config/shard2.conf"
stop_one Shard1 27211 mongod \
    "$LAB/config/shard1.conf"
stop_one ConfigServer 27219 mongod \
    "$LAB/config/configsvr.conf"
echo "========== ALL_COMPONENTS_STOPPED =========="
