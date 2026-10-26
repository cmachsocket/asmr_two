import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/models/work.dart';
import 'package:asmr_two/widgets/add_to_playlist_sheet.dart';
import 'package:asmr_two/widgets/asmr_body.dart';
import 'package:asmr_two/widgets/asmr_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_adapter.dart';
import 'support/mock_image.dart';
import 'support/mock_works.dart';

/// 作品详情页/列表用的作品。
Work _work(int id) => Work(
  id: id,
  title: '作品 $id',
  circleId: 1,
  circleName: '社团',
  nsfw: false,
  release: '2026-01-01',
  dlCount: 0,
  price: 0,
  reviewCount: 0,
  rateCount: 0,
  rateAverage: 0,
  mainCoverUrl: mockCoverUrl,
);

/// 我的播放列表，第二个已经收藏了该作品。
Map<String, dynamic> _myPlaylistsResponse() => {
  'playlists': [
    {'id': 'uuid-1', 'name': '默认收藏', 'works_count': 3, 'exist': false},
    {'id': 'uuid-2', 'name': '我喜欢的', 'works_count': 5, 'exist': true},
  ],
  'pagination': {'currentPage': 1, 'pageSize': 12, 'totalCount': 2},
};

void main() {
  late FakeAdapter adapter;

  setUp(() async {
    Get.testMode = true;
    adapter = FakeAdapter((options) async => jsonBody({}));
  });

  tearDown(() {
    Get.reset();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  /// 渲染带长按/右键入口的作品网格。
  Future<void> pumpBody(WidgetTester tester) async {
    final (client, fake) = buildClient((options) async {
      final path = options.uri.path;
      if (path == '/api/playlist/get-work-exist-status-in-my-playlists') {
        return jsonBody(_myPlaylistsResponse());
      }
      return jsonBody({'id': 'uuid', 'rowCount': 1});
    });
    adapter = fake;
    Get.put<AsmrApi>(AsmrApi(client));

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ASMRBody(
              works: [_work(1)],
              onAddToPlaylist: (workId) => showAddToPlaylist(context, workId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('长按作品卡片弹出播放列表面板', (tester) async {
    await pumpBody(tester);

    await tester.longPress(find.byType(AsmrCard));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AddToPlaylistSheet), findsOneWidget);
    expect(find.text('默认收藏'), findsOneWidget);
    expect(find.text('我喜欢的'), findsOneWidget);
    // 已在列表里的作品打勾
    final marked = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, '我喜欢的'),
    );
    expect(marked.value, isTrue);
    final unmarked = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, '默认收藏'),
    );
    expect(unmarked.value, isFalse);
  });

  testWidgets('右键作品卡片也能弹出播放列表面板', (tester) async {
    await pumpBody(tester);

    await tester.tap(find.byType(AsmrCard), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AddToPlaylistSheet), findsOneWidget);
  });

  testWidgets('点面板里的列表把作品加进去', (tester) async {
    await pumpBody(tester);

    await tester.longPress(find.byType(AsmrCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认收藏'));
    await tester.pumpAndSettle();

    final request = adapter.requests.lastWhere(
      (request) => request.uri.path == '/api/playlist/add-works-to-playlist',
    );
    expect(request.data, {
      'id': 'uuid-1',
      'works': [1],
    });
  });

  testWidgets('再点一次已加入的列表会把作品移出', (tester) async {
    await pumpBody(tester);

    await tester.longPress(find.byType(AsmrCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我喜欢的'));
    await tester.pumpAndSettle();

    final request = adapter.requests.lastWhere(
      (request) =>
          request.uri.path == '/api/playlist/remove-works-from-playlist',
    );
    expect(request.data, {
      'id': 'uuid-2',
      'works': [1],
    });
  });

  testWidgets('加入后列表里的作品数跟着加一', (tester) async {
    await pumpBody(tester);

    await tester.longPress(find.byType(AsmrCard));
    await tester.pumpAndSettle();
    expect(find.text('3 个作品'), findsOneWidget);

    await tester.tap(find.text('默认收藏'));
    await tester.pumpAndSettle();

    expect(find.text('4 个作品'), findsOneWidget);
    expect(find.text('3 个作品'), findsNothing);
  });

  testWidgets('移出后列表里的作品数跟着减一', (tester) async {
    await pumpBody(tester);

    await tester.longPress(find.byType(AsmrCard));
    await tester.pumpAndSettle();
    expect(find.text('5 个作品'), findsOneWidget);

    await tester.tap(find.text('我喜欢的'));
    await tester.pumpAndSettle();

    expect(find.text('4 个作品'), findsOneWidget);
    expect(find.text('5 个作品'), findsNothing);
  });
}
