import 'dart:async';

import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/audio/playback_item.dart';
import '../core/models/subtitle.dart';
import '../core/models/track.dart';
import '../core/subtitle/subtitle_parser.dart';
import 'player_controller.dart';

/// 当前曲目的字幕状态。
///
/// 拉取并解析字幕资源，再交给参考项目同款的 [LyricController]
/// 负责高亮、滚动和点击跳转。
class SubtitleController extends GetxController {
  final AsmrApi _api = Get.find<AsmrApi>();
  final PlayerController _player = Get.find<PlayerController>();

  /// 与 [LyricView] 配套的歌词控制器。
  final LyricController lyricController = LyricController();

  /// 当前曲目的字幕轨。
  final Rxn<SubtitleTrack> track = Rxn<SubtitleTrack>();

  /// 是否正在加载字幕。
  final RxBool loading = false.obs;

  /// 当前曲目是否带字幕资源。
  final RxBool available = false.obs;

  /// 字幕加载错误。
  final RxnString error = RxnString();

  final Map<String, SubtitleTrack> _cache = {};

  String? _currentKey;
  String? _loadingKey;
  Worker? _itemWorker;
  Worker? _positionWorker;

  @override
  void onInit() {
    super.onInit();
    _itemWorker = ever<PlaybackItem?>(_player.current, _onItemChanged);
    _positionWorker = ever<Duration>(_player.position, _onPositionChanged);
    _onItemChanged(_player.current.value);
  }

  @override
  void onClose() {
    _itemWorker?.dispose();
    _positionWorker?.dispose();
    lyricController.dispose();
    super.onClose();
  }

  /// 点字幕行时跳到该行开始的位置。
  void seekTo(Duration position) => _player.seek(position);

  /// 重新拉取当前曲目的字幕。
  void retry() {
    final key = _currentKey;
    if (key != null) _cache.remove(key);
    _currentKey = null;
    _onItemChanged(_player.current.value);
  }

  void _onItemChanged(PlaybackItem? item) {
    final subtitle = item?.subtitle;
    available.value = subtitle != null;

    if (subtitle == null) {
      _currentKey = null;
      _loadingKey = null;
      track.value = null;
      error.value = null;
      loading.value = false;
      _clearLyric();
      return;
    }

    final key = '${subtitle.hash ?? ''}|${subtitle.streamUrl ?? ''}';
    if (key == _currentKey && (track.value != null || _loadingKey == key)) {
      _onPositionChanged(_player.position.value);
      return;
    }
    _currentKey = key;
    _load(subtitle, key);
  }

  Future<void> _load(TrackNode subtitle, String key) async {
    // 先占住当前加载标记：切歌后旧请求即使完成，也不能覆盖新曲目的字幕。
    _loadingKey = key;

    final cached = _cache[key];
    if (cached != null) {
      loading.value = false;
      _apply(cached);
      if (_loadingKey == key) _loadingKey = null;
      return;
    }

    loading.value = true;
    error.value = null;
    track.value = null;
    _clearLyric();

    try {
      final text = await _api.fetchSubtitleText(subtitle);
      if (_loadingKey != key) return;

      final parsed = SubtitleParser.parse(text, filename: subtitle.title);
      _cache[key] = parsed;
      _apply(parsed);
    } on ApiException catch (exception) {
      if (_loadingKey != key) return;
      error.value = exception.message;
    } catch (_) {
      if (_loadingKey != key) return;
      error.value = '字幕加载失败。';
    } finally {
      if (_loadingKey == key) {
        _loadingKey = null;
        loading.value = false;
      }
    }
  }

  void _apply(SubtitleTrack value) {
    track.value = value;
    error.value = null;

    final lrc = _toLrc(value);
    if (lrc.isEmpty) {
      _clearLyric();
      return;
    }
    lyricController.load(lrc);
    lyricController.setPosition(_player.position.value);
  }

  void _onPositionChanged(Duration position) {
    if (track.value == null) return;
    lyricController.setPosition(position);
  }

  void _clearLyric() => lyricController.clear();

  /// 把统一的字幕模型转成 flutter_lyric 能直接消费的 LRC。
  static String _toLrc(SubtitleTrack value) {
    if (value.cues.isEmpty) return '';

    if (!value.timed) {
      return '[00:00.00]${_singleLine(value.cues.first.text)}';
    }

    final buffer = StringBuffer();
    for (final cue in value.cues) {
      final text = _singleLine(cue.text);
      if (text.isEmpty) continue;
      buffer.writeln('[${_stamp(cue.start)}]$text');
    }
    return buffer.toString();
  }

  static String _singleLine(String text) =>
      text.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();

  static String _stamp(Duration value) {
    final minutes = value.inMinutes;
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (value.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '${minutes.toString().padLeft(2, '0')}:$seconds.$millis';
  }
}
