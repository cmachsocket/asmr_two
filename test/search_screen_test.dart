import 'dart:async';

import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/controller/search_controller.dart';
import 'package:asmr_two/screens/search_screen.dart';
import 'package:asmr_two/widgets/asmr_card.dart';
import 'package:asmr_two/widgets/floating_paginator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_adapter.dart';
import 'support/mock_filters.dart';
import 'support/mock_image.dart';
import 'support/mock_works.dart';

void main() {
  late FakeAdapter adapter;

  /// 当前假接口的响应，测试里可以随时换掉。
  late Future<ResponseBody> Function(RequestOptions options) handler;

  setUp(() {
    Get.testMode = true;
    handler = (options) async {
      final path = options.uri.path;
      if (path == '/api/tags/') return jsonBody(mockTags());
      if (path == '/api/vas/') return jsonBody(mockVoiceActors());
      final page = options.queryParameters['page'] as int? ?? 1;
      return jsonBody(worksResponse(page: page));
    };
    final (client, fake) = buildClient((options) => handler(options));
    adapter = fake;
    Get.put<AsmrApi>(AsmrApi(client));
  });

  tearDown(() {
    Get.reset();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  /// 渲染搜索页。
  Future<void> pumpSearch(WidgetTester tester) async {
    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: SearchScreenBinding(),
        home: const Scaffold(body: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 在搜索栏里提交关键字。
  Future<void> submitKeyword(WidgetTester tester, String keyword) async {
    await tester.enterText(find.byType(TextField).first, keyword);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets('没有关键字时提示输入关键字或选择筛选条件', (tester) async {
    await pumpSearch(tester);

    expect(find.text('输入关键字或选择筛选条件'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('提交关键字后展示接口返回的作品', (tester) async {
    await pumpSearch(tester);

    await submitKeyword(tester, 'ASMR');

    expect(Uri.decodeComponent(adapter.requests.last.path), contains('ASMR'));
    expect(find.byType(AsmrCard), findsWidgets);
    expect(find.byType(FloatingPaginator), findsOneWidget);
  });

  testWidgets('排序面板可以改排序字段', (tester) async {
    await pumpSearch(tester);
    await submitKeyword(tester, 'ASMR');

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    expect(find.text('下载量'), findsOneWidget);
    await tester.tap(find.text('下载量'));
    await tester.pumpAndSettle();

    expect(adapter.requests.last.queryParameters['order'], 'dl_count');
  });

  testWidgets('筛选面板可以按标签筛选', (tester) async {
    await pumpSearch(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(find.text('测试标签'), findsOneWidget);
    await tester.tap(find.text('测试标签'));
    await tester.pumpAndSettle();

    expect(
      Uri.decodeComponent(adapter.requests.last.path),
      contains(r'$tag:测试标签$'),
    );
  });

  testWidgets('筛选面板用网格排布选项', (tester) async {
    await pumpSearch(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final first = tester.getTopLeft(find.text('ASMR'));
    final second = tester.getTopLeft(find.text('治愈'));
    expect(second.dx, greaterThan(first.dx));
    expect(second.dy, closeTo(first.dy, 1));
  });

  testWidgets('筛选面板可以按声优筛选', (tester) async {
    await pumpSearch(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    await tester.tap(find.text('声优'));
    await tester.pumpAndSettle();

    expect(find.text('测试声优'), findsOneWidget);
    await tester.tap(find.text('测试声优'));
    await tester.pumpAndSettle();

    expect(
      Uri.decodeComponent(adapter.requests.last.path),
      contains(r'$va:测试声优$'),
    );
  });

  testWidgets('搜索失败时给出重试入口', (tester) async {
    handler = (options) async => errorBody(message: 'boom');

    await pumpSearch(tester);
    await submitKeyword(tester, 'ASMR');

    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('加载途中改筛选条件也会生效', (tester) async {
    await pumpSearch(tester);

    final controller = Get.find<SearchScreenController>();
    unawaited(controller.search('ASMR'));
    controller.toggleTag('测试标签');
    await tester.pumpAndSettle();

    expect(controller.keyword.value, r'ASMR $tag:测试标签$');
    expect(
      Uri.decodeComponent(adapter.requests.last.path),
      contains(r'$tag:测试标签$'),
    );
  });

  testWidgets('搜索控制器把关键字与筛选条件编码进搜索关键字', (tester) async {
    await pumpSearch(tester);

    final controller = Get.find<SearchScreenController>();
    // 接口请求走真实异步，不能在测试体里直接 await，否则假时钟停摆。
    unawaited(controller.search('耳ほじ'));
    await tester.pumpAndSettle();
    controller.toggleTag('ASMR');
    await tester.pumpAndSettle();

    expect(controller.keyword.value, r'耳ほじ $tag:ASMR$');
  });
}
