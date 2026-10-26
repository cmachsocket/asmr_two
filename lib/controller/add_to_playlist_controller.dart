import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/models/playlist.dart';
import 'library_controller.dart';

/// 「加入播放列表」面板的状态：我的播放列表与作品的归属。
class AddToPlaylistController extends GetxController {
  AddToPlaylistController({required this.api, required this.workId});

  final AsmrApi api;

  /// 作品 id。
  final int workId;

  /// controller 的注册标记，不同作品各用各的状态。
  static String tagOf(int workId) => 'add-to-playlist-$workId';

  /// 已加载的播放列表。
  final RxList<Playlist> _playlists = <Playlist>[].obs;

  /// 面板展示的播放列表。
  List<Playlist> get playlists => _playlists.toList();

  /// 作品已在其中的列表 id。
  final RxSet<String> selected = <String>{}.obs;

  /// 正在提交的列表 id。
  final RxSet<String> pending = <String>{}.obs;

  /// 是否正在加载。
  final RxBool loading = false.obs;

  /// 加载错误。
  final RxnString error = RxnString();

  /// 是否还有下一页。
  final RxBool hasMore = false.obs;

  int _page = 1;

  /// 是否改过作品归属，决定关闭面板时要不要刷新收藏库。
  bool _changed = false;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    // 收藏库页的卡片也显示作品数，改过归属就让它重新拉一次。
    if (_changed && Get.isRegistered<LibraryController>()) {
      Get.find<LibraryController>().reload();
    }
    super.onClose();
  }

  /// 加载我的播放列表，[more] 为真时接着往下翻。
  Future<void> load({bool more = false}) async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      final result = await api.fetchMyPlaylists(
        workId: workId,
        page: more ? _page + 1 : 1,
      );
      if (more) {
        _playlists.addAll(result.playlists);
      } else {
        _playlists.assignAll(result.playlists);
        selected
          ..clear()
          ..addAll(
            result.playlists
                .where((playlist) => playlist.exist)
                .map((playlist) => playlist.id),
          );
      }
      _page = result.pagination.page;
      hasMore.value = result.pagination.hasMore;
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = '加载失败，请稍后重试。';
    } finally {
      loading.value = false;
    }
  }

  /// 把作品加入或移出某个列表，失败时返回错误文案。
  Future<String?> toggle(Playlist playlist) async {
    if (pending.contains(playlist.id)) return null;
    final marked = selected.contains(playlist.id);
    pending.add(playlist.id);
    try {
      if (marked) {
        await api.removeWorksFromPlaylist(playlist.id, [workId]);
        selected.remove(playlist.id);
      } else {
        await api.addWorksToPlaylist(playlist.id, [workId]);
        selected.add(playlist.id);
      }
      _syncCount(playlist.id, added: !marked);
      _changed = true;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return '操作失败，请稍后重试。';
    } finally {
      pending.remove(playlist.id);
    }
  }

  /// 同步列表里的作品数量与归属。
  void _syncCount(String playlistId, {required bool added}) {
    final index = _playlists.indexWhere(
      (playlist) => playlist.id == playlistId,
    );
    if (index < 0) return;
    final current = _playlists[index];
    final worksCount = current.worksCount + (added ? 1 : -1);
    _playlists[index] = current.copyWith(
      worksCount: worksCount < 0 ? 0 : worksCount,
      exist: added,
    );
  }
}
