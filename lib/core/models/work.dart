import '../json/json_reader.dart';
import 'pagination.dart';

/// 作品列表可用的排序字段，对应接口的 `order` 参数。
enum WorkOrder {
  createDate('create_date'),
  release('release'),
  dlCount('dl_count'),
  rateAverage('rate_average_2dp'),
  reviewCount('review_count'),
  price('price'),
  id('id'),
  random('random'),
  betterRandom('betterRandom');

  const WorkOrder(this.value);

  final String value;
}

/// 排序方向，对应接口的 `sort` 参数。
enum SortDirection {
  desc('desc'),
  asc('asc');

  const SortDirection(this.value);

  final String value;
}

/// 标签。
class Tag {
  const Tag({
    required this.id,
    required this.name,
    this.i18n = const {},
    this.count = 0,
    this.voteRank,
    this.voteStatus,
    this.upvote = 0,
    this.downvote = 0,
  });

  final int id;
  final String name;

  /// 语言代码到译名的映射，例如 `{'ja-jp': '癒し'}`。
  final Map<String, String> i18n;

  /// 关联作品数量。
  final int count;

  /// 标签投票的当前名次。
  final int? voteRank;

  /// 当前用户对该标签的投票状态。
  final int? voteStatus;

  final int upvote;
  final int downvote;

  /// 取指定语言的译名，缺失时回退到原名。
  String label(String locale) => i18n[locale] ?? name;

  factory Tag.fromJson(Map<String, dynamic> json) {
    final rawI18n = Json.map(json['i18n']);
    return Tag(
      id: Json.integer(json['id']),
      name: Json.string(json['name']),
      i18n: rawI18n.map(
        (locale, entry) =>
            MapEntry(locale, Json.stringOrNull(Json.map(entry)['name']) ?? ''),
      ),
      count: Json.integer(json['count']),
      voteRank: Json.integerOrNull(json['voteRank']),
      voteStatus: Json.integerOrNull(json['voteStatus']),
      upvote: Json.integer(json['upvote']),
      downvote: Json.integer(json['downvote']),
    );
  }
}

/// 社团（サークル）。
class Circle {
  const Circle({
    required this.id,
    required this.name,
    this.sourceId,
    this.sourceType,
    this.count = 0,
  });

  final int id;
  final String name;
  final String? sourceId;
  final String? sourceType;

  /// 关联作品数量，仅列表接口提供。
  final int count;

  factory Circle.fromJson(Map<String, dynamic> json) => Circle(
    id: Json.integer(json['id']),
    name: Json.string(json['name']),
    sourceId: Json.stringOrNull(json['source_id']),
    sourceType: Json.stringOrNull(json['source_type']),
    count: Json.integer(json['count']),
  );
}

/// 声优 / 演绎者。
class VoiceActor {
  const VoiceActor({required this.id, required this.name});

  final String id;
  final String name;

  factory VoiceActor.fromJson(Map<String, dynamic> json) =>
      VoiceActor(id: Json.string(json['id']), name: Json.string(json['name']));
}

/// 同一作品的其它语言版本。
class LanguageEdition {
  const LanguageEdition({
    required this.lang,
    required this.label,
    required this.workNo,
    this.editionId,
    this.editionType,
    this.displayOrder,
  });

  /// 语言代码，例如 `JPN` / `CHI_HANS`。
  final String lang;

  /// 语言显示名，例如 `日本語`。
  final String label;

  /// 对应作品的 DLsite 编号。
  final String workNo;

  final int? editionId;
  final String? editionType;
  final int? displayOrder;

  factory LanguageEdition.fromJson(Map<String, dynamic> json) =>
      LanguageEdition(
        lang: Json.string(json['lang']),
        label: Json.string(json['label']),
        workNo: Json.string(json['workno']),
        editionId: Json.integerOrNull(json['edition_id']),
        editionType: Json.stringOrNull(json['edition_type']),
        displayOrder: Json.integerOrNull(json['display_order']),
      );
}

/// 榜单条目（日榜 / 周榜 / 月榜）。
class RankEntry {
  const RankEntry({
    required this.term,
    required this.category,
    required this.rank,
    this.rankDate,
  });

  /// 榜单周期，例如 `day` / `week` / `month`。
  final String term;

  /// 榜单分类，例如 `voice`。
  final String category;

  final int rank;
  final String? rankDate;

  factory RankEntry.fromJson(Map<String, dynamic> json) => RankEntry(
    term: Json.string(json['term']),
    category: Json.string(json['category']),
    rank: Json.integer(json['rank']),
    rankDate: Json.stringOrNull(json['rank_date']),
  );
}

/// 评分分布中的单档（1~5 星）。
class RateBucket {
  const RateBucket({
    required this.point,
    required this.count,
    required this.ratio,
  });

  /// 星级分档，对应 `review_point`。
  final int point;

  final int count;

  /// 该档占比（百分比）。
  final double ratio;

  factory RateBucket.fromJson(Map<String, dynamic> json) => RateBucket(
    point: Json.integer(json['review_point']),
    count: Json.integer(json['count']),
    ratio: Json.number(json['ratio']),
  );
}

