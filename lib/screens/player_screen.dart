import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/default.dart';
import '../state/player_controller.dart';
import '../widgets/message_view.dart';
import '../widgets/music_progress_bar.dart';
import '../widgets/subtitle_view.dart';
import '../widgets/track_cover.dart';

/// 全屏播放页。
class PlayerScreen extends GetView<PlayerController> {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Obx(() {
          final item = controller.current.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item?.title ?? '未在播放',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item != null)
                Text(
                  item.workTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          );
        }),
      ),
      body: Obx(() {
        final item = controller.current.value;
        if (item == null) {
          return const MessageView(message: '未在播放');
        }

        return Center(
          child: controller.page.value == PlayerPage.cover
              ? AspectRatio(
                  aspectRatio: DefaultValues.squardRadio.toDouble(),
                  child: TrackCover(url: item.coverUrl),
                )
              : const SubtitleView(),
        );
      }),
      floatingActionButton: Obx(() {
        final showingCover = controller.page.value == PlayerPage.cover;
        return FloatingActionButton(
          tooltip: showingCover ? '显示字幕' : '显示封面',
          onPressed: controller.switchPage,
          child: Icon(showingCover ? Icons.subtitles : Icons.album),
        );
      }),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MusicProgressBar(),
          _Controls(player: controller),
        ],
      ),
    );
  }
}

/// 播放控制与模式开关。
class _Controls extends StatelessWidget {
  const _Controls({required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: '上一曲',
            onPressed: player.queue.isEmpty ? null : player.previous,
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton(
            tooltip: player.isPlaying.value ? '暂停' : '播放',
            onPressed: player.queue.isEmpty ? null : player.togglePlay,
            icon: Icon(player.isPlaying.value ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            tooltip: '下一曲',
            onPressed: player.queue.isEmpty ? null : player.next,
            icon: const Icon(Icons.skip_next),
          ),
          IconButton(
            tooltip: player.repeatAll.value ? '列表循环' : '不循环',
            onPressed: player.toggleRepeatAll,
            icon: Icon(
              Icons.repeat,
              color: player.repeatAll.value ? scheme.primary : null,
            ),
          ),
          IconButton(
            tooltip: '播放队列',
            onPressed: player.queue.isEmpty ? null : () => _showQueue(context),
            icon: const Icon(Icons.queue_music),
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Obx(() {
          final queue = player.queue;
          final current = player.currentIndex.value;
          return ListView.builder(
            shrinkWrap: true,
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final item = queue[index];
              return ListTile(
                selected: index == current,
                leading: Icon(
                  index == current ? Icons.graphic_eq : Icons.music_note,
                ),
                title: Text(item.title),
                subtitle: item.workTitle.isEmpty ? null : Text(item.workTitle),
                onTap: () {
                  player.jumpTo(index);
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          );
        });
      },
    );
  }
}
