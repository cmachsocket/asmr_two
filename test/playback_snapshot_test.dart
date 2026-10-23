import 'package:asmr_two/core/audio/playback_item.dart';
import 'package:asmr_two/core/audio/playback_snapshot.dart';
import 'package:asmr_two/core/models/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

PlaybackItem _item() {
  final node = TrackNode.fromJson({'type': 'audio', 'title': '音轨'});
  return PlaybackItem(
    track: AudioTrack(node: node),
    workId: 1,
    workTitle: '作品',
    coverUrl: '',
  );
}

void main() {
  test('进度按时长比例计算', () {
    final snapshot = PlaybackSnapshot(
      position: const Duration(seconds: 30),
      duration: const Duration(seconds: 120),
    );

    expect(snapshot.progress, 0.25);
  });

  test('时长未知时进度为 0', () {
    expect(const PlaybackSnapshot().progress, 0);
  });

  test('缓冲中与加载中视为正在缓冲', () {
    expect(
      const PlaybackSnapshot(processingState: ProcessingState.loading)
          .isBuffering,
      isTrue,
    );
    expect(
      const PlaybackSnapshot(processingState: ProcessingState.buffering)
          .isBuffering,
      isTrue,
    );
    expect(
      const PlaybackSnapshot(processingState: ProcessingState.ready)
          .isBuffering,
      isFalse,
    );
  });

  test('copyWith 保持未替换的字段', () {
    final item = _item();
    final snapshot = PlaybackSnapshot(
      current: item,
      queue: [item],
      currentIndex: 0,
      isPlaying: true,
    );

    final next = snapshot.copyWith(position: const Duration(seconds: 5));

    expect(next.position, const Duration(seconds: 5));
    expect(next.current, item);
    expect(next.queue.length, 1);
    expect(next.currentIndex, 0);
    expect(next.isPlaying, isTrue);
  });

  test('copyWith 需要显式清空当前曲目与错误', () {
    final snapshot = PlaybackSnapshot(current: _item(), error: '播放失败');

    expect(snapshot.copyWith(clearCurrent: true).current, isNull);
    expect(snapshot.copyWith(clearCurrent: true).error, '播放失败');
    expect(snapshot.copyWith(clearError: true).error, isNull);
    expect(snapshot.copyWith(clearError: true).current, isNotNull);
  });
}
