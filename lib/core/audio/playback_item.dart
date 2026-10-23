import '../models/track.dart';

/// 播放队列条目：一条音频轨道 + 所属作品的展示信息。
class PlaybackItem {
  const PlaybackItem({
    required this.track,
    required this.workId,
    required this.workTitle,
    required this.coverUrl,
  });

  /// 展平后的音频条目，含所在目录路径。
  final AudioTrack track;

  /// 所属作品 id。
  final int workId;

  /// 所属作品标题。
  final String workTitle;

  /// 所属作品封面地址。
  final String coverUrl;

  /// 音频标题。
  String get title => track.title;

  /// 所在目录文案，例如 `mp3`。
  String get folderLabel => track.folderLabel;

  /// 时长（秒）。
  double get duration => track.duration;

  /// 是否有可用的时长信息。
  bool get hasDuration => track.hasDuration;

  /// 曲目节点，解析播放地址时使用。
  TrackNode get node => track.node;
}
