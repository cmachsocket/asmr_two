#!/usr/bin/env bash
# 把 .githooks/ 接进仓库的 core.hooksPath。
#
# 为什么不直接放 .git/hooks/:
#   .git/ 不进版本库,clone 下来的人拿不到,每台机器都要手工重装一遍。
#   core.hooksPath 指向仓库内的目录,脚本跟着代码一起走。
#
# 想让"clone 下来就自动生效",用 tool/install_git_template.sh(全局模板),不用这个。
#
# 用法: bash tool/install_git_hooks.sh

set -euo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null || true)

if [ -z "$root" ]; then
  echo "❌ 当前目录不是 git 仓库,先 git init 再装 hooks。" >&2
  exit 1
fi

cd "$root"

if [ ! -f ".githooks/pre-commit" ]; then
  echo "❌ 找不到 .githooks/pre-commit" >&2
  exit 1
fi

chmod +x .githooks/pre-commit

git config core.hooksPath .githooks

echo "✅ 已设置 core.hooksPath = .githooks"
echo
echo "当前生效的 hooks:"
git config --get core.hooksPath
echo
echo "验证: 试着提交一次,或手动跑"
echo "  bash .githooks/pre-commit"
