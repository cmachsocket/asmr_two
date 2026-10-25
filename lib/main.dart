import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/asmr_api.dart';
import 'core/audio/audio_player_service.dart';
import 'core/storage/session_store.dart';
import 'state/player_controller.dart';
import 'state/subtitle_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // 基础设施在 main 里常驻：令牌存储、接口层、音频引擎。
  //
  // 音频引擎必须早于界面就绪 —— 播放入口随时可能被触发，
  // 引擎晚一步注册就会让第一次播放落到"还没准备好"的状态。
  Get.put<SessionStore>(SessionStore(prefs), permanent: true);
  Get.put<ApiClient>(
    ApiClient(tokenProvider: () => Get.find<SessionStore>().token),
    permanent: true,
  );
  Get.put<AsmrApi>(AsmrApi(Get.find<ApiClient>()), permanent: true);
  Get.put<AudioPlayerService>(
    AudioPlayerService(api: Get.find<AsmrApi>()),
    permanent: true,
  );
  Get.put<PlayerController>(PlayerController(), permanent: true);
  Get.put<SubtitleController>(SubtitleController(), permanent: true);

  runApp(const AsmrApp());
}
