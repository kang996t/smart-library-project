#!/bin/bash

# Shared helpers for Member B MongoDB infrastructure scripts.
# This file is sourced by the executable scripts in this directory.

LAB=${LAB:-/opt/smart-library-b}
MONGO_BIN_DIR=${MONGO_BIN_DIR:-/export/servers/mongodb-8.3.11/bin}
MONGOSH_BIN_DIR=${MONGOSH_BIN_DIR:-/export/servers/mongosh-2.12.0/bin}
MONGOD=${MONGOD:-$MONGO_BIN_DIR/mongod}
MONGOS=${MONGOS:-$MONGO_BIN_DIR/mongos}
MONGOSH=${MONGOSH:-$MONGOSH_BIN_DIR/mongosh}
MONGO_SERVICE_USER=${MONGO_SERVICE_USER:-mongolab}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

require_root() {
    [ "$(id -u)" -eq 0 ] || die "Please run as root"
}

require_file() {
    [ -f "$1" ] || die "Missing file: $1"
}

require_executable() {
    [ -x "$1" ] || die "Missing executable: $1"
}

port_listening() {
    ss -lnt "( sport = :$1 )" | grep -q LISTEN
}

expected_pid() {
    local program="$1"
    local config="$2"
    ps -eo pid=,user=,comm=,args= | \
        awk -v u="$MONGO_SERVICE_USER" -v p="$program" -v c="$config" \
        '$2==u && $3==p && index($0,c)>0 {print $1}'
}

assert_single_pid() {
    local pid="$1"
    [ -n "$pid" ] || return 1
    [[ "$pid" =~ ^[0-9]+$ ]] || die "Invalid or multiple PIDs: $pid"
}

wait_for_ping() {
    local port="$1"
    local attempts="${2:-30}"
    local attempt
    for attempt in $(seq 1 "$attempts"); do
        if "$MONGOSH" --quiet --host 127.0.0.1 --port "$port" \
            --eval 'quit(db.adminCommand({ping:1}).ok === 1 ? 0 : 1)' \
            >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

start_component() {
    local name="$1"
    local port="$2"
    local program="$3"
    local config="$4"
    local binary="$MONGO_BIN_DIR/$program"
    local pid

    require_file "$config"
    require_executable "$binary"
    pid=$(expected_pid "$program" "$config")

    echo "========== Start $name ($port) =========="
    if port_listening "$port"; then
        assert_single_pid "$pid" || die "Port $port is occupied by an unexpected process"
        echo "$name: ALREADY_RUNNING pid=$pid"
    else
        [ -z "$pid" ] || die "$name process exists but port $port is not listening"
        runuser -u "$MONGO_SERVICE_USER" -- "$binary" --config "$config"
    fi

    wait_for_ping "$port" 30 || die "$name ping failed on port $port"
    echo "$name: PING_OK"
}

stop_component() {
    local name="$1"
    local port="$2"
    local program="$3"
    local config="$4"
    local pid
    local attempt

    echo "========== Stop $name ($port) =========="
    pid=$(expected_pid "$program" "$config")
    if [ -z "$pid" ]; then
        port_listening "$port" && die "Port $port is occupied by an unexpected process"
        echo "$name: ALREADY_STOPPED"
        return
    fi
    assert_single_pid "$pid"
    kill -TERM "$pid"
    for attempt in $(seq 1 30); do
        if ! kill -0 "$pid" 2>/dev/null; then
            echo "$name: STOPPED"
            return
        fi
        sleep 1
    done
    die "$name stop timeout (pid=$pid)"
}

build_auth_args() {
    MONGO_AUTH_ARGS=()
    if [ -n "${MONGO_ADMIN_USER:-}" ] || [ -n "${MONGO_ADMIN_PASSWORD:-}" ]; then
        [ -n "${MONGO_ADMIN_USER:-}" ] || die "MONGO_ADMIN_USER is required"
        [ -n "${MONGO_ADMIN_PASSWORD:-}" ] || die "MONGO_ADMIN_PASSWORD is required"
        MONGO_AUTH_ARGS=(
            --username "$MONGO_ADMIN_USER"
            --password "$MONGO_ADMIN_PASSWORD"
            --authenticationDatabase admin
        )
    fi
}

mongo_eval() {
    local port="$1"
    local javascript="$2"
    "$MONGOSH" --quiet --host 127.0.0.1 --port "$port" \
        "${MONGO_AUTH_ARGS[@]}" --eval "$javascript"
}
