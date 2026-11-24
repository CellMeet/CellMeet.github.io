#!/usr/bin/env bash
# 新建内容
#
#   ./new.sh "标题" book "书名"      给指定书籍加一章
#   ./new.sh "标题" book             选书（或输入新书名）再加一章
#   ./new.sh "书名" book             新建一本书
#
#   ./new.sh "标题" movie "电影名"   给指定电影加一篇
#   ./new.sh "标题" movie            选电影（或输入新电影名）再加一篇
#   ./new.sh "电影名" movie          新建一部电影
#
#   ./new.sh "文章标题" essay         新建普通文章
#   ./new.sh                          交互式菜单
#
# 集合目录：content/posts/<book|movie>/<名称>/
#   Info.md    信息（标题、简介、封面），自己写
#   _index.md  Hugo 用，自动生成，不用管
set -euo pipefail
cd "$(dirname "$0")"

COLLECTIONS="book movie"

slugify() {
  printf '%s' "$1" |
    tr '/' '-' |
    tr '|' '-' |
    tr ':' '-' |
    tr '？?' '-' |
    tr -s ' ' '-' |
    sed 's/-\+/-/g; s/^-//; s/-$//'
}

now() {
  date '+%Y-%m-%dT%H:%M:%S%:z'
}

collection_root() {
  printf 'content/posts/%s\n' "$1"
}

collection_name() {
  case "$1" in
  book) echo "书" ;;
  movie) echo "电影" ;;
  *) echo "内容" ;;
  esac
}

