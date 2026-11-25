#!/usr/bin/env bash
# 新建内容
#
#   ./new.sh "标题" book "书名"      给指定书籍加一章
#   ./new.sh "标题" book I feel      打开选择器并预填搜索词
#   ./new.sh "标题" book             选书（或输入新书名）再加一章
#   ./new.sh "书名" book             新建一本书
#
#   ./new.sh "标题" movie "电影名"   给指定电影加一篇
#   ./new.sh "标题" movie I feel     打开选择器并预填搜索词
#   ./new.sh "标题" movie            选电影（或输入新电影名）再加一篇
#   ./new.sh "电影名" movie          新建一部电影
#
#   ./new.sh "文章标题" essay         新建普通文章
#   ./new.sh                          交互：标题 -> 类型 -> 书名/电影名（行内候选）
#
# 集合目录：content/posts/<book|movie>/<名称>/
#   Info.md    信息（标题、简介、封面），自己写
#   _index.md  Hugo 用，自动生成，不用管
set -euo pipefail
cd "$(dirname "$0")"

SELF_DIR="$(pwd)"
PICKER_INLINE="$SELF_DIR/scripts/pick_inline.py"
WIZARD="$SELF_DIR/scripts/new_wizard.py"

COLLECTIONS="book movie CS"

slugify() {
  printf '%s' "$1" |
    tr '/' '-' |
    tr '|' '-' |
    tr ':' '-' |
    sed 's/？/-/g; s/?/-/g' |
    tr -s ' ' '-' |
    sed 's/-\+/-/g; s/^-//; s/-$//'
}

now() {
  date '+%Y-%m-%dT%H:%M:%S%:z'
}

collection_root() {
  printf 'content/posts/%s\n' "$1"
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

write_item_meta() {
  local coll="$1"
  local dir="$2"
  local title="$3"

  cat >"$dir/Info.md" <<EOF
---
title: "$title"
build:
  render: never
  list: never
summary: ""
link: ""
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
    if [ ! -f "$dir/Info.md" ] || [ ! -f "$dir/_index.md" ]; then
      write_item_meta "$coll" "$dir" "$title"
      echo "已补全$(collection_name "$coll")信息: $dir" >&2
    else
      echo "已存在: $dir" >&2
    fi
    printf '%s\n' "$dir"
    return 0
  fi

  mkdir -p "$dir"
  write_item_meta "$coll" "$dir" "$title"

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
  if [ ! -f "$itemdir/Info.md" ] || [ ! -f "$itemdir/_index.md" ]; then
    write_item_meta "$coll" "$itemdir" "$item_slug"
  fi

  if [ -z "$title" ]; then
    read -r -p "标题: " title
  fi
  if [ -z "$title" ]; then
    echo "标题不能为空" >&2
    return 1
  fi

  local slug folder item_url slug_url file d file_title coll_url
  slug="$(slugify "$title" | tr '[:upper:]' '[:lower:]')"
  folder="$itemdir/$slug"
  coll_url="$(printf '%s' "$coll" | tr '[:upper:]' '[:lower:]')"
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
url: "/posts/$coll_url/$item_url/$slug_url/"
categories: ["$coll"]
tags: []
summary: ""
---

# $title
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

# $title
EOF

  echo "已创建: $file" >&2
  echo "图片直接放进 $dir/，Markdown 用 ![](图片.png) 引用。" >&2
  echo "继续写: 在 $(pwd) 输入 typora" >&2
  printf '%s\n' "$file"
}

is_collection() {
  local want lower_all
  want="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  lower_all="$(printf '%s' "$COLLECTIONS" | tr '[:upper:]' '[:lower:]')"
  case " $lower_all " in
  *" $want "*) return 0 ;;
  *) return 1 ;;
  esac
}

resolve_collection() {
  local want lower
  want="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  local d
  while IFS= read -r d; do
    lower="$(printf '%s' "$d" | tr '[:upper:]' '[:lower:]')"
    if [ "$lower" = "$want" ]; then
      printf '%s\n' "$d"
      return 0
    fi
  done < <(find content/posts -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)
  printf '%s\n' "$1"
}

collection_name() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
  book) echo "书" ;;
  movie) echo "电影" ;;
  cs) echo "detail" ;;
  *) echo "内容" ;;
  esac
}

add_to_collection() {
  local coll
  coll="$(resolve_collection "$1")"
  local arg1="$2"
  local query="${3:-}"

  # 书名和后缀参数完全匹配时，直接加内容，不弹选择器
  if [ -n "$query" ]; then
    local exact
    if exact="$(find_item_dir "$coll" "$query")"; then
      create_entry "$coll" "$exact" "$arg1"
      return 0
    fi
  fi

  local item
  item="$(choose_or_create_item "$coll" "$arg1" "$query")" || exit 1

  # 输入的新名字和 arg1 相同 -> 只新建；否则 arg1 作为第一部分内容
  if [ "$(slugify "$item")" = "$(slugify "$arg1")" ]; then
    if [ -n "$arg1" ]; then
      echo " 添加内容: ./new.sh \"标题\" $coll \"$item\""
    fi
    exit 0
  fi
  create_entry "$coll" "$item" "$arg1"
}

