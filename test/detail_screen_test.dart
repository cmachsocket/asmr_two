import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/audio/audio_player_service.dart';
import 'package:asmr_two/core/default.dart';
import 'package:asmr_two/core/models/work.dart';
import 'package:asmr_two/controller/home_controller.dart';
import 'package:asmr_two/screens/detail_screen.dart';
import 'package:asmr_two/screens/find_screen.dart';
import 'package:asmr_two/screens/search_screen.dart';
import 'package:asmr_two/state/player_controller.dart';
import 'package:asmr_two/widgets/asmr_body.dart';
import 'package:asmr_two/widgets/asmr_card.dart';
import 'package:asmr_two/widgets/bottom_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import 'support/fake_adapter.dart';
import 'support/fake_just_audio_platform.dart';
import 'support/mock_image.dart';
import 'support/mock_works.dart';

/// 详情页用的作品，带标签、声优与总时长。
Map<String, dynamic> _workJson() => {
  'id': 1,
  'title': '测试作品',
  'circle_id': 1,
  'name': '测试社团',
  'nsfw': false,
  'release': '2026-09-23',
  'price': 0,
  'dl_count': 1200,
  'review_count': 3,
  'rate_count': 9,
  'rate_average_2dp': 4.8,
  'has_subtitle': true,
  'duration': 754,
  'tags': [
    {'id': 1, 'name': 'ASMR'},
    {'id': 2, 'name': '耳语'},
  ],
  'vas': [
    {'id': 'va-1', 'name': '测试声优'},
  ],
  'mainCoverUrl': mockCoverUrl,
};

/// 详情页用的曲目树。
const List<Map<String, dynamic>> _trackJson = [
  {
    'type': 'folder',
    'title': 'mp3',
    'children': [
      {
        'type': 'audio',
        'title': '第一曲',
        'hash': '1/2',
        'mediaStreamUrl': 'https://cdn.example.com/1.mp3',
        'duration': 60,
      },
      {
        'type': 'audio',
        'title': '第二曲',
        'hash': '1/3',
        'mediaStreamUrl': 'https://cdn.example.com/2.mp3',
        'duration': 90,
      },
    ],
  },
];

