import '../json/json_reader.dart';

/// 分页元信息。
class Pagination {
  const Pagination({
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final int page;
  final int pageSize;
  final int totalCount;

  /// 是否还有下一页。
  bool get hasMore => page * pageSize < totalCount;

  /// 总页数。
  int get maxPage => pageSize <= 0 ? 1 : (totalCount / pageSize).ceil();

  /// 解析分页信息。
  ///
  /// 接口把分页放在 `pagination` 子对象里，部分旧接口直接放在顶层，
  /// 页码字段也有 `currentPage` 与 `page` 两种写法，两种形态都兼容。
  factory Pagination.fromJson(
    Map<String, dynamic> json, {
    required int itemCount,
  }) {
    final nested = Json.map(json['pagination']);
    return Pagination(
      page: Json.integer(
        nested['currentPage'] ?? nested['page'] ?? json['page'],
        fallback: 1,
      ),
      pageSize: Json.integer(
        nested['pageSize'] ?? json['pageSize'],
        fallback: itemCount,
      ),
      totalCount: Json.integer(
        nested['totalCount'] ?? json['totalCount'],
        fallback: itemCount,
      ),
    );
  }

  static const empty = Pagination(page: 1, pageSize: 20, totalCount: 0);
}
