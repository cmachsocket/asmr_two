import '../json/json_reader.dart';
import '../models/playlist.dart';
import '../models/review.dart';
import '../models/track.dart';
import '../models/user.dart';
import '../models/work.dart';
import '../subtitle/subtitle_parser.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

/// asmr.one 的接口方法集合。
///
/// 每条方法对应官网前端实际调用的一个接口，
/// 参数名与取值范围均以服务端当前接受的形式为准。
class AsmrApi {
  AsmrApi(this.client);

  final ApiClient client;

  /// 搜索接口改用 POST 的关键字长度阈值。
  static const int searchPostThreshold = 500;

  // ---------------------------------------------------------------------------
  // 线路
  // ---------------------------------------------------------------------------

  /// 健康检查，用于探测线路可用性。
  Future<void> checkHealth() async {
    await client.get(ApiEndpoints.health);
  }

  // ---------------------------------------------------------------------------
  // 作品
  // ---------------------------------------------------------------------------

  /// 作品列表。
  ///
  /// [subtitle] 只支持 `1`（有字幕）与 `0`（无字幕），
  /// 不传则不限制。
  Future<WorksPage> fetchWorks({
    WorkOrder order = WorkOrder.createDate,
    SortDirection sort = SortDirection.desc,
    int page = 1,
    int pageSize = 20,
    int? seed,
    int? subtitle,
    List<String> withPlaylistStatus = const [],
  }) async {
    final data = await client.get(
      ApiEndpoints.works,
      query: _worksQuery(
        order: order,
        sort: sort,
        page: page,
        pageSize: pageSize,
        seed: seed,
        subtitle: subtitle,
        withPlaylistStatus: withPlaylistStatus,
      ),
    );
    return WorksPage.fromJson(Json.map(data));
  }

  /// 随机作品（「随便听听」）。
  Future<Work?> fetchRandomWork({int? seed, int? subtitle}) async {
    final page = seed ?? DateTime.now().millisecondsSinceEpoch % 200 + 1;
    final result = await fetchWorks(
      order: WorkOrder.random,
      sort: SortDirection.desc,
      page: page,
      pageSize: 1,
      seed: seed,
      subtitle: subtitle,
    );
    return result.works.isEmpty ? null : result.works.first;
  }

  /// 作品详情。
  Future<Work> fetchWork(int id) async {
    final data = await client.get(ApiEndpoints.work(id));
    final json = Json.map(data);
    if (json.isEmpty) throw ApiException('作品详情为空，可能已被删除。');
    return Work.fromJson(json);
  }

  /// 作品详情（备用路径，部分线路只挂了其中一个）。
  Future<Work> fetchWorkInfo(int id) async {
    final data = await client.get(ApiEndpoints.workInfo(id));
    final json = Json.map(data);
    if (json.isEmpty) throw ApiException('作品详情为空，可能已被删除。');
    return Work.fromJson(json);
  }

  /// 作品曲目树。
  Future<List<TrackNode>> fetchTracks(int workId) async {
    final data = await client.get(ApiEndpoints.tracks(workId));
    if (data is List) {
      return Json.list(data, TrackNode.fromJson);
    }
    return Json.list(Json.map(data)['children'], TrackNode.fromJson);
  }