/// 造一个带外壳导航器的应用。
///
/// 外壳导航器是底部播放器所在的那一层，推进去的页面仍在应用内；
/// [bottom] 是播放器这类常驻在导航器下方的部件。
Widget shellApp({
  required Widget home,
  Widget? bottom,
  Bindings? initialBinding,
}) {
  return GetMaterialApp(
    initialBinding: initialBinding,
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Navigator(
              key: Get.nestedKey(DefaultValues.shellNavigatorId),
              initialRoute: '/',
              onGenerateRoute: (settings) =>
                  settings.name == '/' ? GetPageRoute(page: () => home) : null,
            ),
          ),
          ?bottom,
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeJustAudioPlatform platform;
  late AudioPlayerService audio;
  late FakeAdapter adapter;

  /// 当前假接口的响应，测试里可以随时换掉。
  late Future<ResponseBody> Function(RequestOptions options) handler;

  setUp(() {
    Get.testMode = true;
    platform = FakeJustAudioPlatform();
    handler = (options) async {
      final path = options.uri.path;
      if (path.startsWith('/api/work/')) return jsonBody(_workJson());
      if (path.startsWith('/api/tracks/')) return jsonBody(_trackJson);
      if (path.startsWith('/api/search')) return jsonBody(worksResponse());
      if (path == '/api/works') return jsonBody(worksResponse());
      return errorBody(message: 'unexpected $path');
    };
    final (client, fake) = buildClient((options) => handler(options));
    adapter = fake;

    final api = AsmrApi(client);
    Get.put<AsmrApi>(api);
    audio = Get.put(
      AudioPlayerService(
        api: api,
        player: AudioPlayer(
          handleAudioSessionActivation: false,
          handleInterruptions: false,
        ),
      ),
    );
    Get.put(PlayerController());
    Get.put(HomeController());
  });

  tearDown(() async {
    Get.reset();
    await platform.close();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  /// 渲染详情页并等接口数据落地。
  Future<void> pumpDetail(WidgetTester tester) async {
    // 详情页内容比默认视口高，放大视口让曲目行一次性完成布局。
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: DetailScreenBinding(1),
        home: const DetailScreen(workId: 1),
      ),
    );
    await tester.pumpAndSettle();
    // 收尾时把整棵树拆掉,路由的销毁就不会拖到下一个用例
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('详情页渲染作品信息与曲目树', (tester) async {
    await pumpDetail(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('测试作品'), findsWidgets);
    expect(find.textContaining('测试社团'), findsOneWidget);
    expect(find.textContaining('12:34'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'ASMR'), findsOneWidget);
    expect(find.text('mp3'), findsOneWidget);
    expect(find.text('第一曲'), findsOneWidget);
    expect(find.text('第二曲'), findsOneWidget);
  });

  testWidgets('点曲目行从该曲起播', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('第二曲'));
    await tester.pumpAndSettle();

    expect(audio.snapshot.value.queue.length, 2);
    expect(audio.snapshot.value.current?.title, '第二曲');
  });

  testWidgets('播放全部把整部作品交给播放队列', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('播放全部'));
    await tester.pumpAndSettle();

    expect(audio.snapshot.value.queue.length, 2);
    expect(audio.snapshot.value.current?.title, '第一曲');
  });

  testWidgets('点标签会打开该标签的搜索页', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      shellApp(
        home: const DetailScreen(workId: 1),
        initialBinding: DetailScreenBinding(1),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    await tester.tap(find.widgetWithText(ActionChip, 'ASMR'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SearchPage), findsOneWidget);
    expect(
      Uri.decodeComponent(adapter.requests.last.path),
      contains(r'$tag:ASMR$'),
    );
  });

  testWidgets('标签搜索页推进外壳导航器，底部播放器常驻', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      shellApp(
        home: const FindScreen(),
        bottom: const SizedBox(height: 120, child: BottomPlayer()),
        initialBinding: FindScreenBinding(),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    await tester.tap(find.widgetWithText(ActionChip, 'ASMR').first);
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
    // 搜索页在外壳导航器里，底部播放器没有被盖掉
    expect(find.byType(BottomPlayer), findsOneWidget);
  });

  testWidgets('作品信息加载失败时给出重试入口', (tester) async {
    handler = (options) async => errorBody(message: 'boom');

    await pumpDetail(tester);

    expect(find.text('boom'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('点作品卡片打开详情页', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      shellApp(
        home: ASMRBody(
          works: [Work.fromJson(_workJson())],
          onWorkTap: openDetail,
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    await tester.tap(find.byType(AsmrCard).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('第一曲'), findsOneWidget);
  });

  testWidgets('详情页推进外壳导航器，底部播放器常驻', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      shellApp(
        home: ASMRBody(
          works: [Work.fromJson(_workJson())],
          onWorkTap: openDetail,
        ),
        bottom: const SizedBox(height: 120, child: BottomPlayer()),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    await tester.tap(find.byType(AsmrCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    // 详情页盖在外壳导航器里，外壳（含播放器）没有被盖掉
    expect(find.byType(BottomPlayer), findsOneWidget);
  });

  testWidgets('详情页自带 app bar，tab 页面的 app bar 被盖掉', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      shellApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('发现')),
          body: ASMRBody(
            works: [Work.fromJson(_workJson())],
            onWorkTap: openDetail,
          ),
        ),
        bottom: const SizedBox(height: 120, child: BottomPlayer()),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    await tester.tap(find.byType(AsmrCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    // 详情页的 app bar 顶上来，tab 页面的 app bar 被盖掉
    expect(find.widgetWithText(AppBar, '测试作品'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '发现'), findsNothing);
    // 底部播放器常驻
    expect(find.byType(BottomPlayer), findsOneWidget);
  });
}
