#!/usr/bin/env bash
# 添加友链：link <网址>
# 自动抓取网站名称和图标，图标保存到 static/img/links/，并写入 content/links.md
set -euo pipefail
cd "$(dirname "$0")/.."
exec python3 scripts/add_link.py "$@"
