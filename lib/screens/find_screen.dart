import "package:flutter/material.dart";
import "package:get/get.dart";

import '../core/api/asmr_api.dart';
import '../core/models/work.dart';
import '../state/work_feed_controller.dart';
import '../widgets/asmr_body.dart';
import '../widgets/floating_paginator.dart';

/// 发现页，按最新排序浏览作品。
class FindScreen extends GetView<WorkFeedController> {
  const FindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final works = controller.works;
      final error = controller.error.value;
      return Stack(
        children: [
          Positioned.fill(child: _body(works, error)),
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
    });
  }

  /// 列表主体：出错给重试入口，加载中给进度圈，否则给作品网格。
  Widget _body(List<Work> works, String? error) {
    if (error != null) {
      return _ErrorView(message: error, onRetry: controller.reload);
    }
    if (works.isEmpty) {
      return controller.loading.value
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    return ASMRBody(works: works);
  }
}

class FindScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkFeedController>(
      () => WorkFeedController(Get.find<AsmrApi>()),
    );
  }
}

/// 出错时的提示与重试。
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
