
#!/bin/bash
set -euo pipefail

LAB=/opt/smart-library-b
MONGOD=/export/servers/mongodb-8.3.11/bin/mongod
MONGOSH=/export/servers/mongosh-2.12.0/bin/mongosh

echo "========== Smart Library Environment Check =========="

echo "OS:"
grep PRETTY_NAME /etc/os-release

echo "MongoDB:"
"$MONGOD" --version | head -n 1

echo "Mongosh:"
"$MONGOSH" --version

echo "========== User Check =========="
id mongolab

echo "========== Directory Check =========="

for dir in \
    "$LAB/config" \
    "$LAB/logs" \
    "$LAB/secrets" \
    "$LAB/replica/node1" \
    "$LAB/replica/node2" \
    "$LAB/replica/node3" \
    "$LAB/sharding/configsvr" \
    "$LAB/sharding/shard1" \
    "$LAB/sharding/shard2"
do
    if [ -d "$dir" ]; then
        echo "EXISTS: $dir"
    else
        echo "MISSING: $dir"
    fi
done

echo "========== Keyfile Check =========="

for file in \
    "$LAB/secrets/replica.key" \
    "$LAB/secrets/sharding.key"
do
    if [ -s "$file" ]; then
        stat -c "%U %G %a %n" "$file"
    else
        echo "MISSING: $file"
    fi
done

echo "========== Port Check =========="

for port in 27117 27118 27119 27219 27211 27212 27200; do
    if ss -lnt "( sport = :$port )" | grep -q LISTEN; then
        echo "$port IN_USE"
    else
        echo "$port FREE"
    fi
done

echo "========== ENVIRONMENT_CHECK_COMPLETE =========="