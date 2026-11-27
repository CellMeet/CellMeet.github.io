#!/usr/bin/env bash
# 启动本地编辑服务（网页“本地编辑”按钮依赖它）
set -euo pipefail
cd "$(dirname "$0")/.."
exec python3 scripts/edit_server.py "$@"
