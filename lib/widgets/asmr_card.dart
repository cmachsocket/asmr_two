import "package:flutter/material.dart";

import "../core/default.dart";

class AsmrCard extends StatelessWidget {
  const AsmrCard({
    super.key,
    required this.title,
    required this.tags,
    required this.imageUrl,
    required this.duration,
    this.onTagTap,
    this.onTap,
    this.onAddToPlaylist,
  });

  final String title;
  final List<String> tags;
  final String imageUrl;
  final String duration;

  /// 点标签时的回调，为空时标签不可点。
  final void Function(String tag)? onTagTap;

  /// 点卡片时的回调，为空时卡片不可点。
  final VoidCallback? onTap;

  /// 长按或右键卡片时的回调，为空时不响应。
  final VoidCallback? onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onAddToPlaylist,
        onSecondaryTap: onAddToPlaylist,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: DefaultValues.cardImageAspectRatio,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    ColoredBox(color: colorScheme.surfaceContainerHighest),
              ),
            ),
            ListTile(
              title: Text(
                title,
                style: textTheme.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(duration, style: textTheme.bodySmall),
                  if (tags.isNotEmpty)
                    Wrap(
                      children: [
                        for (final tag in tags)
                          onTagTap == null
                              ? Chip(
                                  label: Text(tag, style: textTheme.bodySmall),
                                  shape: const StadiumBorder(),
                                )
                              : ActionChip(
                                  label: Text(tag, style: textTheme.bodySmall),
                                  shape: const StadiumBorder(),
                                  onPressed: () => onTagTap!(tag),
                                ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
