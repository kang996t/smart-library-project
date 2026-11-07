
#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"
failures=0

echo "========== Smart Library Environment Check =========="

echo "OS:"
grep PRETTY_NAME /etc/os-release

echo "MongoDB:"
require_executable "$MONGOD"
"$MONGOD" --version | head -n 1

echo "Mongosh:"
require_executable "$MONGOSH"
"$MONGOSH" --version

echo "========== User Check =========="
if id "$MONGO_SERVICE_USER"; then
    echo "SERVICE_USER: PASS"
else
    failures=$((failures + 1))
fi

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
        failures=$((failures + 1))
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
        failures=$((failures + 1))
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
if [ "$failures" -gt 0 ]; then
    echo "ENVIRONMENT_CHECK_FAIL count=$failures"
    exit 1
fi
echo "ENVIRONMENT_CHECK_PASS"
