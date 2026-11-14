import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/search_controller.dart';

/// 筛选面板，按标签或声优筛选作品。
class SearchFilterSheet extends GetView<SearchScreenController> {
  const SearchFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text('筛选'),
              trailing: TextButton(
                onPressed: controller.clearFilters,
                child: const Text('清空'),
              ),
            ),
            ListTile(
              title: Obx(
                () => SegmentedButton<FilterCategory>(
                  segments: [
                    for (final category in FilterCategory.values)
                      ButtonSegment(
                        value: category,
                        label: Text(category.label),
                      ),
                  ],
                  selected: {controller.category.value},
                  onSelectionChanged: (selection) =>
                      controller.category.value = selection.first,
                ),
              ),
            ),
            ListTile(
              title: TextField(
                decoration: const InputDecoration(
                  hintText: '搜索标签或声优',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => controller.filterKeyword.value = value,
              ),
            ),
            Expanded(child: _options()),
          ],
        ),
      ),
    );
  }

  /// 当前类别的可选项列表。
  Widget _options() {
    return Obx(() {
      if (controller.optionsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final error = controller.optionsError.value;
      if (error != null) {
        return Center(child: Text(error));
      }
      if (controller.category.value == FilterCategory.tag) {
        final visible = controller.visibleTags;
        return _optionFlow([
          for (final tag in visible)
            _OptionCell(
              label: controller.tagLabel(tag),
              count: tag.count,
              selected: controller.selectedTags.contains(tag.name),
              onTap: () => controller.toggleTag(tag.name),
            ),
        ]);
      }
      final visible = controller.visibleVoiceActors;
      return _optionFlow([
        for (final va in visible)
          _OptionCell(
            label: va.name,
            count: va.count,
            selected: controller.selectedVoiceActors.contains(va.name),
            onTap: () => controller.toggleVoiceActor(va.name),
          ),
      ]);
    });
  }

  /// 选项按内容宽度排布，一行放不下就换行，因此每行的选项数量随文字长度变化。
  Widget _optionFlow(List<Widget> children) {
    return SingleChildScrollView(child: Wrap(children: children));
  }
}

/// 筛选面板里的一项，文字用胶囊包起来。
class _OptionCell extends StatelessWidget {
  const _OptionCell({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// 关联作品数量。
  final int count;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$count 个作品',
      child: FilterChip(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: selected,
        showCheckmark: false,
        shape: const StadiumBorder(),
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
