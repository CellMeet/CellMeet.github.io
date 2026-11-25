#!/usr/bin/env bash
# 新建收藏：star [belong] [标题] [url]
set -euo pipefail
cd "$(dirname "$0")/.."

STAR_DIR="content/star"
PICKER_INLINE="scripts/pick_inline.py"

slugify() {
  printf '%s' "$1" \
    | sed -e 's#[/|:：]#-#g' -e 's/[?？]/ /g' \
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

list_belongs() {
  find "$STAR_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

resolve_belong() {
  local name="$1"
  local want lower d
  want="$(printf '%s' "$name" | sed 's/^ *//; s/ *$//')"
  [ -z "$want" ] && return 1

  case "$want" in
    page|网页|页面|网站) want="page" ;;
    course|课程) want="course" ;;
    book|书|书籍) want="book" ;;
  esac

  lower="$(printf '%s' "$want" | tr '[:upper:]' '[:lower:]' 2>/dev/null || printf '%s' "$want")"
  while IFS= read -r d; do
    local dl
    dl="$(printf '%s' "$d" | tr '[:upper:]' '[:lower:]' 2>/dev/null || printf '%s' "$d")"
    if [ "$dl" = "$lower" ]; then
      printf '%s\n' "$d"
      return 0
    fi
  done < <(list_belongs)

  local key
  key="$(slugify "$want")"
  [ -n "$key" ] || key="$want"
  mkdir -p "$STAR_DIR/$key"
  if [ ! -f "$STAR_DIR/$key/_index.md" ]; then
    cat >"$STAR_DIR/$key/_index.md" <<INDEX
---
title: "$want"
layout: "star-type"
---
INDEX
  fi
  printf '%s\n' "$key"
}

pick_belong() {
  ensure_base
  if [ -f "$PICKER_INLINE" ] && command -v python3 >/dev/null 2>&1 && [ "${TERM:-x}" != "dumb" ] && { [ -t 1 ] || [ -t 0 ] || { true </dev/tty; } 2>/dev/null; }; then
    list_belongs | python3 "$PICKER_INLINE" --prompt "belong: " --allow-new
    return $?
  fi

  echo "现有 belong：" >&2
  local -a arr=()
  local b
  while IFS= read -r b; do arr+=("$b"); done < <(list_belongs)
  local i=1
  for b in "${arr[@]}"; do
    printf '  %d) %s\n' "$i" "$b" >&2
    i=$((i+1))
  done
  read -r -p "belong（可直接输入新名字）: " b
  [ -n "$b" ] || return 1
  case "$b" in
    [0-9]*) if [ "$b" -ge 1 ] 2>/dev/null && [ "$b" -le ${#arr[@]} ]; then
              printf '%s\n' "${arr[b-1]}"; return 0
            fi ;;
  esac
  printf 'NEW:%s\n' "$b"
}

type_arg=""
title=""
url=""
info=""
prompted=0

# 解析参数：支持 star "标题" course url / star course "标题" url
if [ $# -ge 1 ]; then
  first="$1"
  if [ $# -ge 2 ] && ! printf '%s' "$2" | grep -qE '^https?://'; then
    # 第二个参数看起来像 belong
    if [ $# -ge 3 ] || [ -d "$STAR_DIR/$2" ] || [ "$2" = "page" ] || [ "$2" = "course" ] || [ "$2" = "book" ] || [ "$2" = "课程" ] || [ "$2" = "书" ] || [ "$2" = "页面" ]; then
      title="$1"
      type_arg="$2"
      shift 2
      url="${1:-}"
      [ $# -gt 0 ] && shift
      info="$*"
    fi
  fi
  if [ -z "$title" ] && [ -z "$type_arg" ]; then
    # 可能是 star course "标题" url
    if [ -d "$STAR_DIR/$first" ] || [ "$first" = "page" ] || [ "$first" = "course" ] || [ "$first" = "book" ] || [ "$first" = "课程" ] || [ "$first" = "书" ] || [ "$first" = "页面" ]; then
      type_arg="$first"
      shift
      title="${1:-}"
      [ $# -gt 0 ] && shift
      url="${1:-}"
      [ $# -gt 0 ] && shift
      info="$*"
    else
      title="$first"
      shift
      url="${1:-}"
      [ $# -gt 0 ] && shift
      info="$*"
    fi
  fi
fi

title="$(strip_quotes "$title")"
url="$(strip_quotes "$url")"

if [ -z "$title" ]; then
  read -r -p "title: " title
  title="$(strip_quotes "$title")"
  prompted=1
fi
if [ -z "$title" ]; then
  echo "title 不能为空" >&2
  exit 1
fi

if [ -z "$type_arg" ]; then
  prompted=1
  choice="$(pick_belong)" || { echo "未选择 belong" >&2; exit 1; }
  case "$choice" in
    NEW:*) type_arg="$(resolve_belong "${choice#NEW:}")" ;;
    *) type_arg="$(resolve_belong "$choice")" ;;
  esac
else
  type_arg="$(resolve_belong "$type_arg")"
fi
[ -n "$type_arg" ] || { echo "belong 无效" >&2; exit 1; }

if [ -z "$url" ]; then
  read -r -p "url: " url
  url="$(strip_quotes "$url")"
  prompted=1
fi
if [ -z "$info" ] && [ "$prompted" -eq 1 ]; then
  read -r -p "info: " info
fi

case "$url" in
  "") ;;
  http://*|https://*) ;;
  *) url="https://$url" ;;
esac

ensure_base
slug="$(slugify "$title")"
dir="$STAR_DIR/$type_arg/$slug"
date="$(date '+%F')"
datetime="$(date '+%Y-%m-%dT%H:%M:%S%:z')"

if [ -e "$dir" ]; then
  echo "收藏已存在: $dir" >&2
  exit 1
fi

mkdir -p "$dir"
if [ "$type_arg" = "book" ]; then
  mkdir -p "$dir/books"
fi

title_esc="$(yaml_escape "$title")"
url_esc="$(yaml_escape "$url")"
info_esc="$(yaml_escape "$info")"

cat >"$dir/Info.md" <<INFO
---
title: "$title_esc"
build:
  render: never
  list: never
date: "$date"
summary: "$info_esc"
link: "$url_esc"
cover:
  image: "cover.jpg"
  alt: "《$title_esc》"
links: []
---

${info:-在这里写这个收藏的介绍。}
INFO

cat >"$dir/_index.md" <<INDEX
---
title: "$title_esc"
date: "$datetime"
layout: "star"
---
INDEX

echo "已创建收藏: $dir"
echo "  belong: $type_arg"
echo "  url: ${url:-（空）}"
if [ "$type_arg" = "book" ]; then
  echo "  书籍文件: $dir/books/"
fi
echo "  介绍: $dir/Info.md"
