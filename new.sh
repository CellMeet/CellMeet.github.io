#!/usr/bin/env bash
# 一键新建文章：./new.sh "文件夹名字" [类型，默认 essay]
# 生成 content/posts/<类型>/<文件夹>/<文件夹>.md
set -euo pipefail
cd "$(dirname "$0")"

if [ $# -lt 1 ]; then
  echo '用法: ./new.sh "文件夹名字" [类型，默认 essay]'
  echo '例如: ./new.sh "我的第一篇文章" essay'
  echo '类型可选: ai books essay golang java leetcode movies music security'
  exit 1
fi

name="$1"
type="${2:-essay}"
folder="$(printf '%s' "$name" | tr ' ' '-')"
dir="content/posts/$type/$folder"
file="$dir/$folder.md"

case "$type" in
  ai)       category="大模型" ;;
  books)    category="Books" ;;
  essay)    category="随笔" ;;
  golang)   category="Golang" ;;
  java)     category="Java" ;;
  leetcode) category="力扣" ;;
  movies)   category="电影" ;;
  music)    category="音乐" ;;
  security) category="网络攻防" ;;
  *)        category="$type" ;;
esac

if [ -f "$file" ]; then
  echo "文章已存在：$file"
else
  mkdir -p "$dir"
  now="$(date '+%Y-%m-%dT%H:%M:%S%:z')"
  cat > "$file" <<EOF
---
title: "$name"
date: "$now"
draft: false
url: "/posts/$type/$folder/"
categories: ["$category"]
tags: []
summary: ""
cover:
  image: ""
  alt: ""
---

在这里开始写正文。
EOF
  echo "已创建：$file"
  echo "图片直接放进 $dir/，Markdown 里用 ![](图片.png) 引用。"
fi

echo "写完后运行 ./publish.sh 发布。"

echo "继续写：在 $(pwd) 目录输入 typora（会自动打开最近修改的文章）"
