import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../core/storage/session_store.dart';
import '../state/auth_controller.dart';
import '../state/settings_controller.dart';
import '../controller/home_controller.dart';

/// 依赖装配。
///
/// 基础设施（令牌存储、接口层、音频引擎）在 `main` 里常驻，
/// 这里只装配页面级的 controller。
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(
        api: Get.find<AsmrApi>(),
        sessionStore: Get.find<SessionStore>(),
      ),
      fenix: true,
    );

    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    // 设置页的 controller 全局可用：桌面端托盘也要读「关闭窗口」的行为。
    Get.lazyPut<SettingsController>(
      () => SettingsController(auth: Get.find<AuthController>()),
      fenix: true,
    );
  }
}
