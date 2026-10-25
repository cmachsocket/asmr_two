import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/player_controller.dart';

/// 播放进度条。
///
/// 外观与交互直接使用参考项目的 `audio_video_progress_bar`，
/// 拖动结束后由 [PlayerController.seek] 真正跳转。
class MusicProgressBar extends StatelessWidget {
  const MusicProgressBar({
    super.key,
    this.timeLabelLocation = TimeLabelLocation.below,
  });

  /// 时间标签位置。
  final TimeLabelLocation timeLabelLocation;

  static const double baseBarAlpha = 0.3;
  static const double bufferedBarAlpha = 0.3;
  static const double thumbGlowColorAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(
      () => ProgressBar(
        timeLabelLocation: timeLabelLocation,
        progress: controller.position.value,
        buffered: controller.buffered.value,
        total: controller.duration.value,
        onSeek: controller.seek,
        progressBarColor: scheme.primary,
        baseBarColor: scheme.onSurface.withValues(alpha: baseBarAlpha),
        bufferedBarColor: scheme.tertiary.withValues(alpha: bufferedBarAlpha),
        thumbColor: scheme.secondary,
        thumbGlowColor: scheme.secondary.withValues(alpha: thumbGlowColorAlpha),
        timeLabelTextStyle: textTheme.bodySmall,
      ),
    );
  }
}
