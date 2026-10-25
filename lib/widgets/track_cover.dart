import 'package:flutter/material.dart';

/// 曲目封面，地址为空或加载失败时用主题色占位。
class TrackCover extends StatelessWidget {
  const TrackCover({
    super.key,
    required this.url,
    this.icon = Icons.music_note,
  });

  /// 封面地址。
  final String url;

  /// 占位图标。
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Icon(icon, color: scheme.onSurfaceVariant)),
    );

    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
