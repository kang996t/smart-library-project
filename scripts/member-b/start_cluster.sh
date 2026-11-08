#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_root
require_executable "$MONGOSH"

echo "========== MongoDB Sharded Cluster Startup =========="
start_component ConfigServer 27219 mongod "$LAB/config/configsvr.conf"
start_component Shard1 27211 mongod "$LAB/config/shard1.conf"
start_component Shard2 27212 mongod "$LAB/config/shard2.conf"
start_component Mongos 27200 mongos "$LAB/config/mongos.conf"
echo "========== ALL_COMPONENTS_READY =========="
