import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_player_service.dart';
import 'playback_item.dart';
import 'playback_snapshot.dart';

/// Android 通知栏 / 锁屏媒体控制与现有音频引擎之间的桥接。
///
/// 播放事实仍然只在 [AudioPlayerService] 和 just_audio 里，
/// 这里只把快照翻译成 audio_service 的媒体会话状态，并把系统控制转发回去。
class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AudioPlayerHandler(this._service) {
    mediaItem.add(null);
    _subscription = _service.snapshot.stream.listen(_onSnapshot);
    _onSnapshot(_service.snapshot.value);
  }

  final AudioPlayerService _service;

  StreamSubscription<PlaybackSnapshot>? _subscription;

  List<PlaybackItem>? _lastQueue;
  String? _lastItemId;

  @override
  Future<void> play() => _service.play();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> seek(Duration position) => _service.seek(position);

  @override
  Future<void> skipToNext() => _service.next();

  @override
  Future<void> skipToPrevious() => _service.previous();

  @override
  Future<void> stop() async {
    await _service.stop();
    await super.stop();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _service.setRepeatAll(repeatMode == AudioServiceRepeatMode.all);

  /// 释放监听，由应用退出时调用。
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onSnapshot(PlaybackSnapshot snapshot) {
    final queue = snapshot.queue;
    if (!identical(queue, _lastQueue)) {
      _lastQueue = queue;
      updateQueue(queue.map(_mediaItemOf).toList(growable: false));
    }

    final item = snapshot.current;
    final itemId = item == null ? null : _idOf(item);
    if (itemId != _lastItemId) {
      _lastItemId = itemId;
      mediaItem.add(
        item == null ? null : _mediaItemOf(item, snapshot.duration),
      );
    }

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          snapshot.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _processingStateOf(snapshot.processingState),
        playing: snapshot.isPlaying,
        updatePosition: snapshot.position,
        bufferedPosition: snapshot.bufferedPosition,
        speed: 1,
        repeatMode: snapshot.repeatAll
            ? AudioServiceRepeatMode.all
            : AudioServiceRepeatMode.none,
        shuffleMode: AudioServiceShuffleMode.none,
        queueIndex: snapshot.currentIndex >= 0 ? snapshot.currentIndex : null,
      ),
    );
  }

  MediaItem _mediaItemOf(PlaybackItem item, [Duration? duration]) {
    final itemDuration = duration != null && duration > Duration.zero
        ? duration
        : item.hasDuration
        ? Duration(seconds: item.duration.round())
        : null;
    return MediaItem(
      id: _idOf(item),
      title: item.title,
      album: item.workTitle,
      artUri: Uri.tryParse(item.coverUrl),
      duration: itemDuration,
    );
  }

  static String _idOf(PlaybackItem item) =>
      '${item.workId}:${item.track.hash ?? item.title}';

  static AudioProcessingState _processingStateOf(ProcessingState state) =>
      switch (state) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };
}
