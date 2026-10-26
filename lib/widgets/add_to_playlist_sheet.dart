import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../controller/add_to_playlist_controller.dart';
import '../core/models/playlist.dart';
import 'message_view.dart';

/// 「加入播放列表」面板：列出我的播放列表，点一行加入或移出。
class AddToPlaylistSheet extends GetView<AddToPlaylistController> {
  const AddToPlaylistSheet({super.key, required this.workId});

  /// 作品 id，决定用哪个 controller。
  final int workId;

  @override
  AddToPlaylistController get controller => Get.find<AddToPlaylistController>(
    tag: AddToPlaylistController.tagOf(workId),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(top: false, child: Obx(_body));
  }

  /// 面板主体：出错给重试入口，否则给播放列表。
  Widget _body() {
    final error = controller.error.value;
    if (error != null) {
      return MessageView(message: error, onRetry: controller.load);
    }
    final playlists = controller.playlists;
    if (playlists.isEmpty) {
      return controller.loading.value
          ? const Center(child: CircularProgressIndicator())
          : const MessageView(message: '还没有播放列表');
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final playlist in playlists) _item(playlist),
        if (controller.hasMore.value)
          ListTile(
            leading: const Icon(Icons.expand_more),
            title: const Text('加载更多'),
            onTap: () => controller.load(more: true),
          ),
      ],
    );
  }

  /// 一行播放列表，勾选状态就是作品是否已在此列表中。
  Widget _item(Playlist playlist) {
    return CheckboxListTile(
      title: Text(playlist.displayName),
      subtitle: Text('${playlist.worksCount} 个作品'),
      value: controller.selected.contains(playlist.id),
      onChanged: controller.pending.contains(playlist.id)
          ? null
          : (_) => _toggle(playlist),
    );
  }

  /// 切换作品在列表中的归属。
  Future<void> _toggle(Playlist playlist) async {
    final error = await controller.toggle(playlist);
    if (error == null) return;
    Get.snackbar('操作失败', error, snackPosition: SnackPosition.BOTTOM);
  }
}

/// 打开「加入播放列表」面板。
///
/// 面板里的 controller 只在面板打开期间存在。
Future<void> showAddToPlaylist(BuildContext context, int workId) async {
  final tag = AddToPlaylistController.tagOf(workId);
  Get.put<AddToPlaylistController>(
    AddToPlaylistController(api: Get.find<AsmrApi>(), workId: workId),
    tag: tag,
  );
  try {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => AddToPlaylistSheet(workId: workId),
    );
  } finally {
    Get.delete<AddToPlaylistController>(tag: tag);
  }
}
