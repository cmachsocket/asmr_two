import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:get/get.dart';

import '../state/subtitle_controller.dart';
import 'message_view.dart';

/// 字幕视图。
///
/// 渲染与交互直接使用参考项目的 `flutter_lyric`：
/// 当前行高亮、自动滚动、点击 seek 都由 [LyricView] 完成。
class SubtitleView extends GetView<SubtitleController> {
  const SubtitleView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final error = controller.error.value;
      if (error != null) {
        return MessageView(message: error, onRetry: controller.retry);
      }

      final track = controller.track.value;
      if (track == null || track.isEmpty) {
        return MessageView(
          message: '暂无字幕',
          onRetry: controller.available.value ? controller.retry : null,
        );
      }

      return LyricView(
        controller: controller.lyricController,
        preset: LyricPresets.aurora.copyWith(
          textStyle: textTheme.titleLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          activeTextStyle: textTheme.titleLarge?.copyWith(
            color: scheme.secondary,
            fontWeight: FontWeight.bold,
          ),
          translationTextStyle: textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          activeTranslationTextStyle: textTheme.titleMedium?.copyWith(
            color: scheme.primary,
          ),
          highlight: LyricHighlight.solid(scheme.primary),
          textAlign: TextAlign.center,
          contentAlignment: LyricContentAlignment.center,
        ),
        onLineTap: (details) => controller.seekTo(details.seekPosition),
      );
    });
  }
}
