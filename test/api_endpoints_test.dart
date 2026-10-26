import 'package:asmr_two/core/api/api_endpoints.dart';
import 'package:asmr_two/core/models/playlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiEndpoints 路径', () {
    test('作品相关路径按官网形式拼接', () {
      expect(ApiEndpoints.work(123), '/api/work/123');
      expect(ApiEndpoints.workInfo(123), '/api/workInfo/123');
      expect(ApiEndpoints.tracks(123), '/api/tracks/123?v=2');
    });

    test('登录与注册是同一个入口', () {
      expect(ApiEndpoints.session, '/api/auth/me');
      expect(ApiEndpoints.registration, '/api/auth/reg');
    });

    test('封面路径带上尺寸类型', () {
      expect(
        ApiEndpoints.cover(123, CoverType.main),
        '/api/cover/123.jpg?type=main',
      );
      expect(
        ApiEndpoints.cover(123, CoverType.thumbnail),
        '/api/cover/123.jpg?type=240x240',
      );
    });

    test('媒体路径区分普通与低码率', () {
      expect(ApiEndpoints.mediaStream('1/2'), '/api/media/stream/1/2');
      expect(ApiEndpoints.mediaStreamLow('1/2'), '/api/media/stream-low/1/2');
      expect(ApiEndpoints.mediaDownload('1/2'), '/api/media/download/1/2');
    });

    test('播放列表路径按官网形式拼接', () {
      expect(ApiEndpoints.playlists, '/api/playlist/get-playlists');
      expect(ApiEndpoints.playlistWorks, '/api/playlist/get-playlist-works');
      expect(
        ApiEndpoints.playlistMetadata,
        '/api/playlist/get-playlist-metadata',
      );
      expect(ApiEndpoints.deletePlaylist, '/api/playlist/delete-playlist');
    });
  });

  group('SearchKeyword 编码', () {
    test(r'包含条件编码为 $namespace:value$', () {
      const term = SearchTerm(SearchNamespace.tag, 'ASMR');
      expect(term.encode(), r'$tag:ASMR$');
    });

    test('排除条件的减号紧跟美元符号', () {
      const term = SearchTerm(SearchNamespace.tag, 'ASMR', excluded: true);
      expect(term.encode(), r'$-tag:ASMR$');
    });

    test('普通文本与筛选条件拼接在一起', () {
      final keyword = SearchKeyword(
        text: '耳ほじ',
        terms: const [
          SearchTerm(SearchNamespace.tag, 'ASMR'),
          SearchTerm(SearchNamespace.age, 'general'),
        ],
      );

      expect(keyword.build(), r'耳ほじ $tag:ASMR$ $age:general$');
    });

    test('带空格的文本会被引号包裹', () {
      final keyword = SearchKeyword(text: 'sleep sounds');
      expect(keyword.build(), '"sleep sounds"');
    });

    test('空值条件会被忽略', () {
      final keyword = SearchKeyword(
        terms: const [SearchTerm(SearchNamespace.tag, '  ')],
      );
      expect(keyword.build(), isEmpty);
    });
  });

  group('枚举取值', () {
    test('标签投票状态与服务端一致', () {
      expect(VoteStatus.noVote.value, 0);
      expect(VoteStatus.upvote.value, 1);
      expect(VoteStatus.downvote.value, 2);
    });

    test('播放列表可见性使用整数编码', () {
      expect(PlaylistPrivacy.private.value, 0);
      expect(PlaylistPrivacy.known.value, 1);
      expect(PlaylistPrivacy.public.value, 2);
    });

    test('播放列表筛选条件与官网一致', () {
      expect(PlaylistFilter.all.value, 'all');
      expect(PlaylistFilter.owned.value, 'owned');
      expect(PlaylistFilter.liked.value, 'liked');
    });
  });
}
