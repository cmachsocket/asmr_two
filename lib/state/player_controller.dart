import 'dart:async';

import 'package:get/get.dart';

import '../core/audio/audio_player_service.dart';
import '../core/audio/playback_item.dart';
import '../core/audio/playback_snapshot.dart';

/// 播放页中间区域的两种展示形态。
enum PlayerPage { cover, subtitle }

/// 播放页与迷你播放器的 UI 状态。
///
/// 只镜像 [AudioPlayerService.snapshot] 并转发命令，
/// 不持有任何播放事实，播放状态永远以音频层为准。
class PlayerController extends GetxController {
  final AudioPlayerService _audio = Get.find<AudioPlayerService>();

  /// 是否正在播放。
  final RxBool isPlaying = false.obs;

  /// 是否正在缓冲。
  final RxBool isBuffering = false.obs;

  /// 当前播放位置。
  final Rx<Duration> position = Duration.zero.obs;

  /// 当前曲目时长。
  final Rx<Duration> duration = Duration.zero.obs;

  /// 已缓冲到的位置。
  final Rx<Duration> buffered = Duration.zero.obs;

  /// 当前曲目。
  final Rxn<PlaybackItem> current = Rxn<PlaybackItem>();

  /// 播放队列。
  final RxList<PlaybackItem> queue = <PlaybackItem>[].obs;

  /// 当前曲目在队列中的下标。
  final RxInt currentIndex = (-1).obs;

  /// 是否循环播放整个队列。
  final RxBool repeatAll = false.obs;

  /// 最近一次播放错误。
  final RxnString error = RxnString();

  /// 播放页当前展示封面还是字幕。
  final Rx<PlayerPage> page = PlayerPage.cover.obs;

  Worker? _snapshotWorker;

  @override
  void onInit() {
    super.onInit();
    _snapshotWorker = ever<PlaybackSnapshot>(_audio.snapshot, _sync);
    _sync(_audio.snapshot.value);
  }

  @override
  void onClose() {
    _snapshotWorker?.dispose();
    super.onClose();
  }

  /// 用指定队列替换当前队列并从 [index] 起播。
  Future<void> playQueue(List<PlaybackItem> items, {int index = 0}) =>
      _audio.playQueue(items, startIndex: index);

  /// 播放 / 暂停切换。
  void togglePlay() => unawaited(_audio.togglePlay());

  /// 下一曲。
  void next() => unawaited(_audio.next());

  /// 上一曲。
  void previous() => unawaited(_audio.previous());

  /// 跳到队列中的第 [index] 项。
  void jumpTo(int index) => unawaited(_audio.jumpTo(index));

  /// 跳到指定位置。
  void seek(Duration position) => unawaited(_audio.seek(position));

  /// 切换封面 / 字幕。
  void switchPage() {
    page.value = switch (page.value) {
      PlayerPage.cover => PlayerPage.subtitle,
      PlayerPage.subtitle => PlayerPage.cover,
    };
  }

  /// 切换整队列循环。
  void toggleRepeatAll() => unawaited(_audio.setRepeatAll(!repeatAll.value));

  /// 停止播放并清空队列。
  void stop() => unawaited(_audio.stop());

  void _sync(PlaybackSnapshot snapshot) {
    isPlaying.value = snapshot.isPlaying;
    isBuffering.value = snapshot.isBuffering;
    position.value = snapshot.position;
    duration.value = snapshot.duration > Duration.zero
        ? snapshot.duration
        : _fallbackDuration(snapshot.current);
    buffered.value = snapshot.bufferedPosition;
    current.value = snapshot.current;
    queue.assignAll(snapshot.queue);
    currentIndex.value = snapshot.currentIndex;
    repeatAll.value = snapshot.repeatAll;
    error.value = snapshot.error;
  }

  /// 播放器还没读出时长时，用曲目元数据里的秒数先顶上。
  static Duration _fallbackDuration(PlaybackItem? item) {
    if (item == null || !item.hasDuration) return Duration.zero;
    return Duration(seconds: item.duration.round());
  }
}
