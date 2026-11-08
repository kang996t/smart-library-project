#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_root

echo "========== MongoDB Sharded Cluster Shutdown =========="
stop_component Mongos 27200 mongos "$LAB/config/mongos.conf"
stop_component Shard2 27212 mongod "$LAB/config/shard2.conf"
stop_component Shard1 27211 mongod "$LAB/config/shard1.conf"
stop_component ConfigServer 27219 mongod "$LAB/config/configsvr.conf"
echo "========== ALL_COMPONENTS_STOPPED =========="
