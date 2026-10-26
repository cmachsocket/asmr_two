import 'package:asmr_two/controller/home_controller.dart';
import 'package:asmr_two/controller/search_controller.dart';
import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/state/work_feed_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_adapter.dart';
import 'support/mock_works.dart';

void main() {
  late FakeAdapter adapter;

  setUp(() {
    Get.testMode = true;
    final (client, fake) = buildClient(
      (options) async => jsonBody(
        worksResponse(page: options.queryParameters['page'] as int? ?? 1),
      ),
    );
    adapter = fake;
    Get.put<AsmrApi>(AsmrApi(client));
  });

  tearDown(() {
    Get.reset();
  });

  test('刷新发现页会重新拉取列表', () async {
    Get.put<WorkFeedController>(
      WorkFeedController(Get.find<AsmrApi>(), autoLoad: false),
    );
    final controller = Get.put<HomeController>(HomeController());
    final before = adapter.requests.length;

    await controller.refreshFind();

    expect(adapter.requests.length, before + 1);
    expect(controller.refreshing.value, isFalse);
  });

  test('刷新搜索页会重新拉取结果', () async {
    final search = Get.put<SearchScreenController>(
      SearchScreenController(Get.find<AsmrApi>()),
    );
    await search.search('耳语');
    final controller = Get.put<HomeController>(HomeController());
    final before = adapter.requests.length;

    await controller.refreshSearch();

    expect(adapter.requests.length, before + 1);
    expect(controller.refreshing.value, isFalse);
  });

  test('列表 controller 不在时刷新不会报错', () async {
    final controller = Get.put<HomeController>(HomeController());

    await controller.refreshFind();
    await controller.refreshSearch();

    expect(adapter.requests, isEmpty);
    expect(controller.refreshing.value, isFalse);
  });
}
