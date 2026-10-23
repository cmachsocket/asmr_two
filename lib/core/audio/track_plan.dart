import '../models/track.dart';
import 'playback_item.dart';

/// 作品曲目列表的一行。
sealed class TrackRow {
  const TrackRow();
}

/// 目录行。
class TrackFolderRow extends TrackRow {
  const TrackFolderRow(this.title);

  /// 目录名。
  final String title;
}

/// 音频行。
class TrackAudioRow extends TrackRow {
  const TrackAudioRow(this.item, this.queueIndex);

  /// 对应的播放条目。
  final PlaybackItem item;

  /// 在作品播放队列中的下标。
  final int queueIndex;
}

/// 作品曲目树整理后的结果：播放队列 + 展示行。
class TrackPlan {
  const TrackPlan({required this.items, required this.rows});

  /// 作品的全部音频，按播放顺序排列。
  final List<PlaybackItem> items;

  /// 展示用的行，目录与音频按原始顺序混排。
  final List<TrackRow> rows;

  static const empty = TrackPlan(items: [], rows: []);

  /// 把曲目树整理成播放队列与展示行。
  ///
  /// 目录节点先产出一行目录标题，再按顺序产出其下的音频；
  /// 顶层就是音频的节点直接产出一行音频。
  factory TrackPlan.fromNodes({
    required List<TrackNode> nodes,
    required int workId,
    required String workTitle,
    required String coverUrl,
  }) {
    final items = <PlaybackItem>[];
    final rows = <TrackRow>[];
    for (final node in nodes) {
      final audios = node.flatten();
      if (audios.isEmpty) continue;
      if (node.isFolder) rows.add(TrackFolderRow(node.title));
      for (final audio in audios) {
        final item = PlaybackItem(
          track: audio,
          workId: workId,
          workTitle: workTitle,
          coverUrl: coverUrl,
        );
        items.add(item);
        rows.add(TrackAudioRow(item, items.length - 1));
      }
    }
    return TrackPlan(items: items, rows: rows);
  }
}
