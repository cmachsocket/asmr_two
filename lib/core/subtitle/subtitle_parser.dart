import 'dart:convert';

import 'package:charset/charset.dart' show gbk;

import '../models/subtitle.dart';

/// 字幕文件解析。
///
/// 支持曲目树里出现的三种文本资源：`.lrc`、`.vtt`，
/// 以及内容可能是台本或 WebVTT 的 `.txt`。
class SubtitleParser {
  const SubtitleParser._();

  /// 把原始字节解码成文本。
  ///
  /// 站点上的字幕编码不固定：优先按 UTF-8 解，失败后回退 GB18030（GBK 超集）。
  static String decodeBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';
    try {
      return _stripBom(utf8.decode(bytes));
    } on FormatException {
      return _stripBom(gbk.decode(bytes, allowMalformed: true));
    }
  }

  /// 解析字幕文本，[filename] 的扩展名决定首选解析方式。
  static SubtitleTrack parse(String content, {String filename = ''}) {
    final text = _normalize(content);
    if (text.trim().isEmpty) {
      return const SubtitleTrack(cues: [], timed: true);
    }

    final extension = _extensionOf(filename);
    return switch (extension) {
      'lrc' => _parseLrc(text),
      'vtt' => _parseVtt(text),
      'txt' => _parseLooseText(text),
      _ => _parseLooseText(text),
    };
  }

  static SubtitleTrack _parseLooseText(String text) {
    if (_looksLikeVtt(text)) return _parseVtt(text);
    if (_looksLikeLrc(text)) return _parseLrc(text);
    return SubtitleTrack(
      cues: [SubtitleCue(start: Duration.zero, text: text.trim())],
      timed: false,
    );
  }

  static bool _looksLikeVtt(String text) =>
      text.contains('WEBVTT') || text.contains('-->');

  static bool _looksLikeLrc(String text) => _lrcTime.hasMatch(text);

  // ---------------------------------------------------------------------------
  // LRC
  // ---------------------------------------------------------------------------

  static SubtitleTrack _parseLrc(String text) {
    var offset = 0;
    final entries = <_TimedText>[];

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final offsetMatch = _lrcOffset.firstMatch(line);
      if (offsetMatch != null) {
        offset = int.tryParse(offsetMatch.group(1) ?? '') ?? offset;
        continue;
      }

      final stamps = _lrcTime.allMatches(line).toList();
      if (stamps.isEmpty) continue;

      var body = line;
      for (final stamp in stamps) {
        body = body.replaceFirst(stamp.group(0)!, '');
      }
      body = body.trim();
      if (body.startsWith('{')) continue;

      for (final stamp in stamps) {
        final startMs = _lrcMilliseconds(stamp) + offset;
        entries.add(
          _TimedText(Duration(milliseconds: startMs < 0 ? 0 : startMs), body),
        );
      }
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return _timedTrack(entries);
  }

  /// 取 [entries] 中的非空文本，下一条（含空行）的时间作为结束时间。
  static SubtitleTrack _timedTrack(List<_TimedText> entries) {
    final cues = <SubtitleCue>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.text.isEmpty) continue;

      Duration? end;
      for (var next = i + 1; next < entries.length; next++) {
        if (entries[next].start > entry.start) {
          end = entries[next].start;
          break;
        }
      }
      cues.add(SubtitleCue(start: entry.start, end: end, text: entry.text));
    }
    return SubtitleTrack(cues: cues, timed: true);
  }

  static int _lrcMilliseconds(RegExpMatch match) {
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final fraction = match.group(3) ?? '';
    final millis = fraction.isEmpty
        ? 0
        : int.parse(fraction.padRight(3, '0').substring(0, 3));
    return minutes * Duration.millisecondsPerMinute +
        seconds * Duration.millisecondsPerSecond +
        millis;
  }

  // ---------------------------------------------------------------------------
  // WebVTT
  // ---------------------------------------------------------------------------

  static SubtitleTrack _parseVtt(String text) {
    final lines = text.split('\n');
    final cues = <SubtitleCue>[];
    var index = 0;

    while (index < lines.length) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        index++;
        continue;
      }
      if (line.startsWith('WEBVTT')) {
        index++;
        continue;
      }
      if (line.startsWith('NOTE') ||
          line.startsWith('STYLE') ||
          line.startsWith('REGION')) {
        while (index < lines.length && lines[index].trim().isNotEmpty) {
          index++;
        }
        continue;
      }

      final timing = _vttTiming.firstMatch(line);
      if (timing == null) {
        index++;
        continue;
      }

      final start = _vttDuration(timing.group(1)!);
      final end = _vttDuration(timing.group(2)!);
      index++;

      final body = <String>[];
      while (index < lines.length && lines[index].trim().isNotEmpty) {
        body.add(lines[index].trim());
        index++;
      }

      final cueText = _cleanVttText(body.join('\n'));
      if (cueText.isEmpty) continue;
      cues.add(SubtitleCue(start: start, end: end, text: cueText));
    }

    cues.sort((a, b) => a.start.compareTo(b.start));
    return SubtitleTrack(cues: cues, timed: true);
  }

  static Duration _vttDuration(String value) {
    final parts = value.replaceAll(',', '.').split(':');
    final secondsPart = parts.removeLast();
    final minutes = parts.isEmpty ? 0 : int.parse(parts.removeLast());
    final hours = parts.isEmpty ? 0 : int.parse(parts.removeLast());

    final secondParts = secondsPart.split('.');
    final seconds = int.parse(secondParts.first);
    final fraction = secondParts.length > 1 ? secondParts[1] : '';
    final millis = fraction.isEmpty
        ? 0
        : int.parse(fraction.padRight(3, '0').substring(0, 3));

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: millis,
    );
  }

  static String _cleanVttText(String text) {
    return text
        .replaceAll(_vttTag, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  // ---------------------------------------------------------------------------
  // 通用
  // ---------------------------------------------------------------------------

  static String _normalize(String text) =>
      _stripBom(text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

  static String _stripBom(String text) =>
      text.startsWith('\uFEFF') ? text.substring(1) : text;

  static String _extensionOf(String filename) {
    final name = filename.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static final RegExp _lrcTime = RegExp(
    r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]',
  );

  static final RegExp _lrcOffset = RegExp(
    r'\[offset:\s*([+-]?\d+)\s*\]',
    caseSensitive: false,
  );

  static final RegExp _vttTiming = RegExp(
    r'^\s*((?:\d+:)?\d{1,2}:\d{2}[.,]\d{1,3})'
    r'\s*-->\s*'
    r'((?:\d+:)?\d{1,2}:\d{2}[.,]\d{1,3})',
  );

  static final RegExp _vttTag = RegExp(r'<[^>]*>');
}

/// 解析过程中的临时行，空文本行用于给上一条字幕封口。
class _TimedText {
  const _TimedText(this.start, this.text);

  final Duration start;
  final String text;
}
