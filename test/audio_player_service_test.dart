import 'package:asmr_two/core/api/api_client.dart';
import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/audio/audio_player_service.dart';
import 'package:asmr_two/core/audio/playback_item.dart';
import 'package:asmr_two/core/models/track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'support/fake_just_audio_platform.dart';

/// 构造一个播放条目，[streamUrl] 为空表示拿不到直链。
PlaybackItem _item({
  String title = '音轨',
  String? streamUrl = 'https://cdn.example.com/track.mp3',
  String? hash = '1/2',
}) {
  final node = TrackNode.fromJson({
    'type': 'audio',
    'title': title,
    'hash': hash,
    'mediaStreamUrl': streamUrl,
    'duration': 120,
  });
  return PlaybackItem(
    track: AudioTrack(node: node),
    workId: 7,
    workTitle: '作品',
    coverUrl: 'https://cdn.example.com/cover.jpg',
  );
}

void main() {
  // 播放后端会走方法通道，需要先初始化 binding。
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeJustAudioPlatform platform;
  late AudioPlayerService service;

  setUp(() {
    Get.testMode = true;
    platform = FakeJustAudioPlatform();
    service = Get.put(
      AudioPlayerService(
        api: AsmrApi(ApiClient(tokenProvider: () => null, dio: Dio())),
        player: AudioPlayer(
          handleAudioSessionActivation: false,
          handleInterruptions: false,
        ),
      ),
    );
  });

  tearDown(() async {
    Get.reset();
    await platform.close();
  });

  test('起播后队列与当前曲目同步到快照', () async {
    await service.playQueue([_item(title: '第一曲'), _item(title: '第二曲')]);

    final snapshot = service.snapshot.value;
    expect(snapshot.queue.length, 2);
    expect(snapshot.current?.title, '第一曲');
    expect(snapshot.currentIndex, 0);
    expect(snapshot.isPlaying, isTrue);
    expect(platform.playCount, 1);
  });

  test('从指定下标起播', () async {
    await service.playQueue([
      _item(title: '第一曲'),
      _item(title: '第二曲'),
    ], startIndex: 1);

    expect(service.snapshot.value.current?.title, '第二曲');
    expect(service.snapshot.value.currentIndex, 1);
  });

  test('解析不出播放地址时只记录错误，不改动队列', () async {
    await service.playQueue([_item(streamUrl: null, hash: null)]);

    expect(service.snapshot.value.error, '该作品需要登录后才能播放。');
    expect(service.snapshot.value.queue, isEmpty);
    expect(service.snapshot.value.current, isNull);
    expect(platform.playCount, 0);
  });

  test('跳过解析不出地址的条目', () async {
    await service.playQueue([
      _item(title: '可播', streamUrl: null, hash: null),
      _item(title: '可播但要登录'),
    ]);

    expect(service.snapshot.value.queue.length, 1);
    expect(service.snapshot.value.current?.title, '可播但要登录');
  });

  test('跳转与循环开关转发到底层播放器', () async {
    await service.playQueue([_item(title: '第一曲'), _item(title: '第二曲')]);

    await service.jumpTo(1);
    expect(platform.seeks.last.index, 1);

    await service.setRepeatAll(true);
    expect(service.snapshot.value.repeatAll, isTrue);
    expect(platform.loopModes.last, LoopModeMessage.all);

    await service.setRepeatAll(false);
    expect(platform.loopModes.last, LoopModeMessage.off);
  });

  test('停止播放清空队列', () async {
    await service.playQueue([_item()]);
    await service.stop();

    expect(service.snapshot.value.queue, isEmpty);
    expect(service.snapshot.value.current, isNull);
    expect(service.snapshot.value.currentIndex, -1);
  });
}
