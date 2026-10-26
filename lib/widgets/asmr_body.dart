import "package:flutter/material.dart";
import "package:aspect_driven_grid/aspect_driven_grid.dart";

import "../core/models/work.dart";
import "asmr_card.dart";

/// 作品网格，item 为 [AsmrCard]。
///
/// 列数由容器宽高比派生：1:1 时 [baseColumns] 列，最少 [minColumns] 列。
/// 卡片高度随标签行数变化，故用瀑布流版避免内容溢出。
class ASMRBody extends StatelessWidget {
  const ASMRBody({
    super.key,
    required this.works,
    this.onTagTap,
    this.onWorkTap,
    this.onAddToPlaylist,
  });

  final List<Work> works;

  /// 点标签时的回调，为空时标签不可点。
  final void Function(String tag)? onTagTap;

  /// 点作品时的回调，参数为作品 id；为空时卡片不可点。
  final void Function(int workId)? onWorkTap;

  /// 长按或右键作品时的回调，参数为作品 id；为空时不响应。
  final void Function(int workId)? onAddToPlaylist;

  /// 1:1 容器下的列数。
  static const int baseColumns = 3;

  /// 基准宽高比，1 表示 1:1。
  static const double baseRatio = 1;

  /// 列数下限。
  static const int minColumns = 2;

  /// 列数上限。
  static const int maxColumns = 6;

  @override
  Widget build(BuildContext context) {
    return MasonryAspectDrivenGrid(
      itemCount: works.length,
      baseColumns: baseColumns,
      baseRatio: baseRatio,
      minColumns: minColumns,
      maxColumns: maxColumns,
      itemBuilder: (context, index) {
        final work = works[index];
        return AsmrCard(
          title: work.title,
          tags: [for (final tag in work.tags) tag.name],
          onTagTap: onTagTap,
          onTap: onWorkTap == null ? null : () => onWorkTap!(work.id),
          onAddToPlaylist: onAddToPlaylist == null
              ? null
              : () => onAddToPlaylist!(work.id),
          imageUrl: work.mainCoverUrl.isNotEmpty
              ? work.mainCoverUrl
              : work.thumbnailCoverUrl,
          duration: work.formatDuration(),
        );
      },
    );
  }
}
