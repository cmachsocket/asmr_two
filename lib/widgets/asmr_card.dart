import "package:flutter/material.dart";

import "../core/default.dart";

class AsmrCard extends StatelessWidget {
  const AsmrCard({
    super.key,
    required this.title,
    required this.tags,
    required this.imageUrl,
    required this.duration,
  });

  final String title;
  final List<String> tags;
  final String imageUrl;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
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
            title: Text(title, style: textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(duration, style: textTheme.bodySmall),
                if (tags.isNotEmpty)
                  Wrap(
                    children: [for (final tag in tags) Chip(label: Text(tag))],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
