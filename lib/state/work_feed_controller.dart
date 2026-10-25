import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/models/work.dart';

/// 作品列表的分页加载状态。
class WorkFeedController extends GetxController {
  WorkFeedController(this.api);

  final AsmrApi api;

  /// 已加载的作品。
  final RxList<Work> _works = <Work>[].obs;

  /// 页面展示的作品。
  ///
  /// 读取列表会注册 Obx 监听，直接把 [RxList] 传给界面不会触发刷新。
  List<Work> get works => _works.toList();

  /// 是否正在加载。
  final RxBool loading = false.obs;

  /// 错误文案。
  final RxnString error = RxnString();

  /// 当前页码。
  final RxInt page = 1.obs;

  /// 总页数。
  final RxInt pageCount = 1.obs;

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
    _works.clear();
    await load();
  }

  /// 加载下一页。
  Future<void> loadMore() async {
    if (loading.value || !hasMore.value) return;
    await load(targetPage: page.value + 1, append: true);
  }

  /// 跳到指定页，页码从 1 开始。
  ///
  /// 该页内容替换当前列表，不追加。
  Future<void> gotoPage(int targetPage) async {
    if (targetPage < 1) return;
    await load(targetPage: targetPage);
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
        _works.addAll(result.works);
      } else {
        _works.assignAll(result.works);
      }
      page.value = result.pagination.page;
      pageCount.value = result.pagination.maxPage;
      hasMore.value = result.pagination.hasMore;
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = '加载失败，请稍后重试。';
    } finally {
      loading.value = false;
    }
  }
}
