#!/usr/bin/env bash
# 博客控制面板：新建 / 编辑 / 收藏 / 预览 / 发布
set -euo pipefail
cd "$(dirname "$0")/.."

PICKER="scripts/pick_inline.py"
actions=(
  "写新文章"
  "编辑已有文章"
  "新建收藏"
  "本地预览"
  "发布到网站"
  "添加友链"
)

choice="$(printf '%s\n' "${actions[@]}" | python3 "$PICKER" --prompt "博客: " --max 8)" || {
  echo "已退出"
  exit 0
}

case "$choice" in
  "写新文章") exec ./sh/new.sh ;;
  "编辑已有文章") exec ./sh/edit.sh ;;
  "新建收藏") exec ./sh/star.sh ;;
  "本地预览")
    echo "本地预览：http://localhost:1313  （Ctrl+C 结束）"
    exec hugo server -D
    ;;
  "发布到网站") exec ./sh/pub.sh ;;
  "添加友链")
    read -r -p "网址: " url
    [ -n "$url" ] || { echo "没有输入网址"; exit 1; }
    exec ./sh/link.sh "$url"
    ;;
  *) echo "未知操作: $choice"; exit 1 ;;
esac
