import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import '../api/api_client.dart' show ApiHosts;
import '../api/asmr_api.dart';
import 'playback_item.dart';
import 'playback_snapshot.dart';

/// 音频引擎的唯一入口。
///
/// - 内部持有 [AudioPlayer]，把播放器的多条状态流聚合成单个 [snapshot]，
///   UI 只订阅快照，不必各自去监听播放器。
/// - 播放地址在起播那一刻才解析：付费作品的地址依赖登录令牌，
///   提前解析会拿到已经失效的地址。
/// - 只做顺序播放，不提供乱序。
class AudioPlayerService extends GetxController {
  /// 创建音频服务。
  ///
  /// 桌面端（Linux / Windows）没有原生播放后端，media_kit 必须在播放器
  /// 创建之前启用，所以播放器的构造放在 [_createPlayer] 里。
  AudioPlayerService({required this.api, AudioPlayer? player})
    : _player = player ?? _createPlayer();

  /// 启用桌面端播放后端并创建播放器。
  static AudioPlayer _createPlayer() {
    JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
    return AudioPlayer();
  }

  final AsmrApi api;

  final AudioPlayer _player;

  /// UI 唯一订阅点。
  final Rx<PlaybackSnapshot> snapshot = const PlaybackSnapshot().obs;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// 当前队列。
  List<PlaybackItem> get queue => snapshot.value.queue;

  @override
  void onInit() {
    super.onInit();
    _subscriptions.addAll([
      _player.playerStateStream.listen(_onPlayerState),
      _player.playbackEventStream.listen(_onPlaybackEvent),
      _player.positionStream.listen(_onPosition),
      _player.errorStream.listen(_onError),
    ]);
  }

  /// 用 [items] 替换队列，并从 [startIndex] 起播。
  ///
  /// 解析不出播放地址的条目（例如付费作品且未登录）会被跳过，
  /// 全部都解析不出来时只记录错误，不改变当前队列。
  Future<void> playQueue(List<PlaybackItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;

    final queue = <PlaybackItem>[];
    final sources = <AudioSource>[];
    var target = 0;
    for (var i = 0; i < items.length; i++) {
      final url = api.resolveStreamUrl(items[i].node);
      if (url == null) continue;
      queue.add(items[i]);
      sources.add(_sourceOf(url, items[i]));
      if (i == startIndex) target = queue.length - 1;
    }

    if (queue.isEmpty) {
      _emit(snapshot.value.copyWith(error: '该作品需要登录后才能播放。'));
      return;
    }

    _emit(
      snapshot.value.copyWith(
        queue: queue,
        currentIndex: target,
        current: queue[target],
        position: Duration.zero,
        duration: Duration.zero,
        clearError: true,
      ),
    );

    try {
      await _player.setAudioSources(sources, initialIndex: target);
      await _player.play();
    } on PlayerInterruptedException {
      // 请求被更新的请求顶替，结果以新请求为准。
    } on PlayerException catch (error) {
      _emit(snapshot.value.copyWith(error: error.message ?? '播放失败。'));
    }
  }

  /// 播放 / 暂停切换。
  Future<void> togglePlay() => _player.playing ? pause() : play();

  /// 播放。播放完成的曲目重新从头开始。
  Future<void> play() => _guard(() async {
    if (snapshot.value.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero, index: 0);
    }
    await _player.play();
  });

  /// 暂停。
  Future<void> pause() => _guard(() => _player.pause());

  /// 跳到指定位置。
  Future<void> seek(Duration position) => _guard(() => _player.seek(position));

  /// 下一曲。队列末尾是否回到开头由循环开关决定。
  Future<void> next() => _guard(() => _player.seekToNext());

  /// 上一曲。
  Future<void> previous() => _guard(() => _player.seekToPrevious());

  /// 跳到队列中的第 [index] 项并继续播放。
  Future<void> jumpTo(int index) {
    if (index < 0 || index >= snapshot.value.queue.length) {
      return Future<void>.value();
    }
    return _guard(() async {
      await _player.seek(Duration.zero, index: index);
      await _player.play();
    });
  }

  /// 是否循环播放整个队列。
  Future<void> setRepeatAll(bool value) => _guard(() async {
    await _player.setLoopMode(value ? LoopMode.all : LoopMode.off);
    _emit(snapshot.value.copyWith(repeatAll: value));
  });

  /// 停止播放并清空队列。
  Future<void> stop() => _guard(() async {
    await _player.stop();
    await _player.setAudioSources(const []);
    _emit(const PlaybackSnapshot());
  });

  /// 执行播放器命令，失败时把错误写进快照。
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on PlayerInterruptedException {
      // 请求被更新的请求顶替，结果以新请求为准。
    } on PlayerException catch (error) {
      _emit(snapshot.value.copyWith(error: error.message ?? '播放失败。'));
    }
  }

  /// 构造播放源，带上官网 Referer（接口与 CDN 都可能校验）。
  AudioSource _sourceOf(String url, PlaybackItem item) {
    return AudioSource.uri(
      Uri.parse(url),
      headers: const {'Referer': '${ApiHosts.site}/'},
      tag: item,
    );
  }

  void _onPlayerState(PlayerState state) {
    _emit(
      snapshot.value.copyWith(
        isPlaying: state.playing,
        processingState: state.processingState,
      ),
    );
  }

  void _onPlaybackEvent(PlaybackEvent event) {
    var next = snapshot.value.copyWith(
      processingState: event.processingState,
      bufferedPosition: event.bufferedPosition,
      duration: event.duration ?? Duration.zero,
    );
    final index = event.currentIndex;
    if (index != null && index != next.currentIndex) {
      final inRange = index >= 0 && index < next.queue.length;
      next = next.copyWith(
        currentIndex: index,
        current: inRange ? next.queue[index] : null,
        clearCurrent: !inRange,
      );
    }
    _emit(next);
  }

  void _onPosition(Duration position) {
    _emit(snapshot.value.copyWith(position: position));
  }

  void _onError(PlayerException error) {
    _emit(
      snapshot.value.copyWith(
        error: error.message ?? '播放失败。',
        isPlaying: false,
        processingState: ProcessingState.idle,
      ),
    );
  }

  void _emit(PlaybackSnapshot next) {
    snapshot.value = next;
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_player.dispose().catchError((Object _) {}));
    super.onClose();
  }
}