/// 作品。列表与详情接口返回结构一致，详情额外包含 `tags` / `vas` 等字段。
class Work {
  const Work({
    required this.id,
    required this.title,
    required this.circleId,
    required this.circleName,
    required this.nsfw,
    required this.release,
    required this.dlCount,
    required this.price,
    required this.reviewCount,
    required this.rateCount,
    required this.rateAverage,
    this.rateCountDetail = const [],
    this.rank = const [],
    this.hasSubtitle = false,
    this.createDate = '',
    this.vas = const [],
    this.tags = const [],
    this.languageEditions = const [],
    this.ageCategory = '',
    this.duration,
    this.sourceType,
    this.sourceId,
    this.sourceUrl,
    this.circle,
    this.mainCoverUrl = '',
    this.samCoverUrl = '',
    this.thumbnailCoverUrl = '',
    this.userRating,
    this.reviewText,
    this.progress,
  });

  final int id;
  final String title;
  final int circleId;

  /// 社团名，接口字段名为 `name`。
  final String circleName;

  /// 是否为成人向内容。
  final bool nsfw;

  /// 发售日期。
  final String release;

  /// 销量。
  final int dlCount;

  /// 售价（日元），0 表示免费。
  final int price;

  final int reviewCount;
  final int rateCount;

  /// 平均评分（0~5）。
  final double rateAverage;

  final List<RateBucket> rateCountDetail;
  final List<RankEntry> rank;
  final bool hasSubtitle;
  final String createDate;
  final List<VoiceActor> vas;
  final List<Tag> tags;
  final List<LanguageEdition> languageEditions;

  /// 分级，例如 `adult` / `r15` / `general`。
  final String ageCategory;

  /// 总时长（秒）。
  final int? duration;

  /// 来源站点，例如 `DLSITE`。
  final String? sourceType;

  /// 来源编号，例如 `RJ01712623`。
  final String? sourceId;

  final String? sourceUrl;
  final Circle? circle;
  final String mainCoverUrl;
  final String samCoverUrl;
  final String thumbnailCoverUrl;

  /// 当前登录用户的评分。
  final double? userRating;

  /// 当前登录用户写的评论。
  final String? reviewText;

  /// 当前登录用户标记的收听进度。
  final String? progress;

  /// 是否免费。
  bool get isFree => price == 0;

  /// 是否包含中文版本。
  bool get hasChineseEdition => languageEditions.any(
    (edition) => edition.lang.toUpperCase().startsWith('CHI'),
  );

  factory Work.fromJson(Map<String, dynamic> json) {
    final circleJson = json['circle'];
    return Work(
      id: Json.integer(json['id']),
      title: Json.string(json['title']),
      circleId: Json.integer(json['circle_id']),
      circleName: Json.string(json['name']),
      nsfw: Json.boolean(json['nsfw']),
      release: Json.string(json['release']),
      dlCount: Json.integer(json['dl_count']),
      price: Json.integer(json['price']),
      reviewCount: Json.integer(json['review_count']),
      rateCount: Json.integer(json['rate_count']),
      rateAverage: Json.number(json['rate_average_2dp']),
      rateCountDetail: Json.list(
        json['rate_count_detail'],
        RateBucket.fromJson,
      ),
      rank: Json.list(json['rank'], RankEntry.fromJson),
      hasSubtitle: Json.boolean(json['has_subtitle']),
      createDate: Json.string(json['create_date']),
      vas: Json.list(json['vas'], VoiceActor.fromJson),
      tags: Json.list(json['tags'], Tag.fromJson),
      languageEditions: Json.list(
        json['language_editions'],
        LanguageEdition.fromJson,
      ),
      ageCategory: Json.string(json['age_category_string']),
      duration: Json.integerOrNull(json['duration']),
      sourceType: Json.stringOrNull(json['source_type']),
      sourceId: Json.stringOrNull(json['source_id']),
      sourceUrl: Json.stringOrNull(json['source_url']),
      circle: circleJson == null ? null : Circle.fromJson(Json.map(circleJson)),
      mainCoverUrl: Json.string(json['mainCoverUrl']),
      samCoverUrl: Json.string(json['samCoverUrl']),
      thumbnailCoverUrl: Json.string(json['thumbnailCoverUrl']),
      userRating: Json.numberOrNull(json['userRating']),
      reviewText: Json.stringOrNull(json['review_text']),
      progress: Json.stringOrNull(json['progress']),
    );
  }
}

/// 作品列表的分页结果。
class WorksPage {
  const WorksPage({required this.works, required this.pagination});

  final List<Work> works;
  final Pagination pagination;

  factory WorksPage.fromJson(Map<String, dynamic> json) {
    final works = Json.list(json['works'], Work.fromJson);
    return WorksPage(
      works: works,
      pagination: Pagination.fromJson(json, itemCount: works.length),
    );
  }

  static const empty = WorksPage(works: [], pagination: Pagination.empty);
}
