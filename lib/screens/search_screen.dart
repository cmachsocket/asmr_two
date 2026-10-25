import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/asmr_api.dart';
import '../controller/search_controller.dart';
import '../widgets/asmr_body.dart';
import '../widgets/floating_paginator.dart';
import '../widgets/message_view.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/search_sort_sheet.dart';

/// 搜索页，按关键字、排序与筛选条件找作品。
class SearchScreen extends GetView<SearchScreenController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SearchBar(),
        Expanded(child: Obx(() => _results())),
      ],
    );
  }

  /// 搜索结果区。
  Widget _results() {
    final works = controller.works;
    final error = controller.error.value;
    if (error != null) {
      return MessageView(message: error, onRetry: controller.reload);
    }
    if (works.isEmpty) {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return MessageView(
        message: controller.keyword.value.isEmpty ? '输入关键字或选择筛选条件' : '没有找到作品',
      );
    }
    return Stack(
      children: [
        Positioned.fill(child: ASMRBody(works: works)),
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

/// 搜索栏：关键字输入与排序、筛选入口。
class _SearchBar extends GetView<SearchScreenController> {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                textInputAction: TextInputAction.search,
                onChanged: (value) => controller.text = value,
                onSubmitted: controller.search,
                decoration: const InputDecoration(
                  hintText: '搜索作品',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            IconButton(
              tooltip: '排序',
              icon: const Icon(Icons.sort),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (context) => const SearchSortSheet(),
              ),
            ),
            IconButton(
              tooltip: '筛选',
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                controller.loadOptions();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const SearchFilterSheet(),
                );
              },
            ),
          ],
        ),
        Obx(() => _selectedFilters()),
      ],
    );
  }

  /// 已选筛选条件的标签。
  Widget _selectedFilters() {
    final tags = controller.selectedTags.toList();
    final voiceActors = controller.selectedVoiceActors.toList();
    if (tags.isEmpty && voiceActors.isEmpty) return const SizedBox.shrink();
    return Wrap(
      children: [
        for (final tag in tags)
          InputChip(
            label: Text(controller.tagDisplay(tag)),
            onDeleted: () => controller.toggleTag(tag),
          ),
        for (final voiceActor in voiceActors)
          InputChip(
            label: Text(voiceActor),
            onDeleted: () => controller.toggleVoiceActor(voiceActor),
          ),
      ],
    );
  }
}

class SearchScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchScreenController>(
      () => SearchScreenController(Get.find<AsmrApi>()),
    );
  }
}
