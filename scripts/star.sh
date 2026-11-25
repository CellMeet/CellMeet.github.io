#!/usr/bin/env bash
# 新建一个收藏：star "名字"
set -euo pipefail
cd "$(dirname "$0")/.."

STAR_DIR="content/star"

slugify() {
  printf '%s' "$1" \
    | tr '/' '-' \
    | tr '|' '-' \
    | tr ':' '-' \
    | tr '？?' '-' \
    | tr -s ' ' '-' \
    | sed 's/-\+/-/g; s/^-//; s/-$//'
}

name="${1:-}"
if [ -z "$name" ]; then
  read -r -p "收藏名字: " name
fi
if [ -z "$name" ]; then
  echo "名字不能为空" >&2
  exit 1
fi

slug="$(slugify "$name")"
dir="$STAR_DIR/$slug"
date="$(date '+%F')"

if [ -e "$dir" ]; then
  echo "收藏已存在: $dir" >&2
  exit 1
fi

mkdir -p "$dir/music" "$dir/books" "$dir/images"

cat >"$dir/Info.md" <<INFO
---
title: "$name"
build:
  render: never
  list: never
date: "$date"
summary: ""
cover:
  image: "cover.jpg"
  alt: "《$name》"
links: []
---

在这里写这个收藏的介绍。
INFO

cat >"$dir/_index.md" <<INDEX
---
title: "$name"
build:
  render: never
  list: never
date: "$date"
layout: "star"
---
INDEX

echo "已创建收藏: $dir"
echo "  介绍: $dir/Info.md"
echo "  音乐: $dir/music/  （可建子文件夹作为专辑）"
echo "  书籍: $dir/books/  （放 PDF/EPUB）"
echo "  图片: $dir/images/"
echo "  链接: 写在 Info.md 的 links 里"
