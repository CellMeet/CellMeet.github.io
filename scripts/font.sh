#!/usr/bin/env bash
# 安装「曹溪·藏锋楷」字体文件
#
# 用法：
#   ./scripts/font.sh 常规体.ttf [粗体.ttf]
#
# 作用：
#   1. 把字体复制到 static/fonts/
#   2. 压缩成 woff2（体积更小，加载更快）
#   3. 站点会自动使用，无需改代码
#
# 完成后执行 ./publish.sh 发布即可。

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="$root/static/fonts"

if [ "$#" -lt 1 ]; then
    echo "用法: ./scripts/font.sh 常规体.ttf [粗体.ttf]"
    exit 1
fi

regular="$1"
bold="${2:-}"

if [ ! -f "$regular" ]; then
    echo "找不到文件: $regular"
    exit 1
fi

if ! command -v woff2_compress >/dev/null 2>&1; then
    echo "缺少 woff2_compress（Arch: sudo pacman -S woff2）"
    exit 1
fi

mkdir -p "$dest"

install_one() {
    local src="$1" base="$2"
    local ext="${src##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    cp "$src" "$dest/$base.$ext"
    case "$ext" in
        ttf|otf) woff2_compress "$dest/$base.$ext" >/dev/null ;;
        woff2) cp "$src" "$dest/$base.woff2" ;;
        *) echo "不支持的格式: $ext"; exit 1 ;;
    esac
    echo "已安装 $base.$ext"
}

install_one "$regular" "cangfengkai"

if [ -n "$bold" ]; then
    if [ ! -f "$bold" ]; then
        echo "找不到粗体文件: $bold"
        exit 1
    fi
    install_one "$bold" "cangfengkai-bold"
fi

echo
echo "字体已放入 static/fonts/，执行 ./publish.sh 发布即可。"
