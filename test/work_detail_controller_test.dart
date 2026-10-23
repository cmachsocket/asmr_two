import 'package:asmr_two/core/api/api_client.dart';
import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/audio/audio_player_service.dart';
import 'package:asmr_two/state/player_controller.dart';
import 'package:asmr_two/state/work_detail_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import 'support/fake_adapter.dart';
import 'support/fake_just_audio_platform.dart';

const Map<String, dynamic> _workJson = {
  'id': 1,
  'title': '测试作品',
  'name': '测试社团',
  'release': '2026-09-23',
  'rate_count': 9,
  'rate_average_2dp': 4.8,
};

const List<Map<String, dynamic>> _trackJson = [
  {
    'type': 'folder',
    'title': 'mp3',
    'children': [
      {
        'type': 'audio',
        'title': '第一曲',
        'hash': '1/2',
        'mediaStreamUrl': 'https://cdn.example.com/1.mp3',
        'duration': 60,
      },
      {
        'type': 'audio',
        'title': '第二曲',
        'hash': '1/3',
        'mediaStreamUrl': 'https://cdn.example.com/2.mp3',
        'duration': 90,
      },
    ],
  },
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeJustAudioPlatform platform;
  late AudioPlayerService audio;
  late PlayerController player;
  late WorkDetailController controller;

  setUp(() {
    Get.testMode = true;
    platform = FakeJustAudioPlatform();

    final adapter = FakeAdapter((options) async {
      if (options.uri.path.startsWith('/api/work/')) {
        return jsonBody(_workJson);
      }
      if (options.uri.path.startsWith('/api/tracks/')) {
        return jsonBody(_trackJson);
      }
      return errorBody(message: 'unexpected ${options.uri.path}');
    });
    final api = AsmrApi(
      ApiClient(
        tokenProvider: () => null,
        dio: Dio()..httpClientAdapter = adapter,
      ),
    );

    audio = Get.put(
      AudioPlayerService(
        api: api,
        player: AudioPlayer(
          handleAudioSessionActivation: false,
          handleInterruptions: false,
        ),
      ),
    );
    player = Get.put(PlayerController());
    controller = WorkDetailController(api: api, workId: 1);
  });

  tearDown(() async {
    Get.reset();
    await platform.close();
  });

  test('加载作品信息与曲目并整理成播放队列', () async {
    await controller.load();

    expect(controller.work.value?.title, '测试作品');
    expect(controller.error.value, isNull);
    expect(controller.plan.value.items.length, 2);
    expect(controller.plan.value.items.first.title, '第一曲');
    expect(controller.tracksError.value, isNull);
  });

  test('播放指定曲目时队列交给音频层', () async {
    await controller.load();
    await controller.playIndex(1);

    expect(audio.snapshot.value.queue.length, 2);
    expect(audio.snapshot.value.current?.title, '第二曲');
    expect(player.current.value?.title, '第二曲');
    expect(player.queue.length, 2);
  });

  test('播放控制器镜像音频层状态', () async {
    await controller.load();
    await controller.playAll();

    expect(player.isPlaying.value, isTrue);
    expect(player.currentIndex.value, 0);
    expect(player.duration.value, const Duration(minutes: 3));
  });
}
