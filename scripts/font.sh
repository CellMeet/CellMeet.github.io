#!/usr/bin/env bash
# 安装界面中文字体（宋徽宗瘦金加粗版）
#
# 用法：
#   ./scripts/font.sh 字体.ttf
#
# 作用：
#   1. 按 GB2312 常用字 + 站内已用字符做子集，避免 30MB 原字体直接上线
#   2. 输出 static/fonts/shoujin.woff2
#   3. 站点自动使用，发布后生效
#
# 需要：python-fonttools + brotli（或 woff2_compress）

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="$root/static/fonts"

if [ "$#" -lt 1 ]; then
    echo "用法: ./scripts/font.sh 字体.ttf"
    exit 1
fi

src="$1"
if [ ! -f "$src" ]; then
    echo "找不到文件: $src"
    exit 1
fi

mkdir -p "$dest"

if python3 -c "import fontTools, brotli" >/dev/null 2>&1; then
    echo "正在生成子集（GB2312 常用字 + 站内字符）..."
    python3 - "$root" "$src" "$dest/shoujin.woff2" <<'PY'
import os, sys
from fontTools import subset

root, src, out = sys.argv[1], sys.argv[2], sys.argv[3]

chars = set()
for cp in range(0x4E00, 0xA000):
    ch = chr(cp)
    try:
        ch.encode('gb2312')
        chars.add(ch)
    except UnicodeEncodeError:
        pass

for base, _, files in os.walk(os.path.join(root, 'content')):
    for f in files:
        if f.endswith(('.md', '.html', '.yaml', '.yml', '.txt', '.json')):
            with open(os.path.join(base, f), encoding='utf-8', errors='ignore') as fh:
                chars.update(fh.read())
for base, _, files in os.walk(os.path.join(root, 'layouts')):
    for f in files:
        if f.endswith(('.html', '.json', '.yaml')):
            with open(os.path.join(base, f), encoding='utf-8', errors='ignore') as fh:
                chars.update(fh.read())

chars.update(chr(i) for i in range(32, 127))
chars.update('，。！？；：、“”‘’（）《》〈〉【】—…·￥％＋－×÷＝＃＠＆０１２３４５６７８９')
chars = {c for c in chars if c not in '\r\n\t'}

text_file = '/tmp/site-font-chars.txt'
with open(text_file, 'w', encoding='utf-8') as fh:
    fh.write(''.join(sorted(chars)))

args = [src, '--text-file=' + text_file, '--flavor=woff2',
        '--output-file=' + out, '--no-hinting']
subset.main(args)
print(f'字符数: {len(chars)}')
PY
else
    echo "未安装 fonttools，改用 woff2_compress（不会做子集，文件会很大）"
    if ! command -v woff2_compress >/dev/null 2>&1; then
        echo "缺少 woff2_compress（Arch: sudo pacman -S woff2）"
        exit 1
    fi
    cp "$src" "$dest/shoujin.ttf"
    ( cd "$dest" && woff2_compress shoujin.ttf >/dev/null )
fi

echo
ls -lh "$dest/shoujin.woff2"
echo "完成，执行 ./publish.sh 发布。"
