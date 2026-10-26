import 'dart:io';

import 'package:asmr_two/app/app.dart';
import 'package:asmr_two/core/api/api_client.dart';
import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/audio/audio_player_service.dart';
import 'package:asmr_two/core/storage/session_store.dart';
import 'package:asmr_two/state/player_controller.dart';
import 'package:asmr_two/state/subtitle_controller.dart';
import 'package:asmr_two/state/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_adapter.dart';
import 'support/fake_just_audio_platform.dart';
import 'support/fake_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageDir;
  late FakeJustAudioPlatform platform;

  setUp(() async {
    Get.testMode = true;
    storageDir = await initFakeStorage();
    platform = FakeJustAudioPlatform();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final (client, _) = buildClient((options) async => jsonBody({'items': []}));
    final api = AsmrApi(client);

    Get.put<SessionStore>(SessionStore(prefs));
    Get.put<ApiClient>(ApiClient(tokenProvider: () => null));
    Get.put<AsmrApi>(api);
    Get.put<AudioPlayerService>(
      AudioPlayerService(
        api: api,
        player: AudioPlayer(
          handleAudioSessionActivation: false,
          handleInterruptions: false,
        ),
      ),
    );
    Get.put<PlayerController>(PlayerController());
    Get.put<SubtitleController>(SubtitleController());
    Get.put<ThemeController>(ThemeController());
  });

  tearDown(() async {
    Get.reset();
    await platform.close();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  testWidgets('切到收藏库页有创建播放列表的入口', (tester) async {
    await tester.pumpWidget(const AsmrApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });

  testWidgets('应用能起来，切到设置页能看到迁移过来的条目', (tester) async {
    await tester.pumpWidget(const AsmrApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    expect(find.text('主题'), findsOneWidget);
    expect(find.text('强调色'), findsOneWidget);
    expect(find.text('登录账号'), findsOneWidget);
    expect(find.text('窗口退出按钮'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
