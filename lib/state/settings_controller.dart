import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'auth_controller.dart';

/// 设置页的状态：登录态与关闭窗口的行为。
///
/// 全局注册（设置页与桌面端托盘都要读退出行为）。
class SettingsController extends GetxController {
  static const _exitToTrayKey = 'exit_to_tray_v1';

  final _box = GetStorage();

  /// 登录状态，设置页与登录页共用。
  final AuthController auth;

  SettingsController({required this.auth});

  /// 关闭窗口时最小化到托盘，而不是退出应用。默认关（Linux/Windows 点 X 退出）。
  late final RxBool exitToTray;

  @override
  void onInit() {
    super.onInit();
    exitToTray = (_box.read<bool>(_exitToTrayKey) ?? false).obs;
  }

  /// 先改内存再写盘，所以写盘失败也会保留新值。
  Future<void> setExitToTray(bool enabled) async {
    exitToTray.value = enabled;
    await _box.write(_exitToTrayKey, enabled);
  }

  /// 退出登录。
  Future<void> logout() => auth.logout();
}
