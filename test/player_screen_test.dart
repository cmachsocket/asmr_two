import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/audio/audio_player_service.dart';
import 'package:asmr_two/core/audio/playback_item.dart';
import 'package:asmr_two/core/models/track.dart';
import 'package:asmr_two/screens/player_screen.dart';
import 'package:asmr_two/state/player_controller.dart';
import 'package:asmr_two/state/subtitle_controller.dart';
import 'package:asmr_two/widgets/bottom_player.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import 'support/fake_adapter.dart';
import 'support/fake_just_audio_platform.dart';
import 'support/mock_image.dart';

const _coverUrl = 'https://cdn.example.com/cover.jpg';

const _lrc =
    '[00:00.00]第一句\n'
    '[00:05.00]第二句\n';

/// 构造一条带字幕的播放条目。
PlaybackItem _item() {
  final audio = TrackNode.fromJson({
    'type': 'audio',
    'title': 'chapter01.mp3',
    'hash': '1/2',
    'mediaStreamUrl': 'https://cdn.example.com/chapter01.mp3',
    'duration': 60,
  });
  final subtitle = TrackNode.fromJson({
    'type': 'text',
    'title': 'chapter01.lrc',
    'hash': '9/10',
    'mediaStreamUrl': 'https://cdn.example.com/chapter01.lrc',
  });
  return PlaybackItem(
    track: AudioTrack(node: audio, subtitle: subtitle),
    workId: 1,
    workTitle: '测试作品',
    coverUrl: _coverUrl,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeJustAudioPlatform platform;
  late AudioPlayerService audio;

  setUp(() async {
    Get.testMode = true;
    platform = FakeJustAudioPlatform();

    final (client, _) = buildClient((options) async {
      if (options.uri.path.endsWith('chapter01.lrc')) {
        return ResponseBody.fromString(
          _lrc,
          200,
          headers: const {
            'content-type': ['text/plain'],
          },
        );
      }
      return errorBody(message: 'unexpected ${options.uri}');
    });

    final api = AsmrApi(client);
    Get.put<AsmrApi>(api);
    audio = Get.put(
      AudioPlayerService(
        api: api,
        player: AudioPlayer(
          handleAudioSessionActivation: false,
          handleInterruptions: false,
        ),
      ),
    );
    Get.put<PlayerController>(PlayerController());
    await audio.playQueue([_item()]);
    final subtitle = Get.put<SubtitleController>(SubtitleController());
    for (var i = 0; i < 20 && subtitle.loading.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  tearDown(() async {
    Get.reset();
    await platform.close();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    await mockCoverImage(tester, _coverUrl);
    await tester.pumpWidget(GetMaterialApp(home: home));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('播放页展示曲目、控制按钮与字幕', (tester) async {
    await pumpApp(tester, const PlayerScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('chapter01.mp3'), findsOneWidget);
    expect(find.text('测试作品'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
    expect(find.byIcon(Icons.shuffle), findsNothing);
    expect(find.byType(ProgressBar), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final subtitle = Get.find<SubtitleController>();
    expect(find.byType(LyricView), findsOneWidget);
    expect(subtitle.track.value?.cues.first.text, '第一句');
    expect(subtitle.lyricController.activeLine?.text, '第一句');

    subtitle.lyricController.setPosition(const Duration(seconds: 5));
    expect(subtitle.lyricController.activeLine?.text, '第二句');

    subtitle.seekTo(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );

    expect(platform.seeks.last.position, const Duration(seconds: 5));
  });

  testWidgets('底部播放器展示曲目并打开播放页', (tester) async {
    await pumpApp(tester, const Scaffold(body: BottomPlayer()));

    expect(find.text('chapter01.mp3'), findsOneWidget);
    expect(find.text('测试作品'), findsOneWidget);

    await tester.tap(find.text('chapter01.mp3'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('chapter01.mp3'), findsOneWidget);
  });

  testWidgets('底部播放器在首页分配的高度下不溢出', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: Column(
          children: [
            Expanded(flex: 6, child: SizedBox.shrink()),
            Expanded(flex: 1, child: BottomPlayer()),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('chapter01.mp3'), findsOneWidget);
  });
}