  /// 关键词搜索。
  ///
  /// 筛选条件通过 [SearchKeyword] 编码进关键字串，
  /// 服务端只解析这一种筛选方式。
  Future<WorksPage> searchWorks(
    String keyword, {
    WorkOrder order = WorkOrder.createDate,
    SortDirection sort = SortDirection.desc,
    int page = 1,
    int pageSize = 20,
    int? seed,
    int? subtitle,
    bool includeTranslationWorks = true,
    List<String> withPlaylistStatus = const [],
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return WorksPage.empty;

    final query = _worksQuery(
      order: order,
      sort: sort,
      page: page,
      pageSize: pageSize,
      seed: seed,
      subtitle: subtitle,
      withPlaylistStatus: withPlaylistStatus,
      extra: {if (includeTranslationWorks) 'includeTranslationWorks': true},
    );

    final dynamic data;
    if (trimmed.length > searchPostThreshold) {
      data = await client.post(
        ApiEndpoints.search,
        body: {
          'keyword': trimmed,
          ...query,
          'localSubtitledWorks': const <int>[],
        },
      );
    } else {
      data = await client.get(
        '${ApiEndpoints.search}${Uri.encodeComponent(trimmed)}',
        query: query,
      );
    }
    return WorksPage.fromJson(Json.map(data));
  }

  // ---------------------------------------------------------------------------
  // 标签 / 社团 / 声优
  // ---------------------------------------------------------------------------

  /// 标签全集。
  Future<List<Tag>> fetchTags() async {
    final data = await client.get(ApiEndpoints.tags);
    return Json.list(data, Tag.fromJson);
  }

  /// 单个标签。
  Future<Tag> fetchTag(int id) async {
    final data = await client.get(ApiEndpoints.tag(id));
    return Tag.fromJson(Json.map(data));
  }

  /// 社团全集。
  Future<List<Circle>> fetchCircles() async {
    final data = await client.get(ApiEndpoints.circles);
    return Json.list(data, Circle.fromJson);
  }

  /// 单个社团。
  Future<Circle> fetchCircle(int id) async {
    final data = await client.get(ApiEndpoints.circle(id));
    return Circle.fromJson(Json.map(data));
  }

  /// 声优全集。
  Future<List<VoiceActor>> fetchVoiceActors() async {
    final data = await client.get(ApiEndpoints.voiceActors);
    return Json.list(data, VoiceActor.fromJson);
  }

  /// 单个声优。
  Future<VoiceActor> fetchVoiceActor(String id) async {
    final data = await client.get(ApiEndpoints.voiceActor(id));
    return VoiceActor.fromJson(Json.map(data));
  }

  // ---------------------------------------------------------------------------
  // 账号
  // ---------------------------------------------------------------------------

  /// 当前登录状态。
  Future<SessionInfo> fetchSession() async {
    final data = await client.get(ApiEndpoints.session, auth: true);
    return SessionInfo.fromJson(Json.map(data));
  }

  /// 登录。
  ///
  /// 服务端在账号不存在时会自动创建，因此这一步同时完成注册。
  Future<AuthToken> login(String name, String password) async {
    final data = await client.post(
      ApiEndpoints.session,
      body: {'name': name, 'password': password},
      auth: false,
    );
    return _authToken(Json.map(data));
  }

  /// 注册。
  Future<AuthToken> register(
    String name,
    String password, {
    String? recommenderUuid,
  }) async {
    final data = await client.post(
      ApiEndpoints.registration,
      body: {
        'name': name,
        'password': password,
        'recommenderUuid': ?recommenderUuid,
      },
      auth: false,
    );
    return _authToken(Json.map(data));
  }

  // ---------------------------------------------------------------------------
  // 评论 / 投票
  // ---------------------------------------------------------------------------

  /// 我自己的评论列表。
  Future<ReviewPage> fetchMyReviews({
    int page = 1,
    String? order,
    String? sort,
  }) async {
    final data = await client.get(
      ApiEndpoints.review,
      query: {'page': page, 'order': ?order, 'sort': ?sort},
      auth: true,
    );
    return ReviewPage.fromJson(Json.map(data));
  }

  /// 提交或更新评分与评论。
  ///
  /// [rating] 传 null 表示清除评分，
  /// [progress] 只能取 [ReviewProgress] 中定义的值。
  Future<void> submitReview({
    required int workId,
    required double? rating,
    String reviewText = '',
    ReviewProgress? progress,
  }) async {
    await client.put(
      ApiEndpoints.review,
      body: {
        'work_id': workId,
        'rating': rating,
        'review_text': reviewText,
        'progress': progress?.value ?? '',
      },
      auth: true,
    );
  }

  /// 删除我在某作品上的标记与评论。
  Future<void> deleteReview(int workId) async {
    await client.delete(
      ApiEndpoints.review,
      query: {'work_id': workId},
      auth: true,
    );
  }

  /// 给作品的标签投票。
  Future<void> voteWorkTag({
    required int workId,
    required int tagId,
    required VoteStatus status,
  }) async {
    await client.post(
      ApiEndpoints.voteWorkTag,
      body: {'workID': workId, 'tagID': tagId, 'status': status.value},
      auth: true,
    );
  }

  // ---------------------------------------------------------------------------
  // 播放列表
  // ---------------------------------------------------------------------------

  /// 我的播放列表。
  ///
  /// 传入 [workId] 时会同时返回该作品在各列表中的收藏状态。
  Future<PlaylistListPage> fetchMyPlaylists({
    int? workId,
    int page = 1,
    int pageSize = 12,
  }) async {
    final data = await client.get(
      ApiEndpoints.workPlaylistStatus,
      query: {
        'workID': workId ?? 0,
        'page': page,
        'pageSize': pageSize,
        'version': 2,
      },
      auth: true,
    );
    return PlaylistListPage.fromJson(Json.map(data));
  }

  /// 我的播放列表。
  ///
  /// [filter] 区分「我创建的」与「我点赞的」，默认给出全部可见的列表。
  Future<PlaylistListPage> fetchPlaylists({
    PlaylistFilter filter = PlaylistFilter.all,
    int page = 1,
    int pageSize = 12,
  }) async {
    final data = await client.get(
      ApiEndpoints.playlists,
      query: {'page': page, 'pageSize': pageSize, 'filterBy': filter.value},
      auth: true,
    );
    return PlaylistListPage.fromJson(Json.map(data));
  }

  /// 播放列表里的作品。
  Future<WorksPage> fetchPlaylistWorks({
    required String playlistId,
    int page = 1,
    int pageSize = 12,
  }) async {
    final data = await client.get(
      ApiEndpoints.playlistWorks,
      query: {'id': playlistId, 'page': page, 'pageSize': pageSize},
      auth: true,
    );
    return WorksPage.fromJson(Json.map(data));
  }

  /// 播放列表详情。
  Future<Playlist> fetchPlaylistDetail(String playlistId) async {
    final data = await client.get(
      ApiEndpoints.playlistMetadata,
      query: {'id': playlistId},
      auth: true,
    );
    return Playlist.fromJson(Json.map(data));
  }

  /// 默认收藏目标列表。
  Future<Playlist?> fetchDefaultPlaylist() async {
    final data = await client.get(ApiEndpoints.defaultPlaylist, auth: true);
    final json = Json.map(data);
    if (json.isEmpty) return null;
    return Playlist.fromJson(json);
  }

  /// 创建播放列表。
  Future<Playlist> createPlaylist({
    required String name,
    PlaylistPrivacy privacy = PlaylistPrivacy.private,
    String locale = 'zh-cn',
    String description = '',
    List<int> works = const [],
  }) async {
    final data = await client.post(
      ApiEndpoints.createPlaylist,
      body: {
        'name': name,
        'privacy': privacy.value,
        'locale': locale,
        'description': description,
        'works': works,
      },
      auth: true,
    );
    return Playlist.fromJson(Json.map(data));
  }

  /// 删除播放列表。
  Future<void> deletePlaylist(String playlistId) async {
    await client.post(
      ApiEndpoints.deletePlaylist,
      body: {'id': playlistId},
      auth: true,
    );
  }

  /// 向播放列表添加作品。
  ///
  /// [workIds] 使用站内作品 id，不是 DLsite 编号。
  Future<void> addWorksToPlaylist(String playlistId, List<int> workIds) async {
    await client.post(
      ApiEndpoints.addWorksToPlaylist,
      body: {'id': playlistId, 'works': workIds},
      auth: true,
    );
  }

  /// 从播放列表移除作品。
  Future<void> removeWorksFromPlaylist(
    String playlistId,
    List<int> workIds,
  ) async {
    await client.post(
      ApiEndpoints.removeWorksFromPlaylist,
      body: {'id': playlistId, 'works': workIds},
      auth: true,
    );
  }

  // ---------------------------------------------------------------------------
  // 推荐
  // ---------------------------------------------------------------------------

  /// 个性化推荐。
  Future<WorksPage> fetchRecommended({
    String? recommenderUuid,
    int page = 1,
    int pageSize = 20,
    int? subtitle,
  }) async {
    final data = await client.post(
      ApiEndpoints.recommendForUser,
      body: {
        'keyword': '',
        'recommenderUuid': ?recommenderUuid,
        'page': page,
        'pageSize': pageSize,
        'subtitle': subtitle,
        'localSubtitledWorks': const <int>[],
        'withPlaylistStatus': const <String>[],
      },
      auth: true,
    );
    return WorksPage.fromJson(Json.map(data));
  }

  /// 热门推荐。
  Future<WorksPage> fetchPopular({
    int page = 1,
    int pageSize = 20,
    int? subtitle,
  }) async {
    final data = await client.post(
      ApiEndpoints.recommendPopular,
      body: {
        'keyword': '',
        'page': page,
        'pageSize': pageSize,
        'subtitle': subtitle,
        'localSubtitledWorks': const <int>[],
        'withPlaylistStatus': const <String>[],
      },
    );
    return WorksPage.fromJson(Json.map(data));
  }

  /// 相似作品。
  Future<WorksPage> fetchSimilarWorks({
    required int workId,
    String keyword = '',
  }) async {
    final data = await client.post(
      ApiEndpoints.recommendNeighbors,
      body: {
        'keyword': keyword,
        'itemId': workId,
        'localSubtitledWorks': const <int>[],
        'withPlaylistStatus': const <String>[],
      },
    );
    return WorksPage.fromJson(Json.map(data));
  }

  /// 上报推荐系统的行为。
  Future<void> reportFeedback({
    required FeedbackType type,
    required int workId,
    String? recommenderUuid,
  }) async {
    await client.post(
      ApiEndpoints.recommendFeedback,
      body: {
        'type': type.value,
        'recommenderUuid': ?recommenderUuid,
        'itemId': workId,
      },
      auth: true,
    );
  }

  // ---------------------------------------------------------------------------
  // 资源地址
  // ---------------------------------------------------------------------------

  /// 封面图地址。
  String coverUrl(int workId, {CoverType type = CoverType.main}) {
    return '${client.baseUrl}${ApiEndpoints.cover(workId, type)}';
  }

  /// 播放地址。
  ///
  /// 付费作品需要带上登录令牌。
  String streamUrl(String hash, {bool lowQuality = false}) {
    final path = lowQuality
        ? ApiEndpoints.mediaStreamLow(hash)
        : ApiEndpoints.mediaStream(hash);
    return '${client.baseUrl}$path?token=${_encodedToken()}';
  }

  /// 下载地址。
  String downloadUrl(String hash) {
    return '${client.baseUrl}${ApiEndpoints.mediaDownload(hash)}'
        '?token=${_encodedToken()}';
  }

  /// 解析音频节点的可播放地址。
  ///
  /// 优先使用接口直接给出的 CDN 地址，
  /// 缺失（付费作品）时回退到带令牌的接口地址。
  String? resolveStreamUrl(TrackNode node, {bool preferLowQuality = false}) {
    if (preferLowQuality && (node.lowQualityStreamUrl ?? '').isNotEmpty) {
      return node.lowQualityStreamUrl;
    }
    if ((node.streamUrl ?? '').isNotEmpty) return node.streamUrl;
    final hash = node.hash;
    if (hash == null || hash.isEmpty) return null;
    if (!client.hasToken) return null;
    return streamUrl(hash, lowQuality: preferLowQuality);
  }

  /// 解析音频节点的下载地址。
  String? resolveDownloadUrl(TrackNode node) {
    if ((node.downloadUrl ?? '').isNotEmpty) return node.downloadUrl;
    final hash = node.hash;
    if (hash == null || hash.isEmpty) return null;
    if (!client.hasToken) return null;
    return downloadUrl(hash);
  }

  /// 解析字幕节点的内容地址。
  ///
  /// 字幕通常直接给出 `mediaStreamUrl`，缺失时回退到按 hash 拼出的流地址。
  String? resolveSubtitleUrl(TrackNode node) {
    if ((node.streamUrl ?? '').isNotEmpty) return node.streamUrl;
    if ((node.downloadUrl ?? '').isNotEmpty) return node.downloadUrl;
    final hash = node.hash;
    if (hash == null || hash.isEmpty) return null;
    return '${client.baseUrl}${ApiEndpoints.mediaStream(hash)}';
  }

  /// 拉取并解码字幕原文，解析交给 [SubtitleParser]。
  Future<String> fetchSubtitleText(TrackNode node) async {
    final url = resolveSubtitleUrl(node);
    if (url == null) throw ApiException('字幕内容不可用。');
    final bytes = await client.getBytes(url);
    return SubtitleParser.decodeBytes(bytes);
  }

  /// 官网上的作品页面地址。
  String webUrl(Work work) => '${ApiHosts.site}/works/${work.id}';

  // ---------------------------------------------------------------------------
  // 内部
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _worksQuery({
    required WorkOrder order,
    required SortDirection sort,
    required int page,
    required int pageSize,
    int? seed,
    int? subtitle,
    List<String> withPlaylistStatus = const [],
    Map<String, dynamic> extra = const {},
  }) {
    return {
      'order': order.value,
      'sort': sort.value,
      'page': page,
      'pageSize': pageSize,
      'seed': ?seed,
      'subtitle': ?subtitle,
      if (withPlaylistStatus.isNotEmpty)
        'withPlaylistStatus[]': withPlaylistStatus,
      ...extra,
    };
  }

  AuthToken _authToken(Map<String, dynamic> json) {
    final token = Json.stringOrNull(json['token']);
    if (token == null || token.isEmpty) {
      throw ApiException('登录失败：服务端未返回令牌。');
    }
    final user = Json.map(json['user']);
    return AuthToken(
      token: token,
      user: AccountUser.fromJson(user),
      recommenderUuid: Json.stringOrNull(user['recommenderUuid']),
    );
  }

  String _encodedToken() => Uri.encodeComponent(client.token ?? '');
}
