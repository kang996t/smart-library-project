#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=member_b_common.sh
source "$SCRIPT_DIR/member_b_common.sh"

require_root
require_executable "$MONGOSH"

echo "========== MongoDB Replica Set Startup =========="
start_component Node1 27117 mongod "$LAB/config/node1.conf"
start_component Node2 27118 mongod "$LAB/config/node2.conf"
start_component Node3 27119 mongod "$LAB/config/node3.conf"
echo "========== ALL_REPLICA_NODES_READY =========="
