import 'package:asmr_two/widgets/floating_paginator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_paginator/number_paginator.dart';

/// 把分页器放进最小可用的应用外壳。
Widget _app(FloatingPaginator paginator) {
  return MaterialApp(
    home: Scaffold(body: Center(child: paginator)),
  );
}

void main() {
  testWidgets('点击按钮弹出页码选择器', (tester) async {
    await tester.pumpWidget(
      _app(
        FloatingPaginator(pageCount: 10, currentPage: 1, onPageChange: (_) {}),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(NumberPaginator), findsOneWidget);
  });

  testWidgets('选择页码后回调从 1 开始的页码', (tester) async {
    int? selected;
    await tester.pumpWidget(
      _app(
        FloatingPaginator(
          pageCount: 10,
          currentPage: 1,
          onPageChange: (page) => selected = page,
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(selected, 5);
  });

  testWidgets('选择器高亮当前页', (tester) async {
    await tester.pumpWidget(
      _app(
        FloatingPaginator(pageCount: 10, currentPage: 3, onPageChange: (_) {}),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    final selected = tester
        .widgetList<NumberButton>(find.byType(NumberButton))
        .where((button) => button.isSelected)
        .toList();
    expect(selected.length, 1);
    expect(selected.single.index, 2);
  });
}
