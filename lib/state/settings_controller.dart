import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/api/api_client.dart';
import 'auth_controller.dart';

/// 设置页的状态：登录态、关闭窗口的行为与接口线路。
///
/// 全局注册（设置页与桌面端托盘都要读退出行为）。
class SettingsController extends GetxController {
  static const _exitToTrayKey = 'exit_to_tray_v1';
  static const _mirrorKey = 'api_mirror_v1';

  final _box = GetStorage();

  /// 登录状态，设置页与登录页共用。
  final AuthController auth;

  /// 接口层，用于把选中的线路立刻应用到后续请求。
  final ApiClient api;

  SettingsController({required this.auth, required this.api});

  /// 关闭窗口时最小化到托盘，而不是退出应用。默认关（Linux/Windows 点 X 退出）。
  late final RxBool exitToTray;

  /// 当前选中的接口线路。
  late final RxString selectedMirror;

  /// 可选线路，与官网顺序一致。
  List<String> get mirrors => ApiHosts.all;

  @override
  void onInit() {
    super.onInit();
    exitToTray = (_box.read<bool>(_exitToTrayKey) ?? false).obs;

    final saved = _box.read<String>(_mirrorKey);
    final index = ApiHosts.all.contains(saved)
        ? ApiHosts.all.indexOf(saved!)
        : 0;
    selectedMirror = ApiHosts.all[index].obs;
    api.pinnedHostIndex = index;
  }

  /// 先改内存再写盘，所以写盘失败也会保留新值。
  Future<void> setExitToTray(bool enabled) async {
    exitToTray.value = enabled;
    await _box.write(_exitToTrayKey, enabled);
  }

  /// 切换接口线路：立即生效并写盘，重启后仍从该线路开始。
  Future<void> setSelectedMirror(String? mirror) async {
    if (mirror == null || mirror == selectedMirror.value) return;
    final index = ApiHosts.all.indexOf(mirror);
    if (index < 0) return;
    selectedMirror.value = mirror;
    api.pinnedHostIndex = index;
    await _box.write(_mirrorKey, mirror);
  }

  /// 退出登录。
  Future<void> logout() => auth.logout();
}
