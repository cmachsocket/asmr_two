import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../core/default.dart';
import '../core/models/playlist.dart';
import '../controller/library_controller.dart';
import '../controller/playlist_controller.dart';
import '../state/auth_controller.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/asmr_body.dart';
import '../widgets/floating_paginator.dart';
import '../widgets/message_view.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

/// 播放列表详情页：列表信息与列表内的作品。
///
/// 列表信息与作品由 [PlaylistController] 拉取。
class PlaylistScreen extends GetView<PlaylistController> {
  const PlaylistScreen({super.key, required this.playlistId});

  /// 播放列表 id。
  final String playlistId;

  /// controller 的注册标记，不同列表各用各的状态。
  static String tagOf(String playlistId) => 'playlist-$playlistId';

  @override
  PlaylistController get controller =>
      Get.find<PlaylistController>(tag: tagOf(playlistId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => _title(context)),
        actions: [Obx(() => _deleteAction(context))],
      ),
      body: Obx(() => _works(context)),
    );
  }

  /// 删除入口，只有自己创建的列表才给。
  Widget _deleteAction(BuildContext context) {
    if (!controller.canDelete) return const SizedBox.shrink();
    return IconButton(
      tooltip: '删除播放列表',
      icon: const Icon(Icons.delete_outline),
      onPressed: controller.deleting.value
          ? null
          : () => _confirmDelete(context),
    );
  }

  /// 标题：列表名称与归属信息。
  Widget _title(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final playlist = controller.playlist.value;
    if (playlist == null) {
      return Text('播放列表', style: textTheme.titleLarge);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playlist.displayName,
          style: textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _meta(playlist),
          style: textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 列表里的作品。
  Widget _works(BuildContext context) {
    final error = controller.error.value;
    if (error != null) {
      return MessageView(message: error, onRetry: controller.reload);
    }
    final works = controller.works;
    if (works.isEmpty) {
      return controller.loading.value
          ? const Center(child: CircularProgressIndicator())
          : const MessageView(message: '这个列表还没有作品');
    }
    return Stack(
      children: [
        Positioned.fill(
          child: ASMRBody(
            works: works,
            onTagTap: openTagSearch,
            onWorkTap: openDetail,
            onAddToPlaylist: (workId) => showAddToPlaylist(context, workId),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: FloatingPaginator(
            pageCount: controller.pageCount.value,
            currentPage: controller.page.value,
            onPageChange: controller.gotoPage,
          ),
        ),
      ],
    );
  }

  /// 一行归属信息，例如 `cmach_socket · 1 个作品 · 私密`。
  String _meta(Playlist playlist) {
    return [
      if (playlist.userName.isNotEmpty) playlist.userName,
      if (playlist.worksCount > 0) '${playlist.worksCount} 个作品',
      playlist.privacy.label,
      if (playlist.description.isNotEmpty) playlist.description,
    ].join(' · ');
  }

  /// 确认后删除播放列表，成功后回到收藏库页。
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除播放列表'),
        content: const Text('删除后不可恢复，收藏本列表的人将无法再访问。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.delete();
    if (!ok) {
      Get.snackbar(
        '删除失败',
        controller.error.value ?? '请稍后重试',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.back(id: DefaultValues.shellNavigatorId);
    Get.snackbar('删除成功', '播放列表已删除', snackPosition: SnackPosition.BOTTOM);
  }
}

/// 播放列表详情页的依赖装配。
class PlaylistScreenBinding extends Bindings {
  PlaylistScreenBinding(this.playlistId);

  /// 播放列表 id。
  final String playlistId;

  @override
  void dependencies() {
    Get.lazyPut<PlaylistController>(
      () => PlaylistController(
        api: Get.find<AsmrApi>(),
        auth: Get.find<AuthController>(),
        playlistId: playlistId,
        library: Get.isRegistered<LibraryController>()
            ? Get.find<LibraryController>()
            : null,
      ),
      tag: PlaylistScreen.tagOf(playlistId),
      fenix: true,
    );
  }
}

/// 打开播放列表详情页。
///
/// 推到外壳导航器，底部播放器与标签栏常驻。
void openPlaylist(Playlist playlist) {
  Get.to<void>(
    () => PlaylistScreen(playlistId: playlist.id),
    binding: PlaylistScreenBinding(playlist.id),
    id: DefaultValues.shellNavigatorId,
    // 列表可以逐层打开，不按路由去重。
    preventDuplicates: false,
  );
}
