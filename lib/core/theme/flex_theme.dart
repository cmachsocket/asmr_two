import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mu;

/// flex_color_scheme 9 起主题基于独立的 material_ui 包，
/// 它的 ThemeData / ColorScheme 跟 flutter/material.dart 里的不是同一个类。
///
/// 应用根节点是 GetMaterialApp，只接受 Flutter 内置的 ThemeData，
/// 所以这里把 flex 生成的 material_ui 主题转回内置类型。
///
/// flex 的组件子主题（卡片、按钮等）本来就跟着配色走，
/// 内置 Material 3 主题的默认值也是按配色算的，
/// 所以只需要转配色和 AppBar 主题。

/// material_ui 主题 → Flutter 内置主题。
ThemeData toFlutterTheme(mu.ThemeData theme) {
  return ThemeData(
    colorScheme: toFlutterColorScheme(theme.colorScheme),
    useMaterial3: true,
    appBarTheme: toFlutterAppBarTheme(theme.appBarTheme),
  );
}

/// material_ui 配色 → Flutter 内置配色。
///
/// 内置 ColorScheme 的构造函数不开放全部角色，
/// 这里用 [ColorScheme.fromSeed] 的可选参数把每个角色都对齐过去。
ColorScheme toFlutterColorScheme(mu.ColorScheme scheme) {
  return ColorScheme.fromSeed(
    seedColor: scheme.primary,
    brightness: scheme.brightness,
    primary: scheme.primary,
    onPrimary: scheme.onPrimary,
    primaryContainer: scheme.primaryContainer,
    onPrimaryContainer: scheme.onPrimaryContainer,
    primaryFixed: scheme.primaryFixed,
    primaryFixedDim: scheme.primaryFixedDim,
    onPrimaryFixed: scheme.onPrimaryFixed,
    onPrimaryFixedVariant: scheme.onPrimaryFixedVariant,
    secondary: scheme.secondary,
    onSecondary: scheme.onSecondary,
    secondaryContainer: scheme.secondaryContainer,
    onSecondaryContainer: scheme.onSecondaryContainer,
    secondaryFixed: scheme.secondaryFixed,
    secondaryFixedDim: scheme.secondaryFixedDim,
    onSecondaryFixed: scheme.onSecondaryFixed,
    onSecondaryFixedVariant: scheme.onSecondaryFixedVariant,
    tertiary: scheme.tertiary,
    onTertiary: scheme.onTertiary,
    tertiaryContainer: scheme.tertiaryContainer,
    onTertiaryContainer: scheme.onTertiaryContainer,
    tertiaryFixed: scheme.tertiaryFixed,
    tertiaryFixedDim: scheme.tertiaryFixedDim,
    onTertiaryFixed: scheme.onTertiaryFixed,
    onTertiaryFixedVariant: scheme.onTertiaryFixedVariant,
    error: scheme.error,
    onError: scheme.onError,
    errorContainer: scheme.errorContainer,
    onErrorContainer: scheme.onErrorContainer,
    surface: scheme.surface,
    onSurface: scheme.onSurface,
    surfaceDim: scheme.surfaceDim,
    surfaceBright: scheme.surfaceBright,
    surfaceContainerLowest: scheme.surfaceContainerLowest,
    surfaceContainerLow: scheme.surfaceContainerLow,
    surfaceContainer: scheme.surfaceContainer,
    surfaceContainerHigh: scheme.surfaceContainerHigh,
    surfaceContainerHighest: scheme.surfaceContainerHighest,
    onSurfaceVariant: scheme.onSurfaceVariant,
    outline: scheme.outline,
    outlineVariant: scheme.outlineVariant,
    shadow: scheme.shadow,
    scrim: scheme.scrim,
    inverseSurface: scheme.inverseSurface,
    onInverseSurface: scheme.onInverseSurface,
    inversePrimary: scheme.inversePrimary,
    surfaceTint: scheme.surfaceTint,
  );
}

/// material_ui 的 AppBar 主题 → Flutter 内置的。
AppBarThemeData toFlutterAppBarTheme(mu.AppBarThemeData theme) {
  return AppBarThemeData(
    backgroundColor: theme.backgroundColor,
    foregroundColor: theme.foregroundColor,
    elevation: theme.elevation,
    scrolledUnderElevation: theme.scrolledUnderElevation,
    shadowColor: theme.shadowColor,
    surfaceTintColor: theme.surfaceTintColor,
    shape: theme.shape,
    iconTheme: theme.iconTheme,
    actionsIconTheme: theme.actionsIconTheme,
    centerTitle: theme.centerTitle,
    titleSpacing: theme.titleSpacing,
    leadingWidth: theme.leadingWidth,
    toolbarHeight: theme.toolbarHeight,
    toolbarTextStyle: theme.toolbarTextStyle,
    titleTextStyle: theme.titleTextStyle,
    systemOverlayStyle: theme.systemOverlayStyle,
    actionsPadding: theme.actionsPadding,
  );
}
