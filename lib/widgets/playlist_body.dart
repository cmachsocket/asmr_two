import 'package:flutter/material.dart';
import 'package:aspect_driven_grid/aspect_driven_grid.dart';

import '../core/models/playlist.dart';
import 'playlist_card.dart';

/// 播放列表网格，item 为 [PlaylistCard]。
///
/// 列数由容器宽高比派生：1:1 时 [baseColumns] 列，最少 [minColumns] 列。
/// 卡片高度随标题行数变化，故用瀑布流版避免内容溢出。
class PlaylistBody extends StatelessWidget {
  const PlaylistBody({super.key, required this.playlists, this.onTap});

  /// 要展示的全部播放列表。
  final List<Playlist> playlists;

  /// 点卡片时的回调，参数为被点的播放列表；为空时卡片不可点。
  final void Function(Playlist playlist)? onTap;

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
      itemCount: playlists.length,
      baseColumns: baseColumns,
      baseRatio: baseRatio,
      minColumns: minColumns,
      maxColumns: maxColumns,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return PlaylistCard(
          playlist: playlist,
          onTap: onTap == null ? null : () => onTap!(playlist),
        );
      },
    );
  }
}
