import 'dart:io';

import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/default.dart';
import 'package:asmr_two/core/storage/session_store.dart';
import 'package:asmr_two/screens/library_screen.dart';
import 'package:asmr_two/screens/playlist_screen.dart';
import 'package:asmr_two/state/auth_controller.dart';
import 'package:asmr_two/widgets/playlist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_adapter.dart';
import 'support/fake_storage.dart';
import 'support/mock_image.dart';
import 'support/mock_playlists.dart';
import 'support/mock_works.dart';

void main() {
  late Directory storageDir;
  late FakeAdapter adapter;

  setUp(() async {
    Get.testMode = true;
    storageDir = await initFakeStorage();
  });

  tearDown(() async {
    Get.reset();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  /// 装配依赖并渲染收藏库页。
  ///
  /// [loggedIn] 为 false 时不保存令牌，页面应给出登录入口。
  Future<void> pumpLibrary(WidgetTester tester, {bool loggedIn = true}) async {
    SharedPreferences.setMockInitialValues(
      loggedIn ? {'jwt-token': 'test-token'} : {},
    );
    final prefs = await SharedPreferences.getInstance();
    final (client, fake) = buildClient((options) async {
      final path = options.uri.path;
      if (path == '/api/auth/me') {
        return jsonBody({
          'user': {'loggedIn': true, 'name': 'tester'},
          'auth': true,
          'reg': true,
        });
      }
      if (path == '/api/playlist/get-playlists') {
        return jsonBody(playlistsResponse());
      }
      if (path == '/api/playlist/get-playlist-works') {
        return jsonBody(worksResponse());
      }
      return errorBody(message: 'unexpected $path');
    });
    adapter = fake;
    Get.put<AsmrApi>(AsmrApi(client));
    Get.put<SessionStore>(SessionStore(prefs));
    Get.put(
      AuthController(
        api: Get.find<AsmrApi>(),
        sessionStore: Get.find<SessionStore>(),
      ),
    );

    await mockCoverImage(tester, mockPlaylistCoverUrl);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Navigator(
            key: Get.nestedKey(DefaultValues.shellNavigatorId),
            initialRoute: '/',
            onGenerateRoute: (settings) => settings.name == '/'
                ? GetPageRoute(
                    page: () => const LibraryScreen(),
                    binding: LibraryScreenBinding(),
                  )
                : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('收藏库页展示接口返回的全部播放列表', (tester) async {
    await pumpLibrary(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(PlaylistCard), findsNWidgets(2));
    expect(find.text('默认收藏'), findsOneWidget);
    // 系统内置列表用中文名展示
    expect(find.text('我喜欢的'), findsOneWidget);
  });

  testWidgets('点播放列表卡片进入播放列表页', (tester) async {
    await pumpLibrary(tester);

    await tester.tap(find.text('默认收藏'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PlaylistScreen), findsOneWidget);
    final requests = adapter.requests.where(
      (request) => request.uri.path == '/api/playlist/get-playlist-works',
    );
    expect(requests, isNotEmpty);
    expect(requests.last.queryParameters['id'], 'uuid-1');
  });

  testWidgets('未登录时给出登录入口而不是播放列表', (tester) async {
    await pumpLibrary(tester, loggedIn: false);

    expect(find.text('登录后查看播放列表'), findsOneWidget);
    expect(find.text('去登录'), findsOneWidget);
    expect(find.byType(PlaylistCard), findsNothing);
  });

  testWidgets('换筛选条件会重新请求播放列表', (tester) async {
    await pumpLibrary(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, '我点赞的'));
    await tester.pumpAndSettle();

    final requests = adapter.requests.where(
      (request) => request.uri.path == '/api/playlist/get-playlists',
    );
    expect(requests, isNotEmpty);
    expect(requests.last.queryParameters['filterBy'], 'liked');
    // 选中的筛选项跟着状态走
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '我点赞的'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('接口失败时给出重试入口', (tester) async {
    SharedPreferences.setMockInitialValues({'jwt-token': 'test-token'});
    final prefs = await SharedPreferences.getInstance();
    final (client, _) = buildClient((options) async {
      if (options.uri.path == '/api/auth/me') {
        return jsonBody({
          'user': {'loggedIn': true, 'name': 'tester'},
          'auth': true,
          'reg': true,
        });
      }
      return errorBody(message: 'boom');
    });
    Get.put<AsmrApi>(AsmrApi(client));
    Get.put<SessionStore>(SessionStore(prefs));
    Get.put(
      AuthController(
        api: Get.find<AsmrApi>(),
        sessionStore: Get.find<SessionStore>(),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Navigator(
            key: Get.nestedKey(DefaultValues.shellNavigatorId),
            initialRoute: '/',
            onGenerateRoute: (settings) => settings.name == '/'
                ? GetPageRoute(
                    page: () => const LibraryScreen(),
                    binding: LibraryScreenBinding(),
                  )
                : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('boom'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
