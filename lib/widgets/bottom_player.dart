import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/default.dart';
import '../screens/player_screen.dart';
import '../state/player_controller.dart';
import 'music_progress_bar.dart';
import 'track_cover.dart';

/// 底部迷你播放器，点空白区域打开全屏播放页。
class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final item = player.current.value;
      final subtitle = item == null || item.workTitle.isEmpty
          ? '选择作品开始播放'
          : item.workTitle;
      return Material(
        color: scheme.surfaceContainerHighest,
        child: InkWell(
          onTap: item == null
              ? null
              : () => Get.to<void>(() => const PlayerScreen()),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AspectRatio(
                      aspectRatio: DefaultValues.squardRadio.toDouble(),
                      child: TrackCover(
                        url: item?.coverUrl ?? '',
                        icon: Icons.headphones,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        dense: true,
                        title: Text(
                          item?.title ?? '未在播放',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '上一曲',
                      onPressed: player.queue.isEmpty ? null : player.previous,
                      icon: const Icon(Icons.skip_previous),
                    ),
                    IconButton(
                      tooltip: player.isPlaying.value ? '暂停' : '播放',
                      onPressed: player.queue.isEmpty
                          ? null
                          : player.togglePlay,
                      icon: Icon(
                        player.isPlaying.value ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    IconButton(
                      tooltip: '下一曲',
                      onPressed: player.queue.isEmpty ? null : player.next,
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
              ),
              const MusicProgressBar(
                timeLabelLocation: TimeLabelLocation.sides,
              ),
            ],
          ),
        ),
      );
    });
  }
}
