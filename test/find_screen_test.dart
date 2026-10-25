import 'dart:async';

import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/screens/find_screen.dart';
import 'package:asmr_two/state/work_feed_controller.dart';
import 'package:asmr_two/widgets/asmr_card.dart';
import 'package:asmr_two/widgets/floating_paginator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_adapter.dart';
import 'support/mock_image.dart';
import 'support/mock_works.dart';

void main() {
  late FakeAdapter adapter;

  /// 当前假接口的响应，测试里可以随时换掉。
  late Future<ResponseBody> Function(RequestOptions options) handler;

  setUp(() {
    Get.testMode = true;
    handler = (options) async {
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

  /// 渲染发现页并等接口数据落地。
  Future<void> pumpFind(WidgetTester tester) async {
    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: FindScreenBinding(),
        home: const FindScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('发现页渲染接口返回的作品且不触发 Obx 误用', (tester) async {
    await pumpFind(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AsmrCard), findsWidgets);
  });

  testWidgets('发现页浮着分页按钮', (tester) async {
    await pumpFind(tester);

    expect(find.byType(FloatingPaginator), findsOneWidget);
  });

  testWidgets('分页按钮拿到接口的总页数', (tester) async {
    await pumpFind(tester);

    final paginator = tester.widget<FloatingPaginator>(
      find.byType(FloatingPaginator),
    );
    expect(paginator.pageCount, 5);
    expect(paginator.currentPage, 1);
  });

  testWidgets('跳页会请求对应页并替换列表', (tester) async {
    await pumpFind(tester);

    // 接口请求走真实异步，不能在测试体里直接 await，
    // 否则假时钟停摆，响应永远回不来。
    unawaited(Get.find<WorkFeedController>().gotoPage(3));
    await tester.pumpAndSettle();

    expect(adapter.requests.last.queryParameters['page'], 3);
    expect(Get.find<WorkFeedController>().page.value, 3);
  });

  testWidgets('接口失败时给出重试入口', (tester) async {
    handler = (options) async => errorBody(message: 'boom');

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: FindScreenBinding(),
        home: const FindScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('重试'), findsOneWidget);
  });
}
