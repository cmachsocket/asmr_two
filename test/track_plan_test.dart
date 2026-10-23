import 'package:asmr_two/core/audio/track_plan.dart';
import 'package:asmr_two/core/models/track.dart';
import 'package:flutter_test/flutter_test.dart';

TrackNode _folder(String title, List<TrackNode> children) =>
    TrackNode(type: 'folder', title: title, children: children);

TrackNode _audio(String title, {String? hash}) => TrackNode(
  type: 'audio',
  title: title,
  hash: hash ?? '1/2',
  streamUrl: 'https://cdn.example.com/$title.mp3',
);

void main() {
  test('目录节点产出目录行与音频行', () {
    final plan = TrackPlan.fromNodes(
      nodes: [
        _folder('mp3', [_audio('第一曲'), _audio('第二曲')]),
      ],
      workId: 7,
      workTitle: '作品',
      coverUrl: 'https://cdn.example.com/cover.jpg',
    );

    expect(plan.items.length, 2);
    expect(plan.rows.length, 3);
    expect(plan.rows.first, isA<TrackFolderRow>());
    expect((plan.rows.first as TrackFolderRow).title, 'mp3');
    expect(plan.rows[1], isA<TrackAudioRow>());
    expect((plan.rows[1] as TrackAudioRow).queueIndex, 0);
    expect((plan.rows[2] as TrackAudioRow).queueIndex, 1);
    expect(plan.items.first.workId, 7);
    expect(plan.items.first.workTitle, '作品');
  });

  test('顶层音频不产出目录行', () {
    final plan = TrackPlan.fromNodes(
      nodes: [_audio('单曲')],
      workId: 7,
      workTitle: '作品',
      coverUrl: '',
    );

    expect(plan.rows.length, 1);
    expect(plan.rows.single, isA<TrackAudioRow>());
  });

  test('嵌套目录保留完整路径', () {
    final plan = TrackPlan.fromNodes(
      nodes: [
        _folder('mp3', [
          _folder('特典', [_audio('闹钟')]),
        ]),
      ],
      workId: 7,
      workTitle: '作品',
      coverUrl: '',
    );

    expect(plan.items.single.folderLabel, 'mp3 / 特典');
  });

  test('没有可播放节点时队列为空', () {
    final plan = TrackPlan.fromNodes(
      nodes: [_folder('图片', [])],
      workId: 7,
      workTitle: '作品',
      coverUrl: '',
    );

    expect(plan.items, isEmpty);
    expect(plan.rows, isEmpty);
  });
}
