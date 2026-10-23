import '../json/json_reader.dart';

/// 曲目树节点。
///
/// `type` 为 `folder` 表示目录，`audio` 表示音频文件，
/// 另有 `image` / `text` 等附属文件。
class TrackNode {
  const TrackNode({
    required this.type,
    required this.title,
    this.children = const [],
    this.hash,
    this.duration,
    this.size,
    this.streamUrl,
    this.downloadUrl,
    this.lowQualityStreamUrl,
    this.workId,
    this.sourceId,
    this.workTitle,
  });

  final String type;
  final String title;
  final List<TrackNode> children;

  /// 媒体哈希，形如 `1653004/1937686`，用于拼接带 token 的接口地址。
  final String? hash;

  /// 时长（秒）。
  final double? duration;

  /// 文件体积（字节）。
  final int? size;

  /// 接口直接给出的 CDN 播放地址。
  final String? streamUrl;

  /// 接口直接给出的 CDN 下载地址。
  final String? downloadUrl;

  /// 低码率播放地址，可能为空。
  final String? lowQualityStreamUrl;

  final int? workId;
  final String? sourceId;
  final String? workTitle;

  bool get isFolder => type == 'folder';

  bool get isAudio => type == 'audio';

  /// 是否是可以播放的音频节点。
  bool get isPlayable => isAudio && (hash ?? '').isNotEmpty;

  factory TrackNode.fromJson(Map<String, dynamic> json) {
    final work = Json.map(json['work']);
    return TrackNode(
      type: Json.string(json['type'], fallback: 'audio'),
      title: Json.string(json['title']),
      children: Json.list(json['children'], TrackNode.fromJson),
      hash: Json.stringOrNull(json['hash']),
      duration: Json.numberOrNull(json['duration']),
      size: Json.integerOrNull(json['size']),
      streamUrl: Json.stringOrNull(json['mediaStreamUrl']),
      downloadUrl: Json.stringOrNull(json['mediaDownloadUrl']),
      lowQualityStreamUrl: Json.stringOrNull(json['streamLowQualityUrl']),
      workId: work.isEmpty ? null : Json.integerOrNull(work['id']),
      sourceId: work.isEmpty ? null : Json.stringOrNull(work['source_id']),
      workTitle: Json.stringOrNull(json['workTitle']),
    );
  }

  /// 深度优先展开出全部音频节点，并保留所在目录路径。
  List<AudioTrack> flatten({List<String> path = const []}) {
    final result = <AudioTrack>[];
    if (isAudio) {
      result.add(AudioTrack(node: this, folderPath: path));
      return result;
    }
    final next = [...path, title];
    for (final child in children) {
      result.addAll(child.flatten(path: next));
    }
    return result;
  }
}

/// 展平后的音频条目，供播放队列使用。
class AudioTrack {
  const AudioTrack({required this.node, this.folderPath = const []});

  final TrackNode node;

  /// 所在目录的层级路径。
  final List<String> folderPath;

  String get title => node.title;

  String? get hash => node.hash;

  double get duration => node.duration ?? 0;

  bool get hasDuration => duration > 0;

  /// 目录层级展示文案，例如 `特典 / 闹钟音频`。
  String get folderLabel => folderPath.join(' / ');
}
