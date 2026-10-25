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
  /// 同目录同名的 `text` 节点会挂到对应音频上作为字幕。
  factory TrackPlan.fromNodes({
    required List<TrackNode> nodes,
    required int workId,
    required String workTitle,
    required String coverUrl,
  }) {
    final items = <PlaybackItem>[];
    final rows = <TrackRow>[];
    final topLevelSubtitles = _subtitleIndex(nodes);

    for (final node in nodes) {
      final audios = node.isFolder
          ? _flattenFolder(node)
          : node.isAudio
          ? [
              AudioTrack(
                node: node,
                subtitle: _subtitleFor(node, topLevelSubtitles),
              ),
            ]
          : const <AudioTrack>[];
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

  /// 展开一个目录，目录内再按同名规则配对字幕。
  static List<AudioTrack> _flattenFolder(
    TrackNode folder, [
    List<String> path = const [],
  ]) {
    final nextPath = [...path, folder.title];
    final subtitles = _subtitleIndex(folder.children);
    final result = <AudioTrack>[];

    for (final child in folder.children) {
      if (child.isAudio) {
        result.add(
          AudioTrack(
            node: child,
            folderPath: nextPath,
            subtitle: _subtitleFor(child, subtitles),
          ),
        );
      } else if (child.isFolder) {
        result.addAll(_flattenFolder(child, nextPath));
      }
    }
    return result;
  }

  /// 查找音频对应的字幕。
  ///
  /// 站点上的字幕有两种命名：`chapter01.vtt`（与音频同基名）和
  /// `chapter01.mp3.vtt`（在音频完整文件名后再加字幕扩展名），
  /// 所以先用完整文件名匹配，再退回去掉音频扩展名的基名。
  static TrackNode? _subtitleFor(
    TrackNode audio,
    Map<String, TrackNode> subtitles,
  ) {
    final fullName = audio.title.trim().toLowerCase();
    return subtitles[fullName] ?? subtitles[_fileStem(audio.title)];
  }

  /// 同一层里的文本节点按“去掉扩展名的文件名”建索引。
  ///
  /// 同名存在多种格式时按 LRC > VTT > TXT 取一份，避免播放页在多份字幕间来回切。
  static Map<String, TrackNode> _subtitleIndex(List<TrackNode> nodes) {
    final result = <String, TrackNode>{};
    final ranks = <String, int>{};

    for (final node in nodes) {
      if (!node.isText) continue;
      final extension = _extensionOf(node.title);
      final rank = _subtitleRank(extension);
      if (rank == null) continue;

      final stem = _fileStem(node.title);
      final existingRank = ranks[stem];
      if (existingRank != null && existingRank <= rank) continue;
      result[stem] = node;
      ranks[stem] = rank;
    }
    return result;
  }

  static int? _subtitleRank(String extension) {
    return switch (extension) {
      'lrc' => 0,
      'vtt' => 1,
      'txt' => 2,
      _ => null,
    };
  }

  static String _extensionOf(String title) {
    final name = title.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static String _fileStem(String title) {
    final name = title.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    final stem = dot < 0 ? name : name.substring(0, dot);
    return stem.trim().toLowerCase();
  }
}
