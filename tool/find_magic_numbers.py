#!/usr/bin/env python3
"""
find_magic_numbers.py - 在 lib/ 下扫描"业务代码里的幻数"

不是 lint/pre-commit hook 那种硬拦,而是给人看"还有哪些字面数字没名字"的列表。

跟 .githooks/pre-commit 的区别:
- pre-commit hook 抓的是"业务 widget 里硬编码数字"(padding/fontSize/iconSize/
  widget 尺寸),这些是该走主题/比例式工具的硬约束,违反就 exit 1 拦 commit。
- 本脚本抓的是"代码里出现频率高但没命名的数字"(API 限制/魔法常量/状态机索引/
  算法哨兵),主要是给 review 用,不当 error,只列清单。

用法:
    python3 tool/find_magic_numbers.py                # 扫 lib/ (默认排除接口层)
    python3 tool/find_magic_numbers.py --include-api  # 把 lib/core/api/ 也算进去

排除:
- 单行注释 / doc 注释 (/// / // / *) 里的数字
- 接口层 (lib/core/api/): 协议常量、超时、分页默认值都写在那里,逐个审视没意义
- JSON 解析默认值 (`is int ? json[...] as int : 0`)

返回:
    计数行 + 剩余"待 review"行
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

# 默认排除的路径:接口层是协议常量堆放处,交给 code review 看就行
DEFAULT_EXCLUDE = ('/core/api/',)


def collect_magic_numbers(lib_root: Path, include_api: bool) -> list[str]:
    """收集 lib/ 下所有 .dart 文件里"代码行里出现数字"的行。"""
    # 先用 grep -nE 一次扫完
    cmd = [
        'grep', '-rnE',
        # 数字边界:不能是字母/数字/小数点的一部分
        # 形如 ", 12" / "(1)" / "= 3" 都命中,但 "v1.2.3" / "abc123" / "id123" 不命中
        r'[^a-zA-Z_0-9.]([0-9]+(\.[0-9]+)?)[^a-zA-Z_0-9.]',
        str(lib_root),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    raw_lines = result.stdout.splitlines()

    hits = []
    for line in raw_lines:
        # 跳过注释行(行首是 // /// 或 /* *)
        # 格式: lib/path/file.dart:N:content
        parts = line.split(':', 2)
        if len(parts) < 3:
            continue
        file_part, _, content = parts
        if content.lstrip().startswith(('///', '//', '*', '/*')):
            continue
        # exclude 路径
        if not include_api and any(p in file_part for p in DEFAULT_EXCLUDE):
            continue
        hits.append(line)

    return hits


def filter_suspicious(hits: list[str]) -> list[str]:
    """从总命中筛出"真可疑"行。"""
    suspicious = []
    for line in hits:
        # JSON 解析默认值
        if re.search(r'is int \? json\[', line):
            continue
        suspicious.append(line)
    return suspicious


def main() -> int:
    parser = argparse.ArgumentParser(
        description='扫 lib/ 找还没命名的数字字面量',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        '--lib-root', type=Path, default=Path('lib'),
        help='lib 根目录(默认 ./lib)',
    )
    parser.add_argument(
        '--include-api', action='store_true',
        help='把接口层 (lib/core/api/) 也算进去(默认排除)',
    )
    parser.add_argument(
        '--verbose', '-v', action='store_true',
        help='额外打印每个文件的命中数',
    )
    args = parser.parse_args()

    lib_root = args.lib_root
    if not lib_root.is_dir():
        print(f'❌ 目录不存在: {lib_root}', file=sys.stderr)
        return 2

    print(f'🔍 扫 {lib_root}/ 找幻数(排除接口层: {not args.include_api})...\n')

    hits = collect_magic_numbers(lib_root, args.include_api)
    suspicious = filter_suspicious(hits)

    if args.verbose:
        # 按文件聚合
        from collections import Counter
        files = Counter(line.split(':', 1)[0] for line in hits)
        print('📊 命中文件 Top:')
        for f, n in files.most_common(10):
            print(f'   {n:3d}  {f}')
        print()

    print(f'📋 命中: {len(hits)} 行')
    print(f'⚠️  待 review: {len(suspicious)} 行')
    print()
    for s in suspicious:
        print(s)
    print()

    # 不当 error,return 0(这是给人看的清单,不是 lint gate)
    return 0


if __name__ == '__main__':
    sys.exit(main())
