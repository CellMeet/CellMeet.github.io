#!/usr/bin/env bash
# 新建收藏：star [类型] [标题] [链接]
#   类型：page/course/book 或 网页/课程/书籍
set -euo pipefail
cd "$(dirname "$0")/.."

STAR_DIR="content/star"
PICKER_INLINE="scripts/pick_inline.py"

slugify() {
  printf '%s' "$1" \
    | tr '/' '-' \
    | tr '|' '-' \
    | tr ':' '-' \
    | tr '？?' '-' \
    | tr -s ' ' '-' \
    | sed 's/-\+/-/g; s/^-//; s/-$//'
}

yaml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

strip_quotes() {
  local s="$1"
  s="${s#\"}"
  s="${s%\"}"
  printf '%s' "$s"
}

type_key() {
  case "$1" in
    page|Page|网页|网站) echo "page" ;;
    course|Course|课程) echo "course" ;;
    book|Book|书籍|书) echo "book" ;;
    *) echo "" ;;
  esac
}

type_title() {
  case "$1" in
    page) echo "Page" ;;
    course) echo "Course" ;;
    book) echo "Book" ;;
  esac
}

ensure_base() {
  mkdir -p "$STAR_DIR"
  if [ ! -f "$STAR_DIR/_index.md" ]; then
    cat >"$STAR_DIR/_index.md" <<'INDEX'
---
title: "收藏"
layout: "star-list"
---
INDEX
  fi
}

ensure_type() {
  local key="$1"
  local title
  title="$(type_title "$key")"
  mkdir -p "$STAR_DIR/$key"
  if [ ! -f "$STAR_DIR/$key/_index.md" ]; then
    cat >"$STAR_DIR/$key/_index.md" <<INDEX
---
title: "$title"
layout: "star-type"
---
INDEX
  fi
}

pick_type() {
  if [ -f "$PICKER_INLINE" ] && command -v python3 >/dev/null 2>&1 && [ "${TERM:-x}" != "dumb" ] && { [ -t 1 ] || [ -t 0 ] || { true </dev/tty; } 2>/dev/null; }; then
    printf 'Page\nCourse\nBook\n' | python3 "$PICKER_INLINE" --prompt "belong: "
    return $?
  fi

  echo "belong：" >&2
  echo "  1) Page" >&2
  echo "  2) Course" >&2
  echo "  3) Book" >&2
  local n
  read -r -p "选择 [1-3]: " n
  case "$n" in
    1) echo "Page" ;;
    2) echo "Course" ;;
    3) echo "Book" ;;
    *) return 1 ;;
  esac
}

type_arg=""
title=""
link=""
prompted=0

if [ $# -eq 0 ]; then
  prompted=1
else
  if [ -n "$(type_key "$1")" ]; then
    type_arg="$(type_key "$1")"
    shift
    title="${1:-}"
    [ $# -gt 0 ] && shift
    link="$*"
  elif [ $# -ge 2 ] && [ -n "$(type_key "$2")" ]; then
    title="$1"
    type_arg="$(type_key "$2")"
    shift 2
    link="$*"
  else
    title="$1"
    shift
    link="$*"
  fi
fi

title="$(strip_quotes "$title")"
link="$(strip_quotes "$link")"

if [ -z "$title" ]; then
  read -r -p "title: " title
  title="$(strip_quotes "$title")"
  prompted=1
fi
if [ -z "$title" ]; then
  echo "标题不能为空" >&2
  exit 1
fi

if [ -z "$type_arg" ]; then
  label="$(pick_type)" || { echo "未选择 belong" >&2; exit 1; }
  type_arg="$(type_key "$label")"
  if [ -z "$type_arg" ]; then
    echo "belong 无效: $label" >&2
    exit 1
  fi
  prompted=1
fi

if [ -z "$link" ] && [ "$prompted" -eq 1 ]; then
  read -r -p "link（可留空）: " link
  link="$(strip_quotes "$link")"
fi

case "$link" in
  "") ;;
  http://*|https://*) ;;
  *) link="https://$link" ;;
esac

ensure_base
ensure_type "$type_arg"
label="$(type_title "$type_arg")"

slug="$(slugify "$title")"
dir="$STAR_DIR/$type_arg/$slug"
date="$(date '+%F')"

if [ -e "$dir" ]; then
  echo "收藏已存在: $dir" >&2
  exit 1
fi

mkdir -p "$dir/music" "$dir/books" "$dir/images"

title_esc="$(yaml_escape "$title")"
link_esc="$(yaml_escape "$link")"

cat >"$dir/Info.md" <<INFO
---
title: "$title_esc"
build:
  render: never
  list: never
date: "$date"
summary: ""
link: "$link_esc"
cover:
  image: "cover.jpg"
  alt: "《$title_esc》"
links: []
---

在这里写这个收藏的介绍。
INFO

cat >"$dir/_index.md" <<INDEX
---
title: "$title_esc"
date: "$date"
layout: "star"
---
INDEX

echo "已创建收藏: $dir"
echo "  belong: $label"
echo "  Info.md: 写简介、封面"
echo "  音乐/书籍/图片: $dir/{music,books,images}/"
echo "  link: ${link:-（空）}"
