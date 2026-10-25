import 'package:get/get.dart';

import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/models/work.dart';
import '../state/work_feed_controller.dart';

/// 筛选面板里的类别。
enum FilterCategory {
  tag('标签'),
  voiceActor('声优');

  const FilterCategory(this.label);

  /// 面板里的标题。
  final String label;
}

/// 搜索页控制器。
///
/// 关键字与筛选条件编码成搜索关键字，
/// 服务端不接收独立的筛选参数。
class SearchScreenController extends WorkFeedController {
  SearchScreenController(super.api) : super(autoLoad: false);

  /// 标签译名使用的语言。
  static const String tagLocale = 'zh-cn';

  /// 搜索框里的关键字原文。
  String text = '';

  /// 选中的标签，按标签名匹配。
  final RxList<String> selectedTags = <String>[].obs;

  /// 选中的声优，按声优名匹配。
  final RxList<String> selectedVoiceActors = <String>[].obs;

  /// 标签全集，按作品数从多到少排列。
  final RxList<Tag> tags = <Tag>[].obs;

  /// 声优全集，按作品数从多到少排列。
  final RxList<VoiceActor> voiceActors = <VoiceActor>[].obs;

  /// 筛选选项是否在加载。
  final RxBool optionsLoading = false.obs;

  /// 筛选选项的加载错误。
  final RxnString optionsError = RxnString();

  /// 筛选面板当前显示的类别。
  final Rx<FilterCategory> category = FilterCategory.tag.obs;

  /// 筛选面板里的关键字。
  final RxString filterKeyword = ''.obs;

  /// 搜索页只走搜索接口，不浏览全站作品。
  @override
  Future<WorksPage> fetchPage(int targetPage) => api.searchWorks(
    keyword.value,
    page: targetPage,
    order: order.value,
    sort: sort.value,
  );

  /// 拉取筛选用的标签与声优，已加载过就不再请求。
  Future<void> loadOptions() async {
    if (optionsLoading.value) return;
    optionsLoading.value = true;
    optionsError.value = null;
    try {
      final (tagList, vaList) = await (
        api.fetchTags(),
        api.fetchVoiceActors(),
      ).wait;
      tags.assignAll(tagList..sort((a, b) => b.count.compareTo(a.count)));
      voiceActors.assignAll(vaList..sort((a, b) => b.count.compareTo(a.count)));
    } on ApiException catch (e) {
      optionsError.value = e.message;
    } catch (_) {
      optionsError.value = '加载失败，请稍后重试。';
    } finally {
      optionsLoading.value = false;
    }
  }

  /// 按输入的关键字搜索。
  @override
  Future<void> search(String value) async {
    text = value;
    await apply();
  }

  /// 按当前关键字与筛选条件重新搜索。
  Future<void> apply() async {
    keyword.value = _encode();
    await reload();
  }

  /// 选中或取消一个标签。
  void toggleTag(String name) {
    _toggle(selectedTags, name);
    apply();
  }

  /// 选中或取消一个声优。
  void toggleVoiceActor(String name) {
    _toggle(selectedVoiceActors, name);
    apply();
  }

  /// 清空筛选条件。
  void clearFilters() {
    selectedTags.clear();
    selectedVoiceActors.clear();
    apply();
  }

  /// 改排序字段并重新搜索。
  void changeOrder(WorkOrder value) {
    order.value = value;
    apply();
  }

  /// 改排序方向并重新搜索。
  void changeSort(SortDirection value) {
    sort.value = value;
    apply();
  }

  /// 筛选面板里可见的标签。
  List<Tag> get visibleTags {
    final keyword = filterKeyword.value.trim().toLowerCase();
    if (keyword.isEmpty) return tags.toList();
    return tags
        .where((tag) => _matches(tag.name, tag.label(tagLocale), keyword))
        .toList();
  }

  /// 筛选面板里可见的声优。
  List<VoiceActor> get visibleVoiceActors {
    final keyword = filterKeyword.value.trim().toLowerCase();
    if (keyword.isEmpty) return voiceActors.toList();
    return voiceActors.where((va) => _matches(va.name, null, keyword)).toList();
  }

  /// 标签的展示名，优先用译名。
  String tagLabel(Tag tag) => tag.label(tagLocale);

  /// 按标签名取展示名，优先用译名。
  String tagDisplay(String name) {
    final tag = tags.firstWhereOrNull((tag) => tag.name == name);
    return tag == null ? name : tag.label(tagLocale);
  }

  /// 把关键字与筛选条件编码成搜索接口识别的关键字。
  String _encode() {
    return SearchKeyword(
      text: text,
      terms: [
        for (final tag in selectedTags) SearchTerm(SearchNamespace.tag, tag),
        for (final va in selectedVoiceActors)
          SearchTerm(SearchNamespace.voiceActor, va),
      ],
    ).build();
  }

  void _toggle(RxList<String> list, String value) {
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
  }

  bool _matches(String name, String? label, String keyword) {
    return name.toLowerCase().contains(keyword) ||
        (label?.toLowerCase().contains(keyword) ?? false);
  }
}
