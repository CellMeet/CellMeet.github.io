#!/usr/bin/env bash
# 新建内容：
#   ./new.sh                                  交互式菜单（推荐）
#   ./new.sh book "书名"                      新建一本书
#   ./new.sh chapter "书名" "章节名"          给书添加章节
#   ./new.sh "书名" books                     新建一本书（兼容旧习惯）
#   ./new.sh "章节名" books "书名"            给书添加章节
#   ./new.sh "文章标题" essay                  新建普通文章
set -euo pipefail
cd "$(dirname "$0")"

BOOKS="content/posts/books"

slugify() {
  printf '%s' "$1" | tr ' ' '-' | tr '/' '-'
}

now() {
  date '+%Y-%m-%dT%H:%M:%S%:z'
}

list_books() {
  find "$BOOKS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

choose_book() {
  local books=()
  local b
  while IFS= read -r b; do
    books+=("$b")
  done < <(list_books)

  if [ ${#books[@]} -eq 0 ]; then
    echo ""
    return 0
  fi

  PS3="选择书籍（输入编号）: "
  select b in "${books[@]}"; do
    if [ -n "${b:-}" ]; then
      echo "$b"
      return 0
    fi
  done
}

create_book() {
  local title="${1:-}"
  if [ -z "$title" ]; then
    echo "书名不能为空"
    return 1
  fi

  local slug dir d
  slug="$(slugify "$title")"
  dir="$BOOKS/$slug"

  if [ -e "$dir" ]; then
    echo "书已存在: $dir"
    echo "添加章节: ./new.sh chapter \"$title\" \"章节名\""
    return 1
  fi

  mkdir -p "$dir"
  d="$(now)"
  cat > "$dir/_index.md" <<EOF
---
title: "$title"
date: "$d"
layout: "book"
categories: ["books"]
tags: []
summary: ""
cover:
  image: "cover.jpg"
  alt: "$title"
---

在这里写这本书的简介。
EOF

  echo "已创建书籍: $dir/_index.md"
  echo "把封面图片保存为: $dir/cover.jpg"
  echo "添加章节: ./new.sh chapter \"$title\" \"章节名\""
}

create_chapter() {
  local book_slug="${1:-}"
  local title="${2:-}"

  if [ -z "$book_slug" ]; then
    book_slug="$(choose_book)"
    if [ -z "$book_slug" ]; then
      echo "还没有书籍，先新建一本书: ./new.sh book \"书名\""
      return 1
    fi
  fi

  if [ -z "$title" ]; then
    read -r -p "章节标题: " title
  fi
  if [ -z "$title" ]; then
    echo "章节标题不能为空"
    return 1
  fi

  local bookdir="$BOOKS/$book_slug"
  if [ ! -d "$bookdir" ]; then
    echo "找不到书籍: $book_slug"
    echo "先创建书籍: ./new.sh book \"书名\""
    return 1
  fi

  local slug dir d
  slug="$(slugify "$title")"
  dir="$bookdir/$slug"

  if [ -e "$dir" ]; then
    echo "章节已存在: $dir"
    return 1
  fi

  mkdir -p "$dir"
  d="$(now)"
  cat > "$dir/index.md" <<EOF
---
title: "$title"
date: "$d"
draft: false
categories: ["books"]
tags: []
summary: ""
---

在这里写这一章的内容。
EOF

  echo "已创建章节: $dir/index.md"
  echo "图片直接放到: $dir/"
  echo "继续写: 在 $(pwd) 输入 typora"
}

create_post() {
  local title="${1:-}"
  local type="${2:-essay}"

  if [ -z "$title" ]; then
    echo "文章标题不能为空"
    return 1
  fi

  local slug dir file d
  slug="$(slugify "$title")"
  dir="content/posts/$type/$slug"
  file="$dir/$slug.md"

  if [ -f "$file" ]; then
    echo "文章已存在: $file"
    return 1
  fi

  mkdir -p "$dir"
  d="$(now)"
  cat > "$file" <<EOF
---
title: "$title"
date: "$d"
draft: false
url: "/posts/$type/$slug/"
categories: ["$type"]
tags: []
summary: ""
cover:
  image: ""
  alt: ""
---

在这里开始写正文。
EOF

  echo "已创建: $file"
  echo "图片直接放进 $dir/，Markdown 用 ![](图片.png) 引用。"
  echo "继续写: 在 $(pwd) 输入 typora"
}

interactive() {
  echo "1) 新建书籍"
  echo "2) 在已有书籍中添加章节"
  echo "3) 新建普通文章"
  read -r -p "选择 [1-3]: " choice

  case "$choice" in
    1)
      read -r -p "书名: " title
      create_book "$title"
      ;;
    2)
      local book title
      book="$(choose_book)"
      if [ -z "$book" ]; then
        echo "还没有书籍，先新建一本书吧。"
        return
      fi
      read -r -p "章节标题: " title
      create_chapter "$book" "$title"
      ;;
    3)
      local title type
      read -r -p "文章标题: " title
      read -r -p "类型（essay/leetcode/music/...）: " type
      create_post "$title" "$type"
      ;;
    *)
      echo "无效选择"
      ;;
  esac
}

if [ $# -eq 0 ]; then
  interactive
  exit 0
fi

case "$1" in
  book)
    create_book "${2:-}"
    exit 0
    ;;
  chapter)
    create_chapter "$(slugify "${2:-}")" "${3:-}"
    exit 0
    ;;
esac

arg1="$1"
arg2="${2:-}"

# 兼容：./new.sh "书名" books  /  ./new.sh "章节名" books "书名"
if [ "$arg2" = "books" ]; then
  if [ $# -ge 3 ]; then
    create_chapter "$(slugify "$3")" "$arg1"
  else
    create_book "$arg1"
  fi
  exit 0
fi

# 普通文章：./new.sh "标题" essay
create_post "$arg1" "${arg2:-essay}"
