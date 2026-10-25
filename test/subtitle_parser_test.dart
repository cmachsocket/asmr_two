import 'dart:convert';

import 'package:asmr_two/core/subtitle/subtitle_parser.dart';
import 'package:charset/charset.dart' show gbk;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LRC', () {
    test('解析行时间与空行造成的间隔', () {
      final track = SubtitleParser.parse(
        '[ti:chapter01]\n'
        '[00:14.70]嗯？\n'
        '[00:15.70]\n'
        '[00:17.90]有什么事吗？\n'
        '[00:19.70]\n'
        '[00:20.70]我在看书呢\n',
        filename: 'chapter01.lrc',
      );

      expect(track.timed, isTrue);
      expect(track.cues.map((cue) => cue.text), ['嗯？', '有什么事吗？', '我在看书呢']);
      expect(track.cues.first.start, const Duration(milliseconds: 14700));
      expect(track.cues.first.end, const Duration(milliseconds: 15700));
      expect(track.indexAt(const Duration(milliseconds: 15000)), 0);
      expect(track.indexAt(const Duration(milliseconds: 16000)), -1);
      expect(track.indexAt(const Duration(milliseconds: 18000)), 1);
    });

    test('一行多个时间戳与 offset 偏移', () {
      final track = SubtitleParser.parse(
        '[offset:+500]\n'
        '[00:01.00][00:03.00]重复句\n',
        filename: 'repeat.lrc',
      );

      expect(track.cues.length, 2);
      expect(track.cues[0].start, const Duration(milliseconds: 1500));
      expect(track.cues[1].start, const Duration(milliseconds: 3500));
    });
  });

  group('WebVTT', () {
    test('解析 cue、多行正文并去掉标签', () {
      final track = SubtitleParser.parse(
        'WEBVTT\n'
        '\n'
        '1\n'
        '00:00:01.000 --> 00:00:03.500 align:start\n'
        '<v Speaker>你好\n'
        '世界\n'
        '\n'
        '00:00:04.000 --> 00:00:05.000\n'
        '第二句\n',
        filename: 'chapter01.vtt',
      );

      expect(track.timed, isTrue);
      expect(track.cues.length, 2);
      expect(track.cues.first.text, '你好\n世界');
      expect(track.cues.first.start, const Duration(seconds: 1));
      expect(track.cues.first.end, const Duration(milliseconds: 3500));
      expect(track.indexAt(const Duration(seconds: 2)), 0);
      expect(track.indexAt(const Duration(milliseconds: 3600)), -1);
      expect(track.indexAt(const Duration(seconds: 4)), 1);
    });

    test('.txt 里的 WebVTT 内容按 VTT 解析', () {
      final track = SubtitleParser.parse(
        'WEBVTT\n\n00:01.000 --> 00:02.000\n文本字幕\n',
        filename: 'chapter01.txt',
      );

      expect(track.timed, isTrue);
      expect(track.cues.single.text, '文本字幕');
    });
  });

  group('纯文本', () {
    test('没有时间戳的台本整体展示', () {
      final track = SubtitleParser.parse('第一行\n第二行', filename: 'script.txt');

      expect(track.timed, isFalse);
      expect(track.cues.single.text, '第一行\n第二行');
      expect(track.indexAt(Duration.zero), -1);
    });

    test('空文件返回空字幕', () {
      final track = SubtitleParser.parse('  \n', filename: 'empty.lrc');

      expect(track.isEmpty, isTrue);
    });
  });

  group('编码', () {
    test('优先 UTF-8，失败后回退 GBK', () {
      final utf8Text = utf8.encode('\uFEFF你好');
      expect(SubtitleParser.decodeBytes(utf8Text), '你好');

      final gbkText = gbk.encode('中文字幕');
      expect(SubtitleParser.decodeBytes(gbkText), '中文字幕');
    });
  });
}
