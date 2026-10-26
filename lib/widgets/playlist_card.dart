import 'package:flutter/material.dart';

import '../core/default.dart';
import '../core/models/playlist.dart';

/// 播放列表卡片：封面、名称与归属信息。
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({super.key, required this.playlist, this.onTap});

  final Playlist playlist;

  /// 点卡片时的回调，为空时卡片不可点。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: DefaultValues.cardImageAspectRatio,
              child: _cover(colorScheme),
            ),
            ListTile(
              title: Text(
                playlist.displayName,
                style: textTheme.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _subtitle(),
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 封面，地址缺失或加载失败时用主题色占位。
  Widget _cover(ColorScheme colorScheme) {
    final placeholder = ColoredBox(color: colorScheme.surfaceContainerHighest);
    if (playlist.mainCoverUrl.isEmpty) return placeholder;
    return Image.network(
      playlist.mainCoverUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  /// 一行归属信息，例如 `12 个作品 · 公开`。
  String _subtitle() {
    return [
      if (playlist.worksCount > 0) '${playlist.worksCount} 个作品',
      playlist.privacy.label,
    ].join(' · ');
  }
}
