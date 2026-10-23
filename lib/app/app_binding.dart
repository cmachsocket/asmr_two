import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../core/storage/session_store.dart';
import '../state/auth_controller.dart';
import '../state/work_feed_controller.dart';

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

    Get.lazyPut<WorkFeedController>(
      () => WorkFeedController(Get.find<AsmrApi>()),
      fenix: true,
    );
  }
}
