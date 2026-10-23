import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/models/work.dart';

/// 作品列表的分页加载状态。
class WorkFeedController extends GetxController {
  WorkFeedController(this.api);

  final AsmrApi api;

  /// 已加载的作品。
  final RxList<Work> works = <Work>[].obs;

  /// 是否正在加载。
  final RxBool loading = false.obs;

  /// 错误文案。
  final RxnString error = RxnString();

  /// 当前页码。
  final RxInt page = 1.obs;

  /// 是否还有更多内容。
  final RxBool hasMore = true.obs;

  /// 搜索关键字，为空时按最新排序浏览。
  final RxString keyword = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// 重新加载列表。
  Future<void> reload() async {
    page.value = 1;
    hasMore.value = true;
    works.clear();
    await load();
  }

  /// 加载下一页。
  Future<void> loadMore() async {
    if (loading.value || !hasMore.value) return;
    await load(targetPage: page.value + 1, append: true);
  }

  /// 按关键字搜索。
  Future<void> search(String value) async {
    keyword.value = value.trim();
    await reload();
  }

  /// 加载作品列表。
  Future<void> load({int? targetPage, bool append = false}) async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      final result = keyword.value.isEmpty
          ? await api.fetchWorks(page: targetPage ?? 1)
          : await api.searchWorks(keyword.value, page: targetPage ?? 1);
      if (append) {
        works.addAll(result.works);
      } else {
        works.assignAll(result.works);
      }
      page.value = result.pagination.page;
      hasMore.value = result.pagination.hasMore;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }
}
