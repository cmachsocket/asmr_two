/// asmr.one 的接口路径与请求枚举。
///
/// 路径与参数均以官网前端当前使用的形式为准，
/// 服务端会因版本更新调整，这里保持与官网一致。
class ApiEndpoints {
  const ApiEndpoints._();

  /// 健康检查，用于线路探测。
  static const String health = '/api/health';

  /// 作品列表。
  static const String works = '/api/works';

  /// 作品详情。
  static String work(int id) => '/api/work/$id';

  /// 作品详情的备用路径。
  static String workInfo(int id) => '/api/workInfo/$id';

  /// 作品曲目树。
  static String tracks(int workId) => '/api/tracks/$workId?v=2';

  /// 搜索（POST 形态，超长关键字时使用）。
  static const String search = '/api/search/';

  /// 标签全集。
  static const String tags = '/api/tags/';

  /// 单个标签。
  static String tag(int id) => '/api/tags/$id';

  /// 社团全集。
  static const String circles = '/api/circles/';

  /// 单个社团。
  static String circle(int id) => '/api/circles/$id';

  /// 声优全集。
  static const String voiceActors = '/api/vas/';

  /// 单个声优。
  static String voiceActor(String id) => '/api/vas/$id';

  /// 登录 / 注册（同一入口，未注册的账号会被自动创建）。
  static const String session = '/api/auth/me';

  /// 注册。
  static const String registration = '/api/auth/reg';

  /// 评论。
  static const String review = '/api/review';

  /// 标签投票。
  static const String voteWorkTag = '/api/vote/vote-work-tag';

  /// 我的播放列表（含作品的收藏状态）。
  static const String workPlaylistStatus =
      '/api/playlist/get-work-exist-status-in-my-playlists';

  /// 我的播放列表，可按归属筛选。
  static const String playlists = '/api/playlist/get-playlists';

  /// 播放列表内的作品。
  static const String playlistWorks = '/api/playlist/get-playlist-works';

  /// 播放列表详情。
  static const String playlistMetadata = '/api/playlist/get-playlist-metadata';

  /// 默认收藏目标列表。
  static const String defaultPlaylist =
      '/api/playlist/get-default-mark-target-playlist';

  /// 创建播放列表。
  static const String createPlaylist = '/api/playlist/create-playlist';

  /// 删除播放列表。
  static const String deletePlaylist = '/api/playlist/delete-playlist';

  /// 向播放列表添加作品。
  static const String addWorksToPlaylist =
      '/api/playlist/add-works-to-playlist';

  /// 从播放列表移除作品。
  static const String removeWorksFromPlaylist =
      '/api/playlist/remove-works-from-playlist';

  /// 个性化推荐。
  static const String recommendForUser = '/api/recommender/recommend-for-user';

  /// 热门推荐。
  static const String recommendPopular = '/api/recommender/popular';

  /// 相似作品。
  static const String recommendNeighbors = '/api/recommender/item-neighbors';

  /// 推荐系统行为上报。
  static const String recommendFeedback = '/api/recommender/feedback';

  /// 封面图片。
  static String cover(int workId, CoverType type) =>
      '/api/cover/$workId.jpg?type=${type.value}';

  /// 播放地址。
  static String mediaStream(String hash) => '/api/media/stream/$hash';

  /// 低码率播放地址。
  static String mediaStreamLow(String hash) => '/api/media/stream-low/$hash';

  /// 下载地址。
  static String mediaDownload(String hash) => '/api/media/download/$hash';
}

/// 封面尺寸。
enum CoverType {
  main('main'),
  sam('sam'),
  thumbnail('240x240');

  const CoverType(this.value);

  final String value;
}

/// 标签投票状态。
enum VoteStatus {
  /// 未投票。
  noVote(0),

  /// 赞成。
  upvote(1),

  /// 反对。
  downvote(2);

  const VoteStatus(this.value);

  final int value;
}

/// 推荐系统的行为上报类型。
enum FeedbackType {
  startListen('start-listen'),
  listenFiveMinutes('listen-5mins'),
  listenFifteenMinutes('listen-15mins'),
  listenThirtyMinutes('listen-30mins'),
  listenSixtyMinutes('listen-60mins'),
  listenThirtyPercent('listen-30percent'),
  listenSixtyPercent('listen-60percent'),
  listenNinetyPercent('listen-90percent');

  const FeedbackType(this.value);

  final String value;
}

/// 搜索关键字里可用的筛选命名空间。
enum SearchNamespace {
  tag('tag', 't'),
  circle('circle', 'c'),
  voiceActor('va', 'v'),
  age('age'),
  language('lang'),
  rate('rate'),
  price('price'),
  sales('sell'),
  duration('duration', 'd');

  const SearchNamespace(this.value, [this.alias]);

  final String value;

  /// 简写形式。
  final String? alias;
}

/// 单条搜索筛选条件。
///
/// 接口不接收独立的筛选参数，官网前端是把筛选条件编码成
/// 「搜索关键字」交给搜索接口解析，编码规则为：
/// 包含 `$tag:ASMR$`，排除 `$-tag:ASMR$`。
class SearchTerm {
  const SearchTerm(this.namespace, this.value, {this.excluded = false});

  final SearchNamespace namespace;

  /// 筛选值，按名称而非 id 匹配。
  final String value;

  /// 是否为排除条件。
  final bool excluded;

  /// 编码成接口可识别的片段。
  String encode() => '\$${excluded ? '-' : ''}${namespace.value}:$value\$';
}

/// 搜索关键字构造器。
class SearchKeyword {
  SearchKeyword({this.text = '', List<SearchTerm> terms = const []})
    : terms = List.unmodifiable(terms);

  /// 普通文本关键字。
  final String text;

  /// 筛选条件。
  final List<SearchTerm> terms;

  /// 拼出最终提交给搜索接口的关键字。
  ///
  /// 形如 `耳ほじ $tag:ASMR$ $-tag:治愈$`。
  String build() {
    final parts = <String>[];
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      parts.add(trimmed.contains(' ') ? '"$trimmed"' : trimmed);
    }
    for (final term in terms) {
      if (term.value.trim().isEmpty) continue;
      parts.add(term.encode());
    }
    return parts.join(' ');
  }

  bool get isEmpty => text.trim().isEmpty && terms.isEmpty;
}
