import 'package:asmr_two/core/api/api_client.dart';
import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/screens/home_screen.dart';
import 'package:asmr_two/state/work_feed_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_adapter.dart';

/// 用假适配器替换真实接口的装配。
class _TestBinding extends Bindings {
  _TestBinding(this.adapter);

  final FakeAdapter adapter;

  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(
      () => ApiClient(
        tokenProvider: () => null,
        dio: Dio()..httpClientAdapter = adapter,
      ),
      fenix: true,
    );
    Get.lazyPut<AsmrApi>(() => AsmrApi(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<WorkFeedController>(
      () => WorkFeedController(Get.find<AsmrApi>()),
      fenix: true,
    );
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('首页渲染作品列表', (tester) async {
    final adapter = FakeAdapter(
      (options) async => jsonBody({
        'works': [
          {
            'id': 1,
            'title': '第一部作品',
            'name': '社团',
            'release': '2026-09-23',
            'rate_count': 9,
            'rate_average_2dp': 4.8,
          },
        ],
        'pagination': {'currentPage': 1, 'pageSize': 20, 'totalCount': 1},
      }),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: _TestBinding(adapter),
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('第一部作品'), findsOneWidget);
    expect(find.textContaining('社团'), findsOneWidget);
    expect(adapter.requests.single.uri.path, '/api/works');
  });

  testWidgets('接口失败时展示错误与重试入口', (tester) async {
    final adapter = FakeAdapter(
      (options) async => errorBody(statusCode: 500, message: 'server error'),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: _TestBinding(adapter),
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('重试'), findsOneWidget);
  });
}
