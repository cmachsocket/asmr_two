import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/models/playlist.dart';
import '../core/models/user.dart';
import '../state/auth_controller.dart';

/// 收藏库页的状态：我的播放列表。
///
/// 播放列表接口需要登录，未登录时列表为空，界面据此给出登录入口。
class LibraryController extends GetxController {
  LibraryController({required this.api, required this.auth});

  final AsmrApi api;

  /// 登录状态。
  final AuthController auth;

  /// 已加载的播放列表。
  final RxList<Playlist> _playlists = <Playlist>[].obs;

  /// 页面展示的播放列表。
  ///
  /// 读取列表会注册 Obx 监听，直接把 [RxList] 传给界面不会触发刷新。
  List<Playlist> get playlists => _playlists.toList();

  /// 是否正在加载。
  final RxBool loading = false.obs;

  /// 加载错误。
  final RxnString error = RxnString();

  /// 当前页码。
  final RxInt page = 1.obs;

  /// 总页数。
  final RxInt pageCount = 1.obs;

  /// 当前筛选条件。
  final Rx<PlaylistFilter> filter = PlaylistFilter.all.obs;

  /// 登录后才能看到播放列表。
  bool get loggedIn => auth.isLoggedIn;

  Worker? _sessionWorker;

  @override
  void onInit() {
    super.onInit();
    // 登录态变化时同步列表：登录后拉取，退出登录后清空。
    _sessionWorker = ever<SessionInfo>(auth.session, (_) => syncSession());
    syncSession();
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    super.onClose();
  }

  /// 按当前登录态同步列表。
  Future<void> syncSession() async {
    if (loggedIn) {
      await reload();
    } else {
      _playlists.clear();
      page.value = 1;
      pageCount.value = 1;
    }
  }

  /// 重新加载第一页。
  Future<void> reload() async {
    page.value = 1;
    await load();
  }

  /// 加载播放列表。
  ///
  /// [targetPage] 为空时取当前页。
  Future<void> load({int? targetPage}) async {
    if (!loggedIn) return;
    loading.value = true;
    error.value = null;
    try {
      final result = await api.fetchPlaylists(
        filter: filter.value,
        page: targetPage ?? page.value,
      );
      _playlists.assignAll(result.playlists);
      page.value = result.pagination.page;
      pageCount.value = result.pagination.maxPage;
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = '加载失败，请稍后重试。';
    } finally {
      loading.value = false;
    }
  }

  /// 跳到指定页，页码从 1 开始。
  Future<void> gotoPage(int targetPage) async {
    if (targetPage < 1) return;
    await load(targetPage: targetPage);
  }

  /// 改筛选条件并重新加载。
  Future<void> changeFilter(PlaylistFilter value) async {
    if (filter.value == value) return;
    filter.value = value;
    await reload();
  }
}
