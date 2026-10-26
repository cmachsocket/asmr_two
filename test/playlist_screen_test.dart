import 'dart:io';

import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/audio/audio_player_service.dart';
import 'package:asmr_two/core/default.dart';
import 'package:asmr_two/core/storage/session_store.dart';
import 'package:asmr_two/screens/detail_screen.dart';
import 'package:asmr_two/screens/playlist_screen.dart';
import 'package:asmr_two/state/auth_controller.dart';
import 'package:asmr_two/state/player_controller.dart';
import 'package:asmr_two/widgets/asmr_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_adapter.dart';
import 'support/fake_just_audio_platform.dart';
import 'support/fake_storage.dart';
import 'support/mock_image.dart';
import 'support/mock_works.dart';

const String _playlistId = 'uuid-1';

/// 播放列表信息。
Map<String, dynamic> playlistMetadataJson({String userName = 'tester'}) => {
  'id': _playlistId,
  'name': '默认收藏',
  'description': '常听的几首',
  'privacy': 2,
  'works_count': 3,
  'user_name': userName,
  'created_at': '2026-01-01 00:00:00',
  'updated_at': '2026-01-02 00:00:00',
  'liked_count': 4,
};

void main() {
  late Directory storageDir;
  late FakeJustAudioPlatform platform;
  late FakeAdapter adapter;

  setUp(() async {
    Get.testMode = true;
    storageDir = await initFakeStorage();
    platform = FakeJustAudioPlatform();
  });

  tearDown(() async {
    Get.reset();
    await platform.close();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  /// 渲染播放列表页并等接口数据落地。
  ///
  /// 依赖的装配放在用例体内：`setUp` 在 widget 测试的假时钟之外，
  /// 在那里发起的登录恢复不会在 `pumpAndSettle` 里完成。
  Future<void> pumpPlaylist(
    WidgetTester tester, {
    String userName = 'tester',
  }) async {
    SharedPreferences.setMockInitialValues({'jwt-token': 'test-token'});
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
      if (path == '/api/playlist/get-playlist-metadata') {
        return jsonBody(playlistMetadataJson(userName: userName));
      }
      if (path == '/api/playlist/get-playlist-works') {
        return jsonBody(worksResponse());
      }
      if (path == '/api/playlist/delete-playlist') {
        return jsonBody({'id': _playlistId});
      }
      if (path.startsWith('/api/work/')) {
        return jsonBody({'id': 1, 'title': '测试作品'});
      }
      if (path.startsWith('/api/tracks/')) {
        return jsonBody(const []);
      }
      return errorBody(message: 'unexpected $path');
    });
    adapter = fake;

    final api = AsmrApi(client);
    Get.put<AsmrApi>(api);
    Get.put<SessionStore>(SessionStore(prefs));
    Get.put(AuthController(api: api, sessionStore: Get.find<SessionStore>()));
    Get.put(
      AudioPlayerService(
        api: api,
        player: AudioPlayer(
          handleAudioSessionActivation: false,
          handleInterruptions: false,
        ),
      ),
    );
    Get.put(PlayerController());

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Navigator(
            key: Get.nestedKey(DefaultValues.shellNavigatorId),
            initialRoute: '/',
            onGenerateRoute: (settings) => settings.name == '/'
                ? GetPageRoute(
                    page: () => const PlaylistScreen(playlistId: _playlistId),
                    binding: PlaylistScreenBinding(_playlistId),
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

  testWidgets('播放列表页展示列表信息与列表内的作品', (tester) async {
    await pumpPlaylist(tester);

    expect(tester.takeException(), isNull);
    // 列表名称与归属信息都放在 app bar 上
    expect(find.widgetWithText(AppBar, '默认收藏'), findsOneWidget);
    expect(find.textContaining('常听的几首'), findsOneWidget);
    expect(find.textContaining('tester'), findsOneWidget);
    expect(find.textContaining('公开'), findsOneWidget);
    expect(find.byType(AsmrCard), findsWidgets);
  });

  testWidgets('点作品进入作品详情页', (tester) async {
    await pumpPlaylist(tester);

    await tester.tap(find.byType(AsmrCard).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('列表信息取不到时仍能展示作品', (tester) async {
    SharedPreferences.setMockInitialValues({'jwt-token': 'test-token'});
    final prefs = await SharedPreferences.getInstance();
    final (client, _) = buildClient((options) async {
      return options.uri.path == '/api/playlist/get-playlist-works'
          ? jsonBody(worksResponse())
          : errorBody(message: 'boom');
    });
    final api = AsmrApi(client);
    Get.put<AsmrApi>(api);
    Get.put<SessionStore>(SessionStore(prefs));
    Get.put(AuthController(api: api, sessionStore: Get.find<SessionStore>()));

    await mockCoverImage(tester, mockCoverUrl);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Navigator(
            key: Get.nestedKey(DefaultValues.shellNavigatorId),
            initialRoute: '/',
            onGenerateRoute: (settings) => settings.name == '/'
                ? GetPageRoute(
                    page: () => const PlaylistScreen(playlistId: _playlistId),
                    binding: PlaylistScreenBinding(_playlistId),
                  )
                : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AsmrCard), findsWidgets);
    expect(find.widgetWithText(AppBar, '播放列表'), findsOneWidget);
  });

  testWidgets('自己创建的列表才有删除入口', (tester) async {
    await pumpPlaylist(tester);

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('别人的列表没有删除入口', (tester) async {
    await pumpPlaylist(tester, userName: 'someone');

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('确认后删除播放列表', (tester) async {
    await pumpPlaylist(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('删除播放列表'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    // 提示会自己消失，别把定时器留在用例里。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final request = adapter.requests.lastWhere(
      (request) => request.uri.path == '/api/playlist/delete-playlist',
    );
    expect(request.data['id'], _playlistId);
  });

  testWidgets('取消删除不会发请求', (tester) async {
    await pumpPlaylist(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.any(
        (request) => request.uri.path == '/api/playlist/delete-playlist',
      ),
      isFalse,
    );
  });
}
