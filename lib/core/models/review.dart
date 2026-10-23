import '../json/json_reader.dart';
import 'pagination.dart';
import 'work.dart';

/// 收听进度标记，写入评论接口的 `progress` 字段。
enum ReviewProgress {
  /// 已标记。
  marked('marked'),

  /// 收听中。
  listening('listening'),

  /// 已听完。
  listened('listened'),

  /// 重播。
  replay('replay'),

  /// 稍后再听。
  postponed('postponed');

  const ReviewProgress(this.value);

  final String value;

  /// 从接口返回值解析，未知值返回 null。
  static ReviewProgress? fromValue(String? value) {
    for (final progress in ReviewProgress.values) {
      if (progress.value == value) return progress;
    }
    return null;
  }
}

/// 我自己的评论列表。
///
/// 接口返回的是带有本人评分与评论内容的作品条目，
/// 因此这里直接持有 [Work]，评分与评论从作品上读取。
class ReviewPage {
  const ReviewPage({required this.works, required this.pagination});

  final List<Work> works;
  final Pagination pagination;

  factory ReviewPage.fromJson(Map<String, dynamic> json) {
    final works = Json.list(json['works'], Work.fromJson);
    return ReviewPage(
      works: works,
      pagination: Pagination.fromJson(json, itemCount: works.length),
    );
  }

  static const empty = ReviewPage(works: [], pagination: Pagination.empty);
}
