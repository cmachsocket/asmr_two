import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../core/default.dart';
import '../core/models/playlist.dart';
import '../controller/library_controller.dart';
import '../controller/playlist_create_controller.dart';

/// 创建播放列表页：名称、可见性与描述。
class PlaylistCreateScreen extends GetView<PlaylistCreateController> {
  const PlaylistCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建播放列表')),
      body: ListView(
        children: [
          TextField(
            controller: controller.nameController,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '给播放列表起个名字',
            ),
          ),
          Obx(_privacy),
          TextField(
            controller: controller.descriptionController,
            decoration: const InputDecoration(labelText: '描述'),
            maxLines: 3,
          ),
          Obx(_submit),
        ],
      ),
    );
  }

  /// 可见性选项。
  Widget _privacy() {
    return Wrap(
      children: [
        for (final privacy in PlaylistPrivacy.values)
          ChoiceChip(
            label: Text(privacy.label),
            selected: controller.privacy.value == privacy,
            onSelected: (_) => controller.changePrivacy(privacy),
          ),
      ],
    );
  }

  /// 创建按钮，未登录或没填名称时不可点。
  Widget _submit() {
    if (!controller.loggedIn) {
      return const ListTile(title: Text('登录后才能创建播放列表'));
    }
    return FilledButton(
      onPressed: controller.canCreate ? _create : null,
      child: controller.busy.value
          ? const CircularProgressIndicator()
          : const Text('创建'),
    );
  }

  /// 创建播放列表，成功后回到收藏库页。
  Future<void> _create() async {
    final ok = await controller.create();
    if (!ok) {
      Get.snackbar(
        '创建失败',
        controller.error.value ?? '请稍后重试',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.back(id: DefaultValues.shellNavigatorId);
    Get.snackbar('创建成功', '播放列表已创建', snackPosition: SnackPosition.BOTTOM);
  }
}

/// 创建播放列表页的依赖装配。
class PlaylistCreateScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlaylistCreateController>(
      () => PlaylistCreateController(
        api: Get.find<AsmrApi>(),
        library: Get.find<LibraryController>(),
      ),
    );
  }
}

/// 打开创建播放列表页。
///
/// 推到外壳导航器，底部播放器与标签栏常驻。
void openCreatePlaylist() {
  Get.to<void>(
    () => const PlaylistCreateScreen(),
    binding: PlaylistCreateScreenBinding(),
    id: DefaultValues.shellNavigatorId,
  );
}
