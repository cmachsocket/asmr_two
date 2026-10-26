import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../core/default.dart';
import '../core/models/playlist.dart';
import '../controller/library_controller.dart';
import '../state/auth_controller.dart';
import '../widgets/floating_paginator.dart';
import '../widgets/message_view.dart';
import '../widgets/playlist_body.dart';
import 'login_screen.dart';
import 'playlist_screen.dart';

/// 收藏库页：我的播放列表。
///
/// 播放列表需要登录才能查看，未登录时给出登录入口。
class LibraryScreen extends GetView<LibraryController> {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => _body());
  }

  /// 列表区：未登录给登录入口，出错给重试入口，否则给播放列表网格。
  Widget _body() {
    if (!controller.loggedIn) return const _LoginHint();
    final selected = controller.filter.value;
    return Column(
      children: [
        _FilterBar(controller: controller, selected: selected),
        Expanded(child: _playlists()),
      ],
    );
  }

  /// 播放列表网格与分页。
  Widget _playlists() {
    final error = controller.error.value;
    if (error != null) {
      return MessageView(message: error, onRetry: controller.reload);
    }
    final playlists = controller.playlists;
    if (playlists.isEmpty) {
      return controller.loading.value
          ? const Center(child: CircularProgressIndicator())
          : const MessageView(message: '还没有播放列表');
    }
    return Stack(
      children: [
        Positioned.fill(
          child: PlaylistBody(playlists: playlists, onTap: openPlaylist),
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
}

/// 播放列表的筛选条件。
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller, required this.selected});

  final LibraryController controller;

  /// 当前选中的筛选条件。
  final PlaylistFilter selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (final filter in PlaylistFilter.values)
          ChoiceChip(
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) => controller.changeFilter(filter),
          ),
      ],
    );
  }
}

/// 未登录时的提示，带一个登录入口。
class _LoginHint extends StatelessWidget {
  const _LoginHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('登录后查看播放列表'),
          TextButton(
            onPressed: () => Get.to(
              () => const LoginScreen(),
              binding: LoginScreenBinding(),
              id: DefaultValues.shellNavigatorId,
            ),
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }
}

class LibraryScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LibraryController>(
      () => LibraryController(
        api: Get.find<AsmrApi>(),
        auth: Get.find<AuthController>(),
      ),
    );
  }
}
