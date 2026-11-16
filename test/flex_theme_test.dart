import 'package:asmr_two/core/theme/flex_theme.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const accent = Color(0xFFEC4141);

  test('material_ui 配色能完整转成 Flutter 内置配色', () {
    final flex = FlexColorScheme.light(
      keyColors: const FlexKeyColors(keyPrimary: accent),
    );
    final scheme = flex.toScheme;
    final converted = toFlutterColorScheme(scheme);

    expect(converted.brightness, scheme.brightness);
    expect(converted.primary, scheme.primary);
    expect(converted.onPrimary, scheme.onPrimary);
    expect(converted.primaryContainer, scheme.primaryContainer);
    expect(converted.onPrimaryContainer, scheme.onPrimaryContainer);
    expect(converted.secondary, scheme.secondary);
    expect(converted.onSecondary, scheme.onSecondary);
    expect(converted.secondaryContainer, scheme.secondaryContainer);
    expect(converted.onSecondaryContainer, scheme.onSecondaryContainer);
    expect(converted.tertiary, scheme.tertiary);
    expect(converted.onTertiary, scheme.onTertiary);
    expect(converted.tertiaryContainer, scheme.tertiaryContainer);
    expect(converted.onTertiaryContainer, scheme.onTertiaryContainer);
    expect(converted.error, scheme.error);
    expect(converted.onError, scheme.onError);
    expect(converted.errorContainer, scheme.errorContainer);
    expect(converted.onErrorContainer, scheme.onErrorContainer);
    expect(converted.surface, scheme.surface);
    expect(converted.onSurface, scheme.onSurface);
    expect(converted.surfaceDim, scheme.surfaceDim);
    expect(converted.surfaceBright, scheme.surfaceBright);
    expect(converted.surfaceContainerLowest, scheme.surfaceContainerLowest);
    expect(converted.surfaceContainerLow, scheme.surfaceContainerLow);
    expect(converted.surfaceContainer, scheme.surfaceContainer);
    expect(converted.surfaceContainerHigh, scheme.surfaceContainerHigh);
    expect(converted.surfaceContainerHighest, scheme.surfaceContainerHighest);
    expect(converted.onSurfaceVariant, scheme.onSurfaceVariant);
    expect(converted.outline, scheme.outline);
    expect(converted.outlineVariant, scheme.outlineVariant);
    expect(converted.inverseSurface, scheme.inverseSurface);
    expect(converted.onInverseSurface, scheme.onInverseSurface);
    expect(converted.inversePrimary, scheme.inversePrimary);
    expect(converted.surfaceTint, scheme.surfaceTint);
  });

  test('暗色配色转完还是暗色', () {
    final flex = FlexColorScheme.dark(
      keyColors: const FlexKeyColors(keyPrimary: accent),
    );

    final converted = toFlutterColorScheme(flex.toScheme);

    expect(converted.brightness, Brightness.dark);
    expect(converted.surface, flex.toScheme.surface);
  });

  test('主题转换后配色和 AppBar 背景都跟 flex 一致', () {
    final flex = FlexThemeData.light(
      keyColors: const FlexKeyColors(keyPrimary: accent),
      appBarStyle: FlexAppBarStyle.background,
    );

    final theme = toFlutterTheme(flex);

    expect(theme.colorScheme.primary, flex.colorScheme.primary);
    expect(theme.colorScheme.surface, flex.colorScheme.surface);
    expect(theme.appBarTheme.backgroundColor, flex.appBarTheme.backgroundColor);
    expect(theme.appBarTheme.foregroundColor, flex.appBarTheme.foregroundColor);
    expect(theme.appBarTheme.elevation, flex.appBarTheme.elevation);
  });

  test('AppBar 用 background 样式时背景是 surfaceContainerLow', () {
    final flex = FlexThemeData.light(
      keyColors: const FlexKeyColors(keyPrimary: accent),
      appBarStyle: FlexAppBarStyle.background,
    );

    final theme = toFlutterTheme(flex);

    expect(
      theme.appBarTheme.backgroundColor,
      theme.colorScheme.surfaceContainerLow,
    );
  });
}
