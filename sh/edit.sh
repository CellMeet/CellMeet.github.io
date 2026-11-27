#!/usr/bin/env bash
# 选择一篇文章并用 Typora / 默认编辑器打开
set -euo pipefail
cd "$(dirname "$0")/.."

PICKER="scripts/pick_inline.py"

mapfile -t files < <(find content/posts -type f -name '*.md' ! -name '_index.md' ! -name 'Info.md' | sort)
if [ ${#files[@]} -eq 0 ]; then
  echo "还没有文章，先运行 ./sh/new.sh 新建一篇。"
  exit 1
fi

# 显示时去掉 content/posts/ 前缀
items=()
for f in "${files[@]}"; do
  items+=("${f#content/posts/}")
done

sel="$(printf '%s\n' "${items[@]}" | python3 "$PICKER" --prompt "编辑哪篇: " --max 12)" || {
  echo "已取消"
  exit 1
}

file="content/posts/$sel"
[ -f "$file" ] || { echo "找不到: $file" >&2; exit 1; }

if command -v typora >/dev/null 2>&1; then
  nohup typora "$file" >/dev/null 2>&1 &
elif [ -n "${EDITOR:-}" ]; then
  "$EDITOR" "$file"
else
  xdg-open "$file" >/dev/null 2>&1 &
fi
echo "已打开: $file"
