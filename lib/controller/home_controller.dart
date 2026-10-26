import "package:flutter/material.dart" show ValueNotifier;
import "package:get/get.dart";

import "../state/work_feed_controller.dart";
import "search_controller.dart";

/// 首页外壳的控制器：管理标签页与列表刷新。
class HomeController extends GetxController {
  ValueNotifier<int> appbarSelector = ValueNotifier(0);
  final RxInt index = 0.obs;

  /// 是否正在刷新列表。
  final RxBool refreshing = false.obs;

  void change(int i) {
    index.value = i;
    appbarSelector.value = i;
  }

  /// 刷新发现页的作品列表。
  Future<void> refreshFind() async {
    if (!Get.isRegistered<WorkFeedController>()) return;
    await _reload(() => Get.find<WorkFeedController>());
  }

  /// 刷新搜索页的结果列表。
  Future<void> refreshSearch() async {
    if (!Get.isRegistered<SearchScreenController>()) return;
    await _reload(() => Get.find<SearchScreenController>());
  }

  /// 重新加载列表，刷新过程中忽略重复触发。
  Future<void> _reload(WorkFeedController Function() resolve) async {
    if (refreshing.value) return;
    refreshing.value = true;
    try {
      await resolve().reload();
    } finally {
      refreshing.value = false;
    }
  }
}
