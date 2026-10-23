import 'package:flutter/widgets.dart';

/// 比例式间距工具。
///
/// 界面上不写死具体尺寸，所有留白都按屏幕短边的比例换算。
class AppSpacing {
  const AppSpacing._();

  /// 间距基准：屏幕短边的 2%。
  static double unit(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide * 0.02;

  /// 极小间距。
  static double xs(BuildContext context) => unit(context) * 0.5;

  /// 小间距。
  static double sm(BuildContext context) => unit(context);

  /// 常规间距。
  static double md(BuildContext context) => unit(context) * 2;

  /// 大间距。
  static double lg(BuildContext context) => unit(context) * 3;

  /// 常规内边距。
  static EdgeInsets padding(BuildContext context) =>
      EdgeInsets.all(md(context));

  /// 常规水平内边距。
  static EdgeInsets horizontal(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: md(context));

  /// 常规垂直内边距。
  static EdgeInsets vertical(BuildContext context) =>
      EdgeInsets.symmetric(vertical: sm(context));

  /// 列表项之间的间隔。
  static SizedBox gap(BuildContext context) => SizedBox(height: sm(context));
}
