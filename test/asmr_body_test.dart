import 'package:asmr_two/core/models/work.dart';
import 'package:asmr_two/widgets/asmr_body.dart';
import 'package:asmr_two/widgets/asmr_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mock_image.dart';

const String _coverUrl = 'https://cmach.ccwu.cc/4.png';

List<Work> _works(int count) => [
  for (var i = 0; i < count; i++)
    Work(
      id: i,
      title: '作品 ${i + 1}',
      circleId: 1,
      circleName: '社团',
      nsfw: false,
      release: '2026-01-01',
      dlCount: 0,
      price: 0,
      reviewCount: 0,
      rateCount: 0,
      rateAverage: 0,
      mainCoverUrl: _coverUrl,
    ),
];

/// 渲染 [ASMRBody] 并返回实际排布的列数（按卡片左边界去重）。
Future<int> _columnsAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await mockCoverImage(tester, _coverUrl);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ASMRBody(works: _works(8))),
    ),
  );
  await tester.pump();

  final lefts = <double>{};
  for (final element in find.byType(AsmrCard).evaluate()) {
    final box = element.renderObject! as RenderBox;
    lefts.add(box.localToGlobal(Offset.zero).dx);
  }
  return lefts.length;
}

void main() {
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('容器 1:1 时排 4 列', (tester) async {
    expect(await _columnsAt(tester, const Size(400, 400)), 4);
  });

  testWidgets('容器变窄变高时列数减少，但不少于 2 列', (tester) async {
    expect(await _columnsAt(tester, const Size(400, 1200)), 2);
  });

  testWidgets('容器变宽变矮时列数增加，但不超过 6 列', (tester) async {
    expect(await _columnsAt(tester, const Size(1200, 400)), 6);
  });

  testWidgets('作品标题与时长按 Work 渲染', (tester) async {
    await mockCoverImage(tester, _coverUrl);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ASMRBody(
            works: [
              Work(
                id: 1,
                title: '标题',
                circleId: 1,
                circleName: '社团',
                nsfw: false,
                release: '2026-01-01',
                dlCount: 0,
                price: 0,
                reviewCount: 0,
                rateCount: 0,
                rateAverage: 0,
                duration: 754,
                mainCoverUrl: _coverUrl,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('标题'), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);
  });

  testWidgets('点卡片把作品 id 交给回调', (tester) async {
    await mockCoverImage(tester, _coverUrl);
    final tapped = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ASMRBody(works: _works(2), onWorkTap: tapped.add),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(AsmrCard).first);
    await tester.pump();

    expect(tapped, [0]);
  });
}
