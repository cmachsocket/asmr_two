#!/usr/bin/env bash
# 装成全局 git 模板,之后 clone 下来的仓库自带引导钩子,
# 仓库里只要有 .githooks/,pre-commit 立刻生效 —— 不用再手工跑安装脚本。
#
# 原理:
#   git clone / git init 会把 init.templateDir 指向的目录复制进 .git/。
#   模板里的 hooks/post-checkout 在首次 checkout 时跑,
#   它发现仓库里有 .githooks/pre-commit,就把 core.hooksPath 指过去。
#
# 这是**机器级**设置(改的是 ~/.gitconfig),只装一次,以后所有 clone 都受益。
# 撤销: git config --global --unset init.templateDir
#
# 只想让本仓库生效、不想动全局配置,用: bash tool/install_git_hooks.sh

set -euo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null || true)

if [ -z "$root" ]; then
  echo "❌ 当前目录不是 git 仓库,先 git init 再装模板。" >&2
  exit 1
fi

cd "$root"

SRC="$root/templates"
DST="${GIT_TEMPLATE_DIR:-$HOME/.git-templates}"

if [ ! -d "$SRC/hooks" ]; then
  echo "❌ 找不到模板目录: $SRC/hooks" >&2
  exit 1
fi

mkdir -p "$DST/hooks"
cp -r "$SRC"/. "$DST"/
chmod +x "$DST"/hooks/* 2>/dev/null || true

git config --global init.templateDir "$DST"

echo "✅ 已设置全局 init.templateDir = $DST"
echo
echo "模板里的引导钩子:"
ls -1 "$DST/hooks"
echo
echo "之后 clone 出来的仓库,只要带 .githooks/ 目录:"
echo "  1. 首次 checkout 自动带上引导钩子"
echo "  2. 引导把 core.hooksPath 指到 .githooks"
echo "  3. pre-commit 自检立刻生效"
echo
echo "撤销: git config --global --unset init.templateDir"
