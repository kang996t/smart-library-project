#!/bin/bash
echo "=================================="
echo " Smart Library - Cluster Health"
echo "=================================="
MONGOSH=/export/servers/mongosh-2.12.0/bin/mongosh
echo
echo "========== 系统信息 =========="
hostname
cat /etc/os-release | grep PRETTY_NAME
echo
echo "========== 组件运行状态 =========="
for item in \
    "ConfigServer:27219" \
    "Shard1:27211" \
    "Shard2:27212" \
    "Mongos:27200"
do
    name=${item%%:*}
    port=${item##*:}
    if ss -lnt | grep -q ":$port "; then
        echo "$name ($port): RUNNING"
    else
        echo "$name ($port): STOPPED"
    fi
done
echo
echo "========== MongoDB Ping =========="
for port in 27219 27211 27212 27200
do
    echo "Checking port $port"
    if "$MONGOSH" \
        --quiet \
        --host 127.0.0.1 \
        --port "$port" \
        --eval 'quit(db.adminCommand({ping:1}).ok === 1 ? 0 : 1)' \
        >/dev/null 2>&1
    then
        echo "PORT $port : PING_OK"
    else
        echo "PORT $port : PING_FAILED"
    fi
done
echo
echo "========== 内存信息 =========="
free -h
echo
echo "========== 检查完成 =========="
