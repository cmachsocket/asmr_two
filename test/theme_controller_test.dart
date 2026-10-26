import 'dart:io';

import 'package:asmr_two/state/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'support/fake_storage.dart';

void main() {
  late Directory storageDir;
  late ThemeController theme;

  setUp(() async {
    Get.testMode = true;
    storageDir = await initFakeStorage();
    theme = Get.put(ThemeController());
  });

  tearDown(() async {
    Get.reset();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  test('默认跟随系统，强调色是默认紫', () {
    expect(theme.mode.value, ThemeMode.system);
    expect(theme.accent.value, ThemeController.defaultAccent);
  });

  test('切换亮暗模式会写进本地存储', () async {
    await theme.setMode(ThemeMode.dark);

    expect(theme.mode.value, ThemeMode.dark);
    expect(GetStorage().read<String>('themeMode'), 'dark');
  });

  test('选强调色会写进本地存储', () async {
    await theme.setAccent(const Color(0xFFEC4141));

    expect(theme.accent.value, const Color(0xFFEC4141));
    expect(GetStorage().read<int>('accentColor'), 0xFFEC4141);
  });

  test('取色对话框取消后回到原来的颜色', () async {
    final original = theme.accent.value;
    theme.setAccentPreview(const Color(0xFFEC4141));
    expect(theme.accent.value, const Color(0xFFEC4141));

    theme.setAccentPreview(original);
    expect(theme.accent.value, original);
  });
}
