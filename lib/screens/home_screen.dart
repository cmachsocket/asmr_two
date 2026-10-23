import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_spacing.dart';
import '../state/work_feed_controller.dart';

/// 首页，浏览作品列表。
class HomeScreen extends GetView<WorkFeedController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASMR One'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(AppSpacing.lg(context)),
          child: Padding(
            padding: AppSpacing.horizontal(context),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '搜索作品',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: controller.search,
            ),
          ),
        ),
      ),
      body: Obx(() {
        final works = controller.works;
        final error = controller.error.value;

        if (works.isEmpty && controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (works.isEmpty && error != null) {
          return _ErrorView(message: error, onRetry: controller.reload);
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter <= 0) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: AppSpacing.vertical(context),
              itemCount: works.length + 1,
              separatorBuilder: (context, index) => AppSpacing.gap(context),
              itemBuilder: (context, index) {
                if (index == works.length) {
                  return controller.loading.value
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink();
                }
                final work = works[index];
                return ListTile(
                  contentPadding: AppSpacing.horizontal(context),
                  title: Text(
                    work.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      work.circleName,
                      if (work.release.isNotEmpty) work.release,
                      if (work.rateCount > 0) '★ ${work.rateAverage}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.padding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            AppSpacing.gap(context),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
