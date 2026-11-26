#!/usr/bin/env bash
# 一键发布：本地构建检查 -> 提交 -> 推送，GitHub Actions 自动部署
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> 本地构建检查"
hugo --gc --minify

echo "==> 提交改动"
git add -A
if git diff --cached --quiet; then
  echo "没有新的改动需要提交。"
else
  git commit -m "post: $(date '+%Y-%m-%d %H:%M')"
fi

echo "==> 推送到 GitHub"
git push origin main

echo "完成！等待 GitHub Actions 部署（通常 1-3 分钟）。"
