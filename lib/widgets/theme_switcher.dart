import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/theme_controller.dart';

/// 设置页用的三段主题切换器。
///
/// 用 ToggleButtons 而不是 SegmentedButton —— 后者在 Android 上渲染黑屏。
class ThemeSwitcher extends GetView<ThemeController> {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.mode.value;
      return ToggleButtons(
        isSelected: [
          current == ThemeMode.system,
          current == ThemeMode.light,
          current == ThemeMode.dark,
        ],
        onPressed: (index) {
          const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
          controller.setMode(modes[index]);
        },
        children: const [
          Icon(Icons.brightness_auto),
          Icon(Icons.light_mode),
          Icon(Icons.dark_mode),
        ],
      );
    });
  }
}

/// 强调色取色入口。
class ColorSchemeSwitcher extends GetView<ThemeController> {
  const ColorSchemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.color_lens_outlined),
      onPressed: controller.openColorPickerDialog,
    );
  }
}