list_items() {
  find "$(collection_root "$1")" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

find_item_dir() {
  local coll="$1"
  local want
  want="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]' | tr -d ' -_|:')"
  local b
  while IFS= read -r b; do
    local cur
    cur="$(printf '%s' "$b" | tr '[:upper:]' '[:lower:]' | tr -d ' -_|:')"
    if [ "$cur" = "$want" ]; then
      printf '%s\n' "$b"
      return 0
    fi
  done < <(list_items "$coll")
  return 1
}

print_items() {
  local coll="$1"
  local -a items=()
  local b
  while IFS= read -r b; do items+=("$b"); done < <(list_items "$coll")
  if [ ${#items[@]} -eq 0 ]; then
    echo "（现在还没有$(collection_name "$coll")）" >&2
    return 0
  fi
  echo "现有$(collection_name "$coll")：" >&2
  local i=1
  for b in "${items[@]}"; do
    printf '  %2d) %s\n' "$i" "$b" >&2
    i=$((i + 1))
  done
}

choose_or_create_item() {
  local coll="$1"
  local hint="${2:-}"
  local -a items=()
  local b
  while IFS= read -r b; do items+=("$b"); done < <(list_items "$coll")

  print_items "$coll"

  local prompt ans
  if [ -n "$hint" ]; then
    prompt="选编号 = 把「$hint」作为内容加入；输入新名字 = 新建$(collection_name "$coll")；回车 = 新建「$hint」: "
  else
    prompt="选编号，或输入新名字: "
  fi
  read -r -p "$prompt" ans

  if [[ "$ans" =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le ${#items[@]} ]; then
    printf '%s\n' "${items[ans - 1]}"
    return 0
  fi

  local name="$ans"
  if [ -z "$name" ]; then
    if [ -z "$hint" ]; then
      echo "没有输入名字" >&2
      return 1
    fi
    name="$hint"
  fi

  local existing
  if existing="$(find_item_dir "$coll" "$name")"; then
    printf '%s\n' "$existing"
    return 0
  fi

  local dir
  dir="$(create_item "$coll" "$name")" || return 1
  printf '%s\n' "$(basename "$dir")"
}

create_item() {
  local coll="${1:-}"
  local title="${2:-}"
  local root
  root="$(collection_root "$coll")"

  if [ -z "$title" ]; then
    echo "名字不能为空" >&2
    return 1
  fi

  local slug dir
  slug="$(slugify "$title")"
  dir="$root/$slug"

  if [ -e "$dir" ]; then
    echo "已存在: $dir" >&2
    printf '%s\n' "$dir"
    return 0
  fi

  mkdir -p "$dir"

  cat >"$dir/Info.md" <<EOF
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
EOF

  cat >"$dir/_index.md" <<EOF
---
title: "$title"
layout: "book"
categories: ["$coll"]
---
EOF

  echo "已创建$(collection_name "$coll"): $dir" >&2
  echo "  写简介: $dir/Info.md" >&2
  echo "  放封面: $dir/cover.jpg" >&2

  printf '%s\n' "$dir"
  return 0
}

create_entry() {
  local coll="${1:-}"
  local item_slug="${2:-}"
  local title="${3:-}"
  local root
  root="$(collection_root "$coll")"

  if [ -z "$item_slug" ]; then
    item_slug="$(choose_or_create_item "$coll" "$title")" || return 1
  fi

  local itemdir
  if [ -d "$root/$item_slug" ]; then
    itemdir="$root/$item_slug"
  elif itemdir="$(find_item_dir "$coll" "$item_slug")" && [ -n "$itemdir" ]; then
    itemdir="$root/$itemdir"
  else
    echo "找不到$(collection_name "$coll"): $item_slug" >&2
    echo "先新建: ./new.sh \"$item_slug\" $coll" >&2
    return 1
  fi
  item_slug="$(basename "$itemdir")"

  if [ -z "$title" ]; then
    read -r -p "标题: " title
  fi
  if [ -z "$title" ]; then
    echo "标题不能为空" >&2
    return 1
  fi

  local slug folder item_url slug_url file d file_title
  slug="$(slugify "$title" | tr '[:upper:]' '[:lower:]')"
  folder="$itemdir/$slug"
  item_url="$(printf '%s' "$item_slug" | tr '[:upper:]' '[:lower:]')"
  slug_url="$slug"
  file_title="$(printf '%s' "$title" | tr '/' '-')"
  file="$folder/$file_title.md"
  d="$(now)"

  if [ -e "$folder" ]; then
    echo "已存在: $folder" >&2
    return 1
  fi

  mkdir -p "$folder"
  cat >"$file" <<EOF
---
title: "$title"
date: "$d"
draft: false
url: "/posts/$coll/$item_url/$slug_url/"
categories: ["$coll"]
tags: []
summary: ""
---

EOF

  echo "已创建: $file" >&2
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
  cat >"$file" <<EOF
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

EOF

  echo "已创建: $file" >&2
  echo "图片直接放进 $dir/，Markdown 用 ![](图片.png) 引用。" >&2
  echo "继续写: 在 $(pwd) 输入 typora" >&2
  printf '%s\n' "$file"
}

is_collection() {
  case " $COLLECTIONS " in
  *" $1 "*) return 0 ;;
  *) return 1 ;;
  esac
}

add_to_collection() {
  local coll="$1"
  local arg1="$2"
  local arg3="${3:-}"

  if [ -n "$arg3" ]; then
    create_entry "$coll" "$arg3" "$arg1"
    return 0
  fi

  local item
  item="$(choose_or_create_item "$coll" "$arg1")" || exit 1

  # 输入的新名字和 arg1 相同 -> 只新建；否则 arg1 作为第一部分内容
  if [ "$(slugify "$item")" = "$(slugify "$arg1")" ]; then
    if [ -n "$arg1" ]; then
      echo " 添加内容: ./new.sh \"标题\" $coll \"$item\""
    fi
    exit 0
  fi
  create_entry "$coll" "$item" "$arg1"
}

interactive() {
  echo "1) 新建书籍"
  echo "2) 在书籍中添加一章"
  echo "3) 新建电影"
  echo "4) 在电影中添加一篇"
  echo "5) 新建普通文章"
  read -r -p "选择 [1-5]: " choice

  case "$choice" in
  1)
    read -r -p "书名: " title
    create_item book "$title" >/dev/null
    ;;
  2)
    local item
    item="$(choose_or_create_item book "")" || return
    create_entry book "$item" ""
    ;;
  3)
    read -r -p "电影名: " title
    create_item movie "$title" >/dev/null
    ;;
  4)
    local item
    item="$(choose_or_create_item movie "")" || return
    create_entry movie "$item" ""
    ;;
  5)
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
  create_item book "${2:-}" >/dev/null
  exit 0
  ;;
movie)
  create_item movie "${2:-}" >/dev/null
  exit 0
  ;;
chapter | entry)
  create_entry "${2:-book}" "$(slugify "${3:-}")" "${4:-}"
  exit 0
  ;;
esac

arg1="$1"
arg2="${2:-}"
arg3="${3:-}"

if is_collection "$arg2"; then
  add_to_collection "$arg2" "$arg1" "$arg3"
  exit 0
fi

create_post "$arg1" "${arg2:-essay}" >/dev/null
