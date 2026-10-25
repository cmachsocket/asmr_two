import "package:flutter/material.dart";
import "package:get/get.dart";

import '../core/api/asmr_api.dart';
import '../core/models/work.dart';
import '../state/work_feed_controller.dart';
import '../widgets/asmr_body.dart';
import '../widgets/floating_paginator.dart';
import '../widgets/message_view.dart';
import 'search_screen.dart';

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
      return MessageView(message: error, onRetry: controller.reload);
    }
    if (works.isEmpty) {
      return controller.loading.value
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    return ASMRBody(works: works, onTagTap: openTagSearch);
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