list_types() {
  find content/posts -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

use_inline_picker() {
  [ -f "$PICKER_INLINE" ] && command -v python3 >/dev/null 2>&1 && [ "${TERM:-x}" != "dumb" ] && { [ -t 1 ] || [ -t 0 ] || { true </dev/tty; } 2>/dev/null; }
}

pick_type() {
  local types choice rc=0
  types="$(list_types)"

  if use_inline_picker; then
    choice="$(printf '%s\n' "$types" | python3 "$PICKER_INLINE" --prompt "类型: ")" || rc=$?
    if [ "${rc:-0}" -eq 0 ]; then
      printf '%s\n' "$choice"
      return 0
    fi
    if [ "${rc:-0}" -eq 1 ]; then
      return 1
    fi
  fi

  local -a arr=()
  local b
  while IFS= read -r b; do [ -n "$b" ] && arr+=("$b"); done <<<"$types"
  local i=1
  for b in "${arr[@]}"; do
    printf '  %d) %s\n' "$i" "$b" >&2
    i=$((i + 1))
  done
  read -r -p "选择类型编号: " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#arr[@]} ]; then
    printf '%s\n' "${arr[choice - 1]}"
    return 0
  fi
  return 1
}

pick_item_name() {
  local coll="$1"
  local prompt="$2"
  local rc=0 choice

  if use_inline_picker; then
    choice="$(list_items "$coll" | python3 "$PICKER_INLINE" --prompt "$prompt: " --allow-new)" || rc=$?
    if [ "${rc:-0}" -eq 0 ]; then
      printf '%s\n' "$choice"
      return 0
    fi
    if [ "${rc:-0}" -eq 1 ]; then
      return 1
    fi
  fi

  read -r -p "$prompt: " choice
  [ -n "$choice" ] || return 1
  printf '%s\n' "$choice"
}

add_entry_flow() {
  local coll="$1"
  local label="$2"
  local title="$3"
  local name dir

  name="$(pick_item_name "$coll" "$label")" || return 1
  [ -n "$name" ] || return 1

  if [ "${name#NEW:}" != "$name" ]; then
    name="${name#NEW:}"
    [ -n "$name" ] || return 1
    dir="$(create_item "$coll" "$name")" || return 1
    create_entry "$coll" "$(basename "$dir")" "$title"
  else
    create_entry "$coll" "$name" "$title"
  fi
}

interactive() {
  local title="" category="" name="" out key val raw

  if [ -f "$WIZARD" ] && command -v python3 >/dev/null 2>&1 && [ "${TERM:-x}" != "dumb" ] && { [ -t 1 ] || [ -t 0 ] || { true </dev/tty; } 2>/dev/null; }; then
    out="$(python3 "$WIZARD")" || {
      echo "已取消" >&2
      return 1
    }
    while IFS=$'\x1f' read -r key val; do
      case "$key" in
      TITLE) title="$val" ;;
      CATEGORY) category="$val" ;;
      NAME) name="$val" ;;
      esac
    done <<<"$out"
  else
    # 非交互终端回退
    read -r -p 'title: ' raw
    title="$(printf '%s' "$raw" | sed -e 's/^"//' -e 's/"$//')"
    printf '%s\n' "$(list_types)" >&2
    read -r -p 'belong: ' category
    case "$(printf '%s' "$category" | tr '[:upper:]' '[:lower:]')" in
    book | movie | cs)
      local label
      label="$(collection_name "$category")"
      if [ "$label" = "detail" ]; then
        read -r -p "detail: " raw
      else
        read -r -p "输入$label名: " raw
      fi
      name="$(printf '%s' "$raw" | sed -e 's/^"//' -e 's/"$//')"
      ;;
    esac
  fi

  if [ -z "$title" ]; then
    echo "标题不能为空" >&2
    return 1
  fi
  if [ -z "$category" ]; then
    echo "belong 不能为空" >&2
    return 1
  fi

  case "$(printf '%s' "$category" | tr '[:upper:]' '[:lower:]')" in
  book | movie | cs)
    if [ -z "$name" ]; then
      echo "书名/电影名不能为空" >&2
      return 1
    fi
    if [ "${name#NEW:}" != "$name" ]; then
      name="${name#NEW:}"
      local dir
      dir="$(create_item "$category" "$name")" || return 1
      create_entry "$category" "$(basename "$dir")" "$title"
    else
      create_entry "$category" "$name" "$title"
    fi
    ;;
  *)
    create_post "$title" "$category" >/dev/null
    ;;
  esac
}

if [ $# -eq 0 ]; then
  interactive
  exit 0
fi

# 只输入 book / movie 时，直接打开对应选择器
if [ $# -eq 1 ] && { [ "$1" = "book" ] || [ "$1" = "movie" ]; }; then
  choose_or_create_item "$1" "" "" >/dev/null
  exit 0
fi

arg1="$1"
arg2="${2:-}"

if is_collection "$arg2"; then
  shift 2
  add_to_collection "$arg2" "$arg1" "$*"
  exit 0
fi

create_post "$arg1" "${arg2:-essay}" >/dev/null
