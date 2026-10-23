import 'package:just_audio/just_audio.dart' show ProcessingState;

import 'playback_item.dart';

/// 播放状态快照。
///
/// 音频层把播放器的多条状态流聚合成这一个不可变对象，
/// UI 只订阅它，不必各自去监听播放器的流。
class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.isPlaying = false,
    this.processingState = ProcessingState.idle,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.current,
    this.queue = const [],
    this.currentIndex = -1,
    this.repeatAll = false,
    this.error,
  });

  /// 是否正在播放。
  final bool isPlaying;

  /// 播放器的处理状态。
  final ProcessingState processingState;

  /// 当前播放位置。
  final Duration position;

  /// 已缓冲到的位置。
  final Duration bufferedPosition;

  /// 当前曲目的时长。
  final Duration duration;

  /// 当前曲目。
  final PlaybackItem? current;

  /// 播放队列。
  final List<PlaybackItem> queue;

  /// 当前曲目在队列中的下标，-1 表示队列为空。
  final int currentIndex;

  /// 是否循环播放整个队列。
  final bool repeatAll;

  /// 最近一次播放错误。
  final String? error;

  /// 队列中是否有可播放的条目。
  bool get hasItem => current != null;

  /// 是否正在缓冲。
  bool get isBuffering =>
      processingState == ProcessingState.loading ||
      processingState == ProcessingState.buffering;

  /// 播放进度（0~1）。
  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
  }

  /// 复制并替换指定字段。
  ///
  /// `current` / `error` 传 null 表示保持原值，
  /// 需要清空时分别配合 `clearCurrent` / `clearError`。
  PlaybackSnapshot copyWith({
    bool? isPlaying,
    ProcessingState? processingState,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    PlaybackItem? current,
    bool clearCurrent = false,
    List<PlaybackItem>? queue,
    int? currentIndex,
    bool? repeatAll,
    String? error,
    bool clearError = false,
  }) {
    return PlaybackSnapshot(
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      current: clearCurrent ? null : (current ?? this.current),
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatAll: repeatAll ?? this.repeatAll,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
