import 'package:asmr_two/core/models/playlist.dart';
import 'package:asmr_two/widgets/playlist_body.dart';
import 'package:asmr_two/widgets/playlist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mock_image.dart';

const String _coverUrl = 'https://cmach.ccwu.cc/4.png';

List<Playlist> _playlists() => [
  const Playlist(
    id: 'uuid-1',
    name: '默认收藏',
    worksCount: 3,
    privacy: PlaylistPrivacy.public,
  ),
  const Playlist(id: 'uuid-2', name: '__SYS_PLAYLIST_LIKED'),
];

void main() {
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('播放列表网格渲染全部列表', (tester) async {
    await mockCoverImage(tester, _coverUrl);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlaylistBody(playlists: _playlists())),
      ),
    );
    await tester.pump();

    expect(find.byType(PlaylistCard), findsNWidgets(2));
    expect(find.text('默认收藏'), findsOneWidget);
    // 系统内置列表用中文名展示
    expect(find.text('我喜欢的'), findsOneWidget);
  });

  testWidgets('点卡片把被点的列表交给回调', (tester) async {
    await mockCoverImage(tester, _coverUrl);
    final tapped = <Playlist>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistBody(playlists: _playlists(), onTap: tapped.add),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('默认收藏'));
    await tester.pump();

    expect(tapped.single.id, 'uuid-1');
  });

  testWidgets('没有封面时用占位色代替图片', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlaylistBody(playlists: _playlists())),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
