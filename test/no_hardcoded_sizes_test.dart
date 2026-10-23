import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 规则文件,与 `.githooks/pre-commit` 共用同一份。
const String rulesPath = 'tool/hardcoded_size_rules.txt';

/// 比例式间距的令牌来源,里面的系数是「比例」不是「像素」,按定义允许。
const String excludedPath = 'lib/core/theme/app_spacing.dart';

/// 一条检查规则。
class _Rule {
  const _Rule(this.label, this.pattern);

  /// 规则名,用于报错定位。
  final String label;

  /// 匹配用正则。
  final RegExp pattern;
}

void main() {
  test('lib/ 下没有硬编码尺寸', () {
    final rules = _loadRules();
    final violations = <String>[];

    for (final rule in rules) {
      for (final file in _dartFilesUnder('lib')) {
        if (file.path == excludedPath) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (rule.pattern.hasMatch(lines[i])) {
            violations.add(
              '${file.path}:${i + 1}: [${rule.label}] ${lines[i].trim()}',
            );
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '业务 widget 里不允许硬编码尺寸,改成主题 / 比例式工具:\n'
          '${violations.join('\n')}',
    );
  });
}

/// 读规则文件,每行格式 `label|ERE 正则`。
List<_Rule> _loadRules() {
  final file = File(rulesPath);
  if (!file.existsSync()) {
    throw StateError('规则文件不存在: $rulesPath');
  }

  final rules = <_Rule>[];
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final separator = line.indexOf('|');
    if (separator < 0) continue;
    final label = line.substring(0, separator).trim();
    final pattern = line.substring(separator + 1).trim();
    rules.add(_Rule(label, RegExp(pattern)));
  }
  return rules;
}

/// 递归列出目录下的 .dart 文件。
List<File> _dartFilesUnder(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) {
    throw StateError('目录不存在: $root');
  }
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);
}
