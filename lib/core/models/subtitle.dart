/// 一条带时间轴的字幕。
class SubtitleCue {
  const SubtitleCue({required this.start, this.end, required this.text});

  /// 开始时间。
  final Duration start;

  /// 结束时间，为空表示持续到下一条字幕。
  final Duration? end;

  /// 字幕正文，可能包含换行。
  final String text;
}

/// 一条字幕轨。
///
/// [timed] 为 false 时表示内容只有纯文本、没有时间轴，
/// 界面应当把它当成台本整体展示，而不是做高亮跟随。
class SubtitleTrack {
  const SubtitleTrack({required this.cues, required this.timed});

  /// 按开始时间升序排列的字幕。
  final List<SubtitleCue> cues;

  /// 是否带时间轴。
  final bool timed;

  /// 是否没有任何可展示的文字。
  bool get isEmpty => cues.every((cue) => cue.text.trim().isEmpty);

  /// [position] 命中的字幕下标，没有命中时返回 -1。
  int indexAt(Duration position) {
    if (!timed || cues.isEmpty) return -1;

    var low = 0;
    var high = cues.length - 1;
    var found = -1;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      if (cues[middle].start <= position) {
        found = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    if (found < 0) return -1;

    final end = cues[found].end;
    if (end != null && position >= end) return -1;
    return found;
  }
}
