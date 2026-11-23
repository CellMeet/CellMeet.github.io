#!/usr/bin/env bash
# 新建内容
#
#   ./new.sh "章节名" books "书名"    给指定书籍加一章
#   ./new.sh "章节名" books           先选书（或输入新书名）再加一章
#   ./new.sh "书名" books             新建一本书
#   ./new.sh "文章标题" essay         新建普通文章
#   ./new.sh                          交互式菜单
#
# 书籍目录：content/posts/books/<书名>/
#   _Info.md   书籍信息（书名、简介、封面），自己写
#   _index.md  Hugo 用，自动生成，不用管
#   <章节名>/<章节名>.md + 图片
set -euo pipefail
cd "$(dirname "$0")"

BOOKS="content/posts/books"

slugify() {
  printf '%s' "$1" \
    | tr '/' '-' \
    | tr '|' '-' \
    | tr ':' '-' \
    | tr '？?' '-' \
    | tr -s ' ' '-' \
    | sed 's/-\+/-/g; s/^-//; s/-$//'
}

now() {
  date '+%Y-%m-%dT%H:%M:%S%:z'
}

list_books() {
  find "$BOOKS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

# 按名称找书（忽略大小写和连字符/空格差异）
find_book_dir() {
  local want
  want="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d ' -_|:')"
  local b
  while IFS= read -r b; do
    local cur
    cur="$(printf '%s' "$b" | tr '[:upper:]' '[:lower:]' | tr -d ' -_|:')"
    if [ "$cur" = "$want" ]; then
      printf '%s\n' "$b"
      return 0
    fi
  done < <(list_books)
  return 1
}

print_books() {
  local -a books=()
  local b
  while IFS= read -r b; do books+=("$b"); done < <(list_books)
  if [ ${#books[@]} -eq 0 ]; then
    echo "（现在还没有书）" >&2
    return 0
  fi
  echo "现有书籍：" >&2
  local i=1
  for b in "${books[@]}"; do
    printf '  %2d) %s\n' "$i" "$b" >&2
    i=$((i + 1))
  done
}

# 选书或新建书。输出最终的书目录名（不含路径）
choose_or_create_book() {
  local hint="${1:-}"
  local -a books=()
  local b
  while IFS= read -r b; do books+=("$b"); done < <(list_books)

  print_books

  local prompt ans
  if [ -n "$hint" ]; then
    prompt="选编号 = 把「$hint」作为章节加入；输入新书名 = 新建书；回车 = 新建「$hint」: "
  else
    prompt="选编号，或输入新书名: "
  fi
  read -r -p "$prompt" ans

  if [[ "$ans" =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le ${#books[@]} ]; then
    printf '%s\n' "${books[ans - 1]}"
    return 0
  fi

  local name="$ans"
  if [ -z "$name" ]; then
    if [ -z "$hint" ]; then
      echo "没有输入书名" >&2
      return 1
    fi
    name="$hint"
  fi

  local existing
  if existing="$(find_book_dir "$name")"; then
    printf '%s\n' "$existing"
    return 0
  fi

  local dir
  dir="$(create_book "$name")" || return 1
  printf '%s\n' "$(basename "$dir")"
}

create_book() {
  local title="${1:-}"
  if [ -z "$title" ]; then
    echo "书名不能为空" >&2
    return 1
  fi

  local slug dir d
  slug="$(slugify "$title")"
  dir="$BOOKS/$slug"

  if [ -e "$dir" ]; then
    echo "书已存在: $dir" >&2
    printf '%s\n' "$dir"
    return 0
  fi

  mkdir -p "$dir"
  d="$(now)"

  cat > "$dir/_Info.md" <<EOF
---
title: "$title"
build:
  render: never
  list: never
summary: ""
cover:
  image: "cover.jpg"
  alt: "《$title》封面"
---

在这里写这本书的简介。
EOF

  cat > "$dir/_index.md" <<EOF
---
title: "$title"
layout: "book"
---
EOF

  echo "已创建书籍: $dir" >&2
  echo "  写简介: $dir/_Info.md" >&2
  echo "  放封面: $dir/cover.jpg" >&2

  printf '%s\n' "$dir"
  return 0
}

create_chapter() {
  local book_slug="${1:-}"
  local title="${2:-}"

  if [ -z "$book_slug" ]; then
    book_slug="$(choose_or_create_book "$title")" || return 1
  fi

  local bookdir
  if [ -d "$BOOKS/$book_slug" ]; then
    bookdir="$BOOKS/$book_slug"
  elif bookdir="$(find_book_dir "$book_slug")" && [ -n "$bookdir" ]; then
    bookdir="$BOOKS/$bookdir"
  else
    echo "找不到书籍: $book_slug" >&2
    echo "先新建书籍: ./new.sh \"书名\" books" >&2
    return 1
  fi
  book_slug="$(basename "$bookdir")"

  if [ -z "$title" ]; then
    read -r -p "章节标题: " title
  fi
  if [ -z "$title" ]; then
    echo "章节标题不能为空" >&2
    return 1
  fi

  local slug folder book_url file d file_title
  slug="$(slugify "$title" | tr '[:upper:]' '[:lower:]')"
  folder="$bookdir/$slug"
  book_url="$(printf '%s' "$book_slug" | tr '[:upper:]' '[:lower:]')"
  slug_url="$slug"
  file_title="$(printf '%s' "$title" | tr '/' '-')"
  file="$folder/$file_title.md"
  d="$(now)"

  if [ -e "$folder" ]; then
    echo "章节已存在: $folder" >&2
    return 1
  fi

  mkdir -p "$folder"
  cat > "$file" <<EOF
---
title: "$title"
date: "$d"
draft: false
url: "/posts/books/$book_url/$slug_url/"
categories: ["books"]
tags: []
summary: ""
---

在这里写这一章的内容。
EOF

  echo "已创建章节: $file" >&2
  echo "  图片直接放进: $folder/" >&2
  echo "  继续写: 在 $(pwd) 输入 typora" >&2
}

create_post() {
  local title="${1:-}"
  local type="${2:-essay}"

  if [ -z "$title" ]; then
    echo "文章标题不能为空" >&2
    return 1
  fi

  local slug dir file d
  slug="$(slugify "$title")"
  dir="content/posts/$type/$slug"
  file="$dir/$slug.md"

  if [ -f "$file" ]; then
    echo "文章已存在: $file" >&2
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

  echo "已创建: $file" >&2
  echo "图片直接放进 $dir/，Markdown 用 ![](图片.png) 引用。" >&2
  echo "继续写: 在 $(pwd) 输入 typora" >&2
  printf '%s\n' "$file"
}

interactive() {
  echo "1) 新建书籍"
  echo "2) 在已有书籍中添加章节（会列出书籍）"
  echo "3) 新建普通文章"
  read -r -p "选择 [1-3]: " choice

  case "$choice" in
    1)
      read -r -p "书名: " title
      create_book "$title" >/dev/null
      ;;
    2)
      local book
      book="$(choose_or_create_book "")" || return
      create_chapter "$book" ""
      ;;
    3)
      local title type
      read -r -p "文章标题: " title
      read -r -p "类型（essay/leetcode/music/...）: " type
      create_post "$title" "$type" >/dev/null
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
    create_book "${2:-}" >/dev/null
    exit 0
    ;;
  chapter)
    create_chapter "$(slugify "${2:-}")" "${3:-}"
    exit 0
    ;;
esac

arg1="$1"
arg2="${2:-}"
arg3="${3:-}"

# 书籍相关：./new.sh "..." books ["书名"]
if [ "$arg2" = "books" ]; then
  if [ -n "$arg3" ]; then
    create_chapter "$arg3" "$arg1"
    exit 0
  fi

  book="$(choose_or_create_book "$arg1")" || exit 1

  # 输入的新书名和 arg1 相同 -> 只建书；否则 arg1 作为这一章
  if [ "$(slugify "$book")" = "$(slugify "$arg1")" ]; then
    if [ ! -e "$BOOKS/$book/$(slugify "$arg1")" ] && [ -n "$arg1" ] && [ -d "$BOOKS/$book" ]; then
      # 新书：只建书，提示下一步
      echo " 添加章节: ./new.sh \"章节名\" books \"$book\""
    fi
    exit 0
  fi
  create_chapter "$book" "$arg1"
  exit 0
fi

# 普通文章：./new.sh "标题" essay
create_post "$arg1" "${arg2:-essay}" >/dev/null
