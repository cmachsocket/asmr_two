import 'package:asmr_two/core/models/pagination.dart';
import 'package:asmr_two/core/models/playlist.dart';
import 'package:asmr_two/core/models/review.dart';
import 'package:asmr_two/core/models/track.dart';
import 'package:asmr_two/core/models/user.dart';
import 'package:asmr_two/core/models/work.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Work 解析', () {
    final json = <String, dynamic>{
      'id': 1712623,
      'title': 'テスト作品',
      'circle_id': 1036219,
      'name': 'サークル',
      'nsfw': true,
      'release': '2026-09-23',
      'dl_count': 334,
      'price': 990,
      'review_count': 4,
      'rate_count': 9,
      'rate_average_2dp': 5,
      'rate_count_detail': [
        {'review_point': 5, 'count': 9, 'ratio': 100},
      ],
      'rank': [
        {
          'term': 'day',
          'category': 'voice',
          'rank': 29,
          'rank_date': '2026-09-23',
        },
      ],
      'has_subtitle': false,
      'create_date': '2026-10-23',
      'vas': [
        {'id': 'uuid-1', 'name': '葉月'},
      ],
      'tags': [
        {
          'id': 56,
          'name': '治愈',
          'i18n': {
            'ja-jp': {'name': '癒し'},
            'zh-cn': {'name': '治愈'},
          },
          'count': 734,
        },
      ],
      'language_editions': [
        {
          'lang': 'CHI_HANS',
          'label': '簡体中文',
          'workno': 'RJ01638153',
          'edition_id': 50856,
          'edition_type': 'language',
          'display_order': 5,
        },
      ],
      'age_category_string': 'adult',
      'duration': 3481,
      'source_type': 'DLSITE',
      'source_id': 'RJ01712623',
      'source_url':
          'https://www.dlsite.com/maniax/work/=/product_id/RJ01712623.html',
      'userRating': 4.5,
      'review_text': '很好',
      'progress': 'listened',
      'mainCoverUrl': 'https://api.asmr.one/api/cover/1712623.jpg?type=main',
      'circle': {
        'id': 1036219,
        'name': 'サークル',
        'source_id': 'RG01036219',
        'source_type': 'DLSITE',
      },
    };

    test('基础字段按服务端字段名读取', () {
      final work = Work.fromJson(json);

      expect(work.id, 1712623);
      expect(work.circleId, 1036219);
      expect(work.circleName, 'サークル');
      expect(work.dlCount, 334);
      expect(work.price, 990);
      expect(work.rateAverage, 5);
      expect(work.ageCategory, 'adult');
      expect(work.duration, 3481);
      expect(work.sourceId, 'RJ01712623');
      expect(work.isFree, isFalse);
    });

    test('评分分布与榜单被解析成对象列表', () {
      final work = Work.fromJson(json);

      expect(work.rateCountDetail.single.point, 5);
      expect(work.rateCountDetail.single.ratio, 100);
      expect(work.rank.single.term, 'day');
      expect(work.rank.single.rank, 29);
    });

    test('标签能按语言取到译名', () {
      final work = Work.fromJson(json);

      expect(work.tags.single.label('zh-cn'), '治愈');
      expect(work.tags.single.label('ja-jp'), '癒し');
      expect(work.tags.single.label('en-us'), '治愈');
      expect(work.tags.single.count, 734);
    });

    test('声优与社团被解析', () {
      final work = Work.fromJson(json);

      expect(work.vas.single.name, '葉月');
      expect(work.circle?.sourceId, 'RG01036219');
    });

    test('能识别出包含中文版本', () {
      expect(Work.fromJson(json).hasChineseEdition, isTrue);
    });

    test('缺失字段不会导致解析失败', () {
      final work = Work.fromJson({'id': '7', 'rate_average_2dp': '4.69'});

      expect(work.id, 7);
      expect(work.rateAverage, 4.69);
      expect(work.tags, isEmpty);
      expect(work.circle, isNull);
    });
  });

  group('WorksPage 分页解析', () {
    test('分页信息位于 pagination 子对象时能正确读取', () {
      final page = WorksPage.fromJson({
        'works': [
          {'id': 1},
          {'id': 2},
        ],
        'pagination': {'currentPage': 3, 'pageSize': 2, 'totalCount': 62940},
      });

      expect(page.works.length, 2);
      expect(page.pagination.page, 3);
      expect(page.pagination.pageSize, 2);
      expect(page.pagination.totalCount, 62940);
      expect(page.pagination.hasMore, isTrue);
      expect(page.pagination.maxPage, 31470);
    });

    test('分页信息位于顶层时同样兼容', () {
      final page = WorksPage.fromJson({
        'works': [
          {'id': 1},
        ],
        'page': 2,
        'pageSize': 20,
        'totalCount': 100,
      });

      expect(page.pagination.page, 2);
      expect(page.pagination.totalCount, 100);
    });
  });

  group('TrackNode 解析', () {
    test('目录节点会递归展开音频', () {
      final nodes = TrackNode.fromJson({
        'type': 'folder',
        'title': 'mp3',
        'children': [
          {
            'type': 'audio',
            'title': '01. track.mp3',
            'hash': '1712623/1963358',
            'duration': 213.912,
            'size': 8557440,
            'mediaStreamUrl': 'https://cdn/stream.mp3',
            'mediaDownloadUrl': 'https://cdn/download.mp3',
            'streamLowQualityUrl': '',
            'work': {'id': 1712623, 'source_id': 'RJ01712623'},
            'workTitle': '作品',
          },
        ],
      }).flatten();

      final audio = nodes.single;
      expect(audio.title, '01. track.mp3');
      expect(audio.hash, '1712623/1963358');
      expect(audio.duration, closeTo(213.912, 0.001));
      expect(audio.node.workId, 1712623);
      expect(audio.node.sourceId, 'RJ01712623');
      expect(audio.folderLabel, 'mp3');
      expect(audio.node.isPlayable, isTrue);
    });

    test('图片与文本节点不算可播放', () {
      final node = TrackNode.fromJson({'type': 'image', 'title': 'cover.jpg'});

      expect(node.isPlayable, isFalse);
      expect(node.isAudio, isFalse);
    });
  });

  group('Playlist 解析', () {
    test('可见性按整数编码解析', () {
      expect(PlaylistPrivacy.fromValue(0), PlaylistPrivacy.private);
      expect(PlaylistPrivacy.fromValue(1), PlaylistPrivacy.known);
      expect(PlaylistPrivacy.fromValue(2), PlaylistPrivacy.public);
    });

    test('系统内置列表通过名称前缀识别', () {
      final playlist = Playlist.fromJson({
        'id': 'uuid',
        'name': '__SYS_PLAYLIST_MARKED',
        'privacy': 0,
        'works_count': 3,
      });

      expect(playlist.isSystem, isTrue);
      expect(playlist.privacy, PlaylistPrivacy.private);
      expect(playlist.worksCount, 3);
    });
  });

  group('ReviewProgress 解析', () {
    test('只接受服务端定义的进度值', () {
      expect(ReviewProgress.fromValue('listened'), ReviewProgress.listened);
      expect(ReviewProgress.fromValue('postponed'), ReviewProgress.postponed);
      expect(ReviewProgress.fromValue('unknown'), isNull);
    });
  });

  group('用户信息解析', () {
    test('未登录时返回空用户', () {
      final session = SessionInfo.fromJson({
        'user': {'loggedIn': false},
        'auth': true,
        'reg': false,
      });

      expect(session.user.loggedIn, isFalse);
      expect(session.user.displayName, '未登录');
      expect(session.authEnabled, isTrue);
      expect(session.registrationEnabled, isFalse);
    });

    test('登录后能读到推荐系统标识', () {
      final session = SessionInfo.fromJson({
        'user': {
          'loggedIn': true,
          'name': 'user',
          'group': 'user',
          'recommenderUuid': 'uuid-1',
        },
      });

      expect(session.user.name, 'user');
      expect(session.user.recommenderUuid, 'uuid-1');
    });
  });

  group('Pagination', () {
    test('最后一页没有更多内容', () {
      const pagination = Pagination(page: 2, pageSize: 20, totalCount: 40);
      expect(pagination.hasMore, isFalse);
    });
  });
}
