import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/models/playlist.dart';
import '../core/models/work.dart';
import '../state/auth_controller.dart';
import 'library_controller.dart';

/// 播放列表详情页的状态：列表信息与列表内的作品。
class PlaylistController extends GetxController {
  PlaylistController({
    required this.api,
    required this.auth,
    required this.playlistId,
    this.library,
  });

  final AsmrApi api;

  /// 登录状态，用来判断列表是不是自己的。
  final AuthController auth;

  /// 播放列表 id。
  final String playlistId;

  /// 收藏库页的状态，删除后刷新列表；不在收藏库页打开时为空。
  final LibraryController? library;

  /// 列表信息。
  final Rxn<Playlist> playlist = Rxn<Playlist>();

  /// 已加载的作品。
  final RxList<Work> _works = <Work>[].obs;

  /// 页面展示的作品。
  ///
  /// 读取列表会注册 Obx 监听，直接把 [RxList] 传给界面不会触发刷新。
  List<Work> get works => _works.toList();

  /// 是否正在加载。
  final RxBool loading = false.obs;

  /// 加载错误。
  final RxnString error = RxnString();

  /// 是否正在删除。
  final RxBool deleting = false.obs;

  /// 当前页码。
  final RxInt page = 1.obs;

  /// 总页数。
  final RxInt pageCount = 1.obs;

  /// 自己创建的普通列表才能删除，系统内置列表不行。
  bool get canDelete {
    final playlist = this.playlist.value;
    if (playlist == null || playlist.isSystem) return false;
    final userName = auth.userName;
    return userName.isNotEmpty && playlist.userName == userName;
  }

  @override
  void onInit() {
    super.onInit();
    load();
    loadMetadata();
  }

  /// 重新加载第一页。
  Future<void> reload() async {
    page.value = 1;
    await load();
  }

  /// 加载列表信息与作品。
  ///
  /// [targetPage] 为空时取当前页。
  Future<void> load({int? targetPage}) async {
    loading.value = true;
    error.value = null;
    try {
      final result = await api.fetchPlaylistWorks(
        playlistId: playlistId,
        page: targetPage ?? page.value,
      );
      _works.assignAll(result.works);
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

  /// 拉取列表信息。
  ///
  /// 拿不到列表信息时不影响作品列表，标题退回默认文案。
  Future<void> loadMetadata() async {
    try {
      playlist.value = await api.fetchPlaylistDetail(playlistId);
    } on ApiException catch (_) {
      return;
    }
  }

  /// 删除播放列表，成功返回 true。
  ///
  /// 删除后刷新收藏库页的列表。
  Future<bool> delete() async {
    if (deleting.value) return false;
    deleting.value = true;
    error.value = null;
    try {
      await api.deletePlaylist(playlistId);
      await library?.reload();
      return true;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } catch (_) {
      error.value = '删除失败，请稍后重试。';
      return false;
    } finally {
      deleting.value = false;
    }
  }
}
