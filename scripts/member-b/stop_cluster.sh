
#!/bin/bash
set -euo pipefail

LAB=/opt/smart-library-b
BIN=/export/servers/mongodb-8.3.11/bin

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Please run as root"
    exit 1
fi

is_listening() {
    local port="$1"
    ss -H -lnt "( sport = :$port )" | grep -q LISTEN
}

stop_one() {
    local name="$1"
    local port="$2"
    local program="$3"
    local config="$4"
    local pidfile="$5"

    echo "========== $name ($port) =========="

    if ! is_listening "$port"; then
        echo "$name: ALREADY_STOPPED"
        return 0
    fi

    if [ ! -f "$pidfile" ]; then
        echo "ERROR: PID file missing"
        return 1
    fi

    local pid
    pid=$(cat "$pidfile")

    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid PID"
        return 1
    fi

    if [ ! -d "/proc/$pid" ]; then
        echo "ERROR: Process not found"
        return 1
    fi

    local exe
    exe=$(readlink -f "/proc/$pid/exe")

    if [ "$exe" != "$BIN/$program" ]; then
        echo "ERROR: Executable mismatch"
        return 1
    fi

    local owner
    owner=$(ps -o user= -p "$pid" | xargs)

    if [ "$owner" != "mongolab" ]; then
        echo "ERROR: Unexpected process owner"
        return 1
    fi

    if ! tr '\0' '\n' < "/proc/$pid/cmdline" | grep -Fxq "$config"; then
        echo "ERROR: Config path mismatch"
        return 1
    fi

    echo "Stopping $name PID=$pid"

    kill -TERM "$pid"

    for attempt in $(seq 1 30); do
        if ! kill -0 "$pid" 2>/dev/null && ! is_listening "$port"; then
            echo "$name: STOPPED"
            return 0
        fi
        sleep 1
    done

    echo "ERROR: $name did not stop"
    return 1
}

echo "========== MongoDB Cluster Shutdown =========="

stop_one Mongos 27200 mongos \
    "$LAB/config/mongos.conf" \
    "$LAB/mongos.pid"

stop_one Shard2 27212 mongod \
    "$LAB/config/shard2.conf" \
    "$LAB/sharding/shard2/mongod.pid"

stop_one Shard1 27211 mongod \
    "$LAB/config/shard1.conf" \
    "$LAB/sharding/shard1/mongod.pid"

stop_one ConfigServer 27219 mongod \
    "$LAB/config/configsvr.conf" \
    "$LAB/sharding/configsvr/mongod.pid"

echo "========== SHUTDOWN_COMPLETE =========="
