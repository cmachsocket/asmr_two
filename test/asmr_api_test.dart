import 'package:asmr_two/core/api/api_client.dart';
import 'package:asmr_two/core/api/api_endpoints.dart';
import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/models/playlist.dart';
import 'package:asmr_two/core/models/review.dart';
import 'package:asmr_two/core/models/track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_adapter.dart';

void main() {
  late FakeAdapter adapter;
  late AsmrApi api;

  setUp(() {
    adapter = FakeAdapter((options) async => jsonBody({'ok': true}));
    final dio = Dio()..httpClientAdapter = adapter;
    api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));
  });

  group('作品接口', () {
    test('作品列表解析分页与作品', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody({
          'works': [
            {'id': 1, 'title': '作品一'},
            {'id': 2, 'title': '作品二'},
          ],
          'pagination': {'currentPage': 1, 'pageSize': 2, 'totalCount': 10},
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      final page = await api.fetchWorks(pageSize: 2);

      expect(page.works.length, 2);
      expect(page.pagination.totalCount, 10);
      expect(adapter.requests.single.uri.path, '/api/works');
      expect(adapter.requests.single.queryParameters['order'], 'create_date');
      expect(adapter.requests.single.queryParameters['sort'], 'desc');
    });

    test('作品详情使用 /api/work/{id}', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody({'id': 42, 'title': '详情'}),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      final work = await api.fetchWork(42);

      expect(work.id, 42);
      expect(adapter.requests.single.uri.path, '/api/work/42');
    });

    test('曲目树请求带上 v=2', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody([
          {
            'type': 'folder',
            'title': 'mp3',
            'children': [
              {'type': 'audio', 'title': 'a.mp3', 'hash': '1/2'},
            ],
          },
        ]),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      final tracks = await api.fetchTracks(42);

      expect(tracks.single.children.single.hash, '1/2');
      expect(adapter.requests.single.uri.queryParameters['v'], '2');
    });
  });

  group('搜索接口', () {
    test('关键字会被编码进路径', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody({
          'works': [],
          'pagination': {'currentPage': 1, 'pageSize': 20, 'totalCount': 0},
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      await api.searchWorks(r'$tag:ASMR$');

      expect(adapter.requests.single.uri.path, '/api/search/%24tag%3AASMR%24');
      expect(
        adapter.requests.single.queryParameters['includeTranslationWorks'],
        true,
      );
    });

    test('超长关键字改用 POST', () async {
      await api.searchWorks('x' * (AsmrApi.searchPostThreshold + 1));

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.uri.path, '/api/search/');
    });

    test('空关键字直接返回空结果', () async {
      final page = await api.searchWorks('   ');

      expect(page.works, isEmpty);
      expect(adapter.requests, isEmpty);
    });
  });

  group('账号接口', () {
    test('登录使用 /api/auth/me 且不带鉴权头', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody({
          'user': {'loggedIn': true, 'name': 'u', 'recommenderUuid': 'uuid'},
          'token': 'jwt',
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      final result = await api.login('u', 'p');

      expect(result.token, 'jwt');
      expect(result.user.name, 'u');
      expect(result.recommenderUuid, 'uuid');
      expect(adapter.requests.single.uri.path, '/api/auth/me');
      expect(adapter.requests.single.method, 'POST');
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(adapter.requests.single.data, {'name': 'u', 'password': 'p'});
    });

    test('服务端没有返回令牌时抛出异常', () async {
      adapter = FakeAdapter((options) async => jsonBody({'user': {}}));
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      expect(api.login('u', 'p'), throwsA(isA<Exception>()));
    });
  });

  group('评论接口', () {
    test('提交评论使用 PUT 且字段名为 work_id', () async {
      await api.submitReview(
        workId: 42,
        rating: 5,
        reviewText: '很好',
        progress: ReviewProgress.listened,
      );

      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.uri.path, '/api/review');
      expect(request.data['work_id'], 42);
      expect(request.data['rating'], 5);
      expect(request.data['review_text'], '很好');
      expect(request.data['progress'], 'listened');
    });

    test('删除评论带上 work_id 查询参数', () async {
      await api.deleteReview(42);

      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.queryParameters['work_id'], 42);
    });

    test('标签投票使用 workID 与 status', () async {
      await api.voteWorkTag(workId: 42, tagId: 56, status: VoteStatus.upvote);

      final request = adapter.requests.single;
      expect(request.uri.path, '/api/vote/vote-work-tag');
      expect(request.data['workID'], 42);
      expect(request.data['tagID'], 56);
      expect(request.data['status'], 1);
    });
  });

  group('播放列表接口', () {
    test('我的播放列表带上 version=2', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody({
          'playlists': [
            {'id': 'uuid', 'name': '默认收藏', 'privacy': 0, 'exist': false},
          ],
          'pagination': {'currentPage': 1, 'pageSize': 12, 'totalCount': 1},
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      final page = await api.fetchMyPlaylists(workId: 42);

      expect(page.playlists.single.id, 'uuid');
      expect(adapter.requests.single.queryParameters['version'], 2);
      expect(adapter.requests.single.queryParameters['workID'], 42);
    });

    test('添加与移除作品使用站内作品 id', () async {
      await api.addWorksToPlaylist('uuid', [1, 2]);
      await api.removeWorksFromPlaylist('uuid', [1, 2]);

      expect(adapter.requests.first.data, {
        'id': 'uuid',
        'works': [1, 2],
      });
      expect(
        adapter.requests.last.uri.path,
        '/api/playlist/remove-works-from-playlist',
      );
    });

    test('删除播放列表带上 id', () async {
      await api.deletePlaylist('uuid');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/playlist/delete-playlist');
      expect(request.data, {'id': 'uuid'});
    });

    test('播放列表带上 filterBy', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody({
          'playlists': [
            {'id': 'uuid', 'name': '默认收藏', 'privacy': 0},
          ],
          'pagination': {'currentPage': 1, 'pageSize': 12, 'totalCount': 1},
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      final page = await api.fetchPlaylists(filter: PlaylistFilter.owned);

      expect(page.playlists.single.id, 'uuid');
      expect(adapter.requests.single.uri.path, '/api/playlist/get-playlists');
      expect(adapter.requests.single.queryParameters['filterBy'], 'owned');
    });

    test('播放列表里的作品解析分页', () async {
      adapter = FakeAdapter(
        (options) async => jsonBody({
          'works': [
            {'id': 1, 'title': '作品一'},
          ],
          'pagination': {'page': 2, 'pageSize': 12, 'totalCount': 30},
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      api = AsmrApi(ApiClient(tokenProvider: () => null, dio: dio));

      final page = await api.fetchPlaylistWorks(playlistId: 'uuid', page: 2);

      expect(page.works.single.id, 1);
      expect(page.pagination.page, 2);
      expect(page.pagination.totalCount, 30);
      expect(
        adapter.requests.single.uri.path,
        '/api/playlist/get-playlist-works',
      );
      expect(adapter.requests.single.queryParameters['id'], 'uuid');
      expect(adapter.requests.single.queryParameters['page'], 2);
    });
  });

  group('资源地址', () {
    test('播放地址带上线令', () {
      final dio = Dio();
      final client = ApiClient(tokenProvider: () => 'jwt token', dio: dio);
      final apiWithToken = AsmrApi(client);

      final url = apiWithToken.streamUrl('1/2');

      expect(url, contains('/api/media/stream/1/2'));
      expect(url, contains('token=jwt%20token'));
    });

    test('优先使用接口给出的 CDN 地址', () {
      final node = TrackNode.fromJson({
        'type': 'audio',
        'title': 'a.mp3',
        'hash': '1/2',
        'mediaStreamUrl': 'https://cdn/stream.mp3',
      });

      expect(api.resolveStreamUrl(node), 'https://cdn/stream.mp3');
    });

    test('没有 CDN 地址且未登录时返回 null', () {
      final node = TrackNode.fromJson({
        'type': 'audio',
        'title': 'a.mp3',
        'hash': '1/2',
      });

      expect(api.resolveStreamUrl(node), isNull);
      expect(api.resolveDownloadUrl(node), isNull);
    });
  });
}
