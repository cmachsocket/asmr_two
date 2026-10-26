import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 主题模式与强调色。
///
/// 亮暗模式和强调色都存在本地存储里，启动时读回来。
class ThemeController extends GetxController {
  static const _modeKey = 'themeMode';
  static const _accentKey = 'accentColor';

  /// 默认强调色。
  static const Color defaultAccent = Colors.deepPurple;

  final _box = GetStorage();

  late final Rx<ThemeMode> mode;
  late final Rx<Color> accent;

  @override
  void onInit() {
    super.onInit();

    // 亮暗模式存名字（String），读回来还原。
    final savedMode = _box.read<String>(_modeKey);
    mode =
        (savedMode == null
                ? ThemeMode.system
                : ThemeMode.values.firstWhere(
                    (e) => e.name == savedMode,
                    orElse: () => ThemeMode.system,
                  ))
            .obs;

    // 强调色存整数（ARGB），读回来还原成颜色。
    final savedArgb = _box.read<int>(_accentKey);
    accent = (savedArgb != null ? Color(savedArgb) : defaultAccent).obs;
  }

  /// 切换亮暗模式。
  Future<void> setMode(ThemeMode m) async {
    if (mode.value == m) return;
    mode.value = m;
    await _box.write(_modeKey, m.name);
    Get.changeThemeMode(m);
  }

  /// 用户确认选色：持久化并换肤。
  Future<void> setAccent(Color c) async {
    accent.value = c;
    await _box.write(_accentKey, c.toARGB32());
  }

  /// 对话框实时预览：只改内存，不写存储。
  void setAccentPreview(Color c) {
    if (accent.value == c) return;
    accent.value = c;
  }

  /// 亮色主题。
  ThemeData get lightTheme => FlexThemeData.light(
    keyColors: FlexKeyColors(keyPrimary: accent.value),
    appBarStyle: FlexAppBarStyle.background,
  );

  /// 暗色主题。
  ThemeData get darkTheme => FlexThemeData.dark(
    keyColors: FlexKeyColors(keyPrimary: accent.value),
    appBarStyle: FlexAppBarStyle.background,
  );

  /// 打开取色对话框：确认后写盘，取消后回滚到原色。
  Future<void> openColorPickerDialog() async {
    final original = accent.value;
    var picked = original;

    final confirmed = await ColorPicker(
      color: original,
      enableTonalPalette: true,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.accent: true,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: {
        ColorTools.createPrimarySwatch(defaultAccent): '默认紫',
      },
      showColorCode: true,
      showRecentColors: true,
      onColorChanged: (Color color) {
        picked = color;
        setAccentPreview(color);
      },
    ).showPickerDialog(Get.context!);

    if (confirmed) {
      await setAccent(picked);
    } else {
      setAccentPreview(original);
    }
  }
}
