import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/default.dart';
import '../state/settings_controller.dart';
import '../widgets/theme_switcher.dart';
import 'about_screen.dart';
import 'login_screen.dart';

/// 设置页内容（放在首页外壳的 body 里）。
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  /// 跳登录页入口：跟 tab 切换同款 Get.to(binding:) 模式。
  static void _openLogin() => Get.to(
    () => const LoginScreen(),
    binding: LoginScreenBinding(),
    id: DefaultValues.shellNavigatorId,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.brightness_6_outlined),
          title: Text('主题'),
          subtitle: Text('跟随系统 / 浅色 / 深色'),
          trailing: ThemeSwitcher(),
        ),
        const ListTile(
          leading: Icon(Icons.colorize),
          title: Text('强调色'),
          subtitle: Text('自定义强调色'),
          trailing: ColorSchemeSwitcher(),
        ),
        // 登录账号：已登录 → "已登录 (退出)" / 未登录 → "登录账号"
        Obx(() {
          final loggedIn = controller.auth.isLoggedIn;
          return ListTile(
            leading: Icon(
              loggedIn ? Icons.account_circle : Icons.account_circle_outlined,
            ),
            title: Text(loggedIn ? '已登录' : '登录账号'),
            subtitle: Text(loggedIn ? '本地登录态已保存,点击退出' : '账号 + 密码'),
            trailing: loggedIn
                ? const Icon(Icons.logout)
                : const Icon(Icons.chevron_right),
            onTap: loggedIn ? _logout : _openLogin,
          );
        }),
        ListTile(
          leading: const Icon(Icons.exit_to_app),
          title: const Text('窗口退出按钮'),
          subtitle: const Text('退出应用/最小化到托盘'),
          trailing: Obx(
            () => Switch(
              value: controller.exitToTray.value,
              onChanged: controller.setExitToTray,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('关于'),
          subtitle: const Text('版本号 / 开源协议 / 联系方式'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Get.to(
            () => const AboutScreen(),
            id: DefaultValues.shellNavigatorId,
          ),
        ),
      ],
    );
  }

  /// 退出登录：清掉本地令牌后提示。
  Future<void> _logout() async {
    await controller.logout();
    Get.snackbar('已退出', '本地登录态已清除', snackPosition: SnackPosition.BOTTOM);
  }
}
