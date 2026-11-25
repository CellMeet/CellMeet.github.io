#!/usr/bin/env bash
# 新建收藏：star [类型] [名字]
#   类型：course/web/music/book 或 课程/网页/音乐/书籍
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

type_key() {
  case "$1" in
    course|课程) echo "course" ;;
    web|网页|网站) echo "web" ;;
    music|音乐|歌曲) echo "music" ;;
    book|书籍|书) echo "book" ;;
    *) echo "" ;;
  esac
}

type_title() {
  case "$1" in
    course) echo "课程" ;;
    web) echo "网页" ;;
    music) echo "音乐" ;;
    book) echo "书籍" ;;
  esac
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
    printf '课程\n网页\n音乐\n书籍\n' | python3 "$PICKER_INLINE" --prompt "收藏到: "
    return $?
  fi

  echo "收藏到：" >&2
  echo "  1) 课程" >&2
  echo "  2) 网页" >&2
  echo "  3) 音乐" >&2
  echo "  4) 书籍" >&2
  local n
  read -r -p "选择 [1-4]: " n
  case "$n" in
    1) echo "课程" ;;
    2) echo "网页" ;;
    3) echo "音乐" ;;
    4) echo "书籍" ;;
    *) return 1 ;;
  esac
}

type_arg=""
name=""

if [ $# -eq 0 ]; then
  :
elif [ -n "$(type_key "$1")" ]; then
  type_arg="$(type_key "$1")"
  shift
  name="$*"
else
  name="$1"
  shift
  if [ $# -gt 0 ]; then
    name="$name $*"
  fi
fi

if [ -z "$name" ]; then
  read -r -p "收藏名字: " name
fi
if [ -z "$name" ]; then
  echo "名字不能为空" >&2
  exit 1
fi

if [ -z "$type_arg" ]; then
  label="$(pick_type)" || { echo "未选择类型" >&2; exit 1; }
  type_arg="$(type_key "$label")"
  if [ -z "$type_arg" ]; then
    echo "类型无效: $label" >&2
    exit 1
  fi
fi

ensure_type "$type_arg"
title="$(type_title "$type_arg")"

slug="$(slugify "$name")"
dir="$STAR_DIR/$type_arg/$slug"
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
date: "$date"
layout: "star"
---
INDEX

echo "已创建收藏: $dir"
echo "  版块: $title"
echo "  介绍: $dir/Info.md"
echo "  音乐: $dir/music/  （子文件夹 = 专辑）"
echo "  书籍: $dir/books/"
echo "  图片: $dir/images/"
echo "  链接: Info.md 里的 links"
