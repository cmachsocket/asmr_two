import 'dart:io';

import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/default.dart';
import 'package:asmr_two/core/storage/session_store.dart';
import 'package:asmr_two/controller/library_controller.dart';
import 'package:asmr_two/screens/playlist_create_screen.dart';
import 'package:asmr_two/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_adapter.dart';
import 'support/fake_storage.dart';
import 'support/mock_playlists.dart';

void main() {
  late Directory storageDir;
  late FakeAdapter adapter;

  setUp(() async {
    Get.testMode = true;
    storageDir = await initFakeStorage();
  });

  tearDown(() async {
    Get.reset();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  /// 装配依赖并渲染创建播放列表页。
  ///
  /// [loggedIn] 为 false 时不保存令牌，页面应提示先登录。
  Future<void> pumpCreate(WidgetTester tester, {bool loggedIn = true}) async {
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
      if (path == '/api/playlist/create-playlist') {
        return jsonBody({'id': 'uuid-new', 'name': '新列表', 'privacy': 0});
      }
      return errorBody(message: 'unexpected $path');
    });
    adapter = fake;
    Get.put<AsmrApi>(AsmrApi(client));
    Get.put<SessionStore>(SessionStore(prefs));
    final auth = Get.put(
      AuthController(
        api: Get.find<AsmrApi>(),
        sessionStore: Get.find<SessionStore>(),
      ),
    );
    Get.put(LibraryController(api: Get.find<AsmrApi>(), auth: auth));

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Navigator(
            key: Get.nestedKey(DefaultValues.shellNavigatorId),
            initialRoute: '/',
            onGenerateRoute: (settings) => GetPageRoute(
              page: () => settings.name == '/'
                  ? const Scaffold(body: Text('收藏库'))
                  : const PlaylistCreateScreen(),
              binding: settings.name == '/'
                  ? null
                  : PlaylistCreateScreenBinding(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    openCreatePlaylist();
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('创建页有名称、可见性与创建按钮', (tester) async {
    await pumpCreate(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('创建播放列表'), findsOneWidget);
    expect(find.text('名称'), findsOneWidget);
    expect(find.text('私密'), findsOneWidget);
    expect(find.text('公开'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('没填名称时创建按钮不可点', (tester) async {
    await pumpCreate(tester);

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).first, '新列表');
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('创建播放列表后回到收藏库页', (tester) async {
    await pumpCreate(tester);

    await tester.enterText(find.byType(TextField).first, '新列表');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    // 提示会自己消失，别把定时器留在用例里。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final request = adapter.requests.lastWhere(
      (request) => request.uri.path == '/api/playlist/create-playlist',
    );
    expect(request.data['name'], '新列表');
    expect(request.data['privacy'], 0);
    expect(find.byType(PlaylistCreateScreen), findsNothing);
    expect(find.text('收藏库'), findsOneWidget);
  });

  testWidgets('未登录时提示先登录', (tester) async {
    await pumpCreate(tester, loggedIn: false);

    expect(find.text('登录后才能创建播放列表'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
