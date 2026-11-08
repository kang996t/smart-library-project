#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
LAB=${LAB:-/opt/smart-library-b}
MODE=${1:---dry-run}

[ "$(id -u)" -eq 0 ] || { echo "ERROR: Please run as root" >&2; exit 1; }
case "$MODE" in
    --dry-run|--apply) ;;
    *) echo "Usage: $0 [--dry-run|--apply]" >&2; exit 2 ;;
esac

declare -a mappings=(
    "$REPO_ROOT/config/member-b/replica/node1.conf:$LAB/config/node1.conf"
    "$REPO_ROOT/config/member-b/replica/node2.conf:$LAB/config/node2.conf"
    "$REPO_ROOT/config/member-b/replica/node3.conf:$LAB/config/node3.conf"
    "$REPO_ROOT/config/member-b/sharding/configsvr.conf:$LAB/config/configsvr.conf"
    "$REPO_ROOT/config/member-b/sharding/shard1.conf:$LAB/config/shard1.conf"
    "$REPO_ROOT/config/member-b/sharding/shard2.conf:$LAB/config/shard2.conf"
    "$REPO_ROOT/config/member-b/sharding/mongos.conf:$LAB/config/mongos.conf"
)

for mapping in "${mappings[@]}"; do
    source_file=${mapping%%:*}
    target_file=${mapping#*:}
    [ -f "$source_file" ] || { echo "ERROR: Missing $source_file" >&2; exit 1; }
    echo "$source_file -> $target_file"
done

if [ "$MODE" = "--dry-run" ]; then
    echo "DRY_RUN_COMPLETE: no files changed"
    exit 0
fi

backup_dir="$LAB/config/backup-$(date -u +%Y%m%dT%H%M%SZ)"
install -d -o mongolab -g mongolab -m 0750 "$LAB/config" "$backup_dir"
for mapping in "${mappings[@]}"; do
    source_file=${mapping%%:*}
    target_file=${mapping#*:}
    if [ -f "$target_file" ]; then
        cp -a "$target_file" "$backup_dir/"
    fi
    install -o mongolab -g mongolab -m 0640 "$source_file" "$target_file"
done
echo "INSTALL_COMPLETE backup=$backup_dir"
