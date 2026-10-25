import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/asmr_api.dart';
import 'core/audio/audio_player_handler.dart';
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
  final audio = AudioPlayerService(api: Get.find<AsmrApi>());
  Get.put<AudioPlayerService>(audio, permanent: true);
  Get.put<PlayerController>(PlayerController(), permanent: true);
  Get.put<SubtitleController>(SubtitleController(), permanent: true);

  // Android 需要 audio_service 托管媒体会话，通知栏 / 锁屏才能控制播放。
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await AudioService.init(
      builder: () => AudioPlayerHandler(audio),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.cmach.asmr_two.audio',
        androidNotificationChannelName: 'ASMR Two 播放',
        androidNotificationChannelDescription: '后台播放与媒体控制',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        preloadArtwork: false,
        artDownscaleWidth: 800,
        artDownscaleHeight: 800,
      ),
    );
  }

  runApp(const AsmrApp());
}
