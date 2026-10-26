import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../core/audio/playback_item.dart';
import '../core/audio/track_plan.dart';
import '../core/default.dart';
import '../core/models/work.dart';
import '../state/work_detail_controller.dart';
import '../widgets/message_view.dart';
import 'search_screen.dart';

/// 作品详情页：封面、作品信息与曲目树。
///
/// 作品信息与曲目由 [WorkDetailController] 拉取，曲目行的播放命令也转给它。
class DetailScreen extends GetView<WorkDetailController> {
  const DetailScreen({super.key, required this.workId});

  /// 作品 id。
  final int workId;

  /// controller 的注册标记，不同作品各用各的状态。
  static String tagOf(int workId) => 'detail-$workId';

  @override
  WorkDetailController get controller =>
      Get.find<WorkDetailController>(tag: tagOf(workId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.work.value?.title ?? '作品详情')),
      ),
      body: Obx(_body),
    );
  }

  /// 详情内容：作品信息就绪前给进度圈，失败给重试入口。
  Widget _body() {
    final work = controller.work.value;
    if (work == null) {
      final error = controller.error.value;
      return error == null
          ? const Center(child: CircularProgressIndicator())
          : MessageView(message: error, onRetry: controller.loadWork);
    }
    return ListView(
      children: [
        _WorkHeader(work: work, onTagTap: openTagSearch),
        _TrackList(
          workId: work.id,
          plan: controller.plan.value,
          current: controller.current,
          loading: controller.tracksLoading.value,
          error: controller.tracksError.value,
          onPlayAll: controller.playAll,
          onPlayIndex: controller.playIndex,
          onRetry: controller.loadTracks,
        ),
      ],
    );
  }
}

/// 详情页的依赖装配。
class DetailScreenBinding extends Bindings {
  DetailScreenBinding(this.workId);

  /// 作品 id。
  final int workId;

  @override
  void dependencies() {
    Get.lazyPut<WorkDetailController>(
      () => WorkDetailController(api: Get.find<AsmrApi>(), workId: workId),
      tag: DetailScreen.tagOf(workId),
      fenix: true,
    );
  }
}

/// 打开作品详情页。
///
/// 推到外壳导航器，底部播放器与标签栏常驻；
/// 外壳的 app bar 让位给详情页自己的 app bar。
void openDetail(int workId) {
  Get.to<void>(
    () => DetailScreen(workId: workId),
    binding: DetailScreenBinding(workId),
    id: DefaultValues.shellNavigatorId,
    // 详情页可以逐层打开其它作品，不按路由去重。
    preventDuplicates: false,
  );
}

/// 封面与作品信息。
class _WorkHeader extends StatelessWidget {
  const _WorkHeader({required this.work, this.onTagTap});

  final Work work;

  /// 点标签时的回调，为空时标签不可点。
  final void Function(String tag)? onTagTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = _metaText(work);
    final stats = _statsText(work);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: DefaultValues.cardImageAspectRatio,
            child: _cover(context),
          ),
          ListTile(
            title: Text(work.title, style: textTheme.titleLarge),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta.isNotEmpty) Text(meta, style: textTheme.bodySmall),
                if (stats.isNotEmpty) Text(stats, style: textTheme.bodySmall),
                if (work.tags.isNotEmpty) _tags(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 封面，地址缺失或加载失败时用主题色占位。
  Widget _cover(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
    final url = work.mainCoverUrl.isNotEmpty
        ? work.mainCoverUrl
        : work.samCoverUrl.isNotEmpty
        ? work.samCoverUrl
        : work.thumbnailCoverUrl;
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  /// 标签，点击按该标签搜索。
  Widget _tags() {
    return Wrap(
      children: [
        for (final tag in work.tags)
          onTagTap == null
              ? Chip(label: Text(tag.name), shape: const StadiumBorder())
              : ActionChip(
                  label: Text(tag.name),
                  shape: const StadiumBorder(),
                  onPressed: () => onTagTap!(tag.name),
                ),
      ],
    );
  }
}

/// 曲目树：目录行与音频行按接口顺序混排。
class _TrackList extends StatelessWidget {
  const _TrackList({
    required this.workId,
    required this.plan,
    required this.current,
    required this.loading,
    required this.error,
    required this.onPlayAll,
    required this.onPlayIndex,
    required this.onRetry,
  });

  /// 所属作品 id，用来判断当前曲目是否属于本作品。
  final int workId;

  /// 曲目整理结果。
  final TrackPlan plan;

  /// 正在播放的条目。
  final PlaybackItem? current;

  /// 是否正在加载曲目。
  final bool loading;

  /// 曲目加载错误。
  final String? error;

  final VoidCallback onPlayAll;
  final ValueChanged<int> onPlayIndex;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('曲目', style: textTheme.titleMedium),
            trailing: plan.items.isEmpty
                ? null
                : TextButton.icon(
                    onPressed: onPlayAll,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放全部'),
                  ),
          ),
          const Divider(),
          if (error != null)
            ListTile(
              title: Text(error!),
              trailing: TextButton(onPressed: onRetry, child: const Text('重试')),
            )
          else if (loading)
            const LinearProgressIndicator()
          else if (plan.rows.isEmpty)
            const ListTile(title: Text('没有可播放的曲目'))
          else
            for (final row in plan.rows) _row(row),
        ],
      ),
    );
  }

  /// 一行曲目：目录给标题，音频给播放入口。
  Widget _row(TrackRow row) {
    return switch (row) {
      TrackFolderRow() => ListTile(
        dense: true,
        leading: const Icon(Icons.folder_outlined),
        title: Text(row.title),
      ),
      TrackAudioRow() => _audioRow(row),
    };
  }

  /// 音频行，正在播放的一行高亮。
  Widget _audioRow(TrackAudioRow row) {
    final playing =
        current != null &&
        current!.workId == workId &&
        current!.track == row.item.track;
    return ListTile(
      selected: playing,
      leading: Icon(playing ? Icons.graphic_eq : Icons.play_arrow),
      title: Text(row.item.title),
      subtitle: row.item.hasDuration ? Text(row.item.formatDuration()) : null,
      onTap: () => onPlayIndex(row.queueIndex),
    );
  }
}

/// 一行作品信息，例如 `社团 · 2026-09-23 · 有字幕 · 免费`。
String _metaText(Work work) {
  return [
    if (work.circleName.isNotEmpty) work.circleName,
    if (work.release.isNotEmpty) work.release,
    if (work.vas.isNotEmpty) work.vas.map((va) => va.name).join('、'),
    if (work.hasSubtitle) '有字幕',
    work.isFree ? '免费' : '¥${work.price}',
  ].join(' · ');
}

/// 一行统计信息，例如 `★ 4.8（9 人） · 1200 次下载 · 12:34`。
String _statsText(Work work) {
  final duration = work.formatDuration();
  return [
    if (work.rateCount > 0)
      '★ ${work.rateAverage.toStringAsFixed(1)}（${work.rateCount} 人）',
    if (work.dlCount > 0) '${work.dlCount} 次下载',
    if (duration.isNotEmpty) duration,
  ].join(' · ');
}
