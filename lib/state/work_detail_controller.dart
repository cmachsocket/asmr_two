import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/audio/track_plan.dart';
import '../core/models/work.dart';
import 'player_controller.dart';

/// 作品详情的状态：作品信息、曲目与播放入口。
class WorkDetailController extends GetxController {
  WorkDetailController({required this.api, required this.workId});

  final AsmrApi api;

  /// 作品 id。
  final int workId;

  final PlayerController _player = Get.find<PlayerController>();

  /// 作品信息。
  final Rxn<Work> work = Rxn<Work>();

  /// 是否正在加载作品信息。
  final RxBool loading = false.obs;

  /// 作品信息加载错误。
  final RxnString error = RxnString();

  /// 曲目整理结果。
  final Rx<TrackPlan> plan = TrackPlan.empty.obs;

  /// 是否正在加载曲目。
  final RxBool tracksLoading = false.obs;

  /// 曲目加载错误。
  final RxnString tracksError = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// 拉取作品信息与曲目。
  Future<void> load() async {
    await loadWork();
    await loadTracks();
  }

  /// 拉取作品信息。
  Future<void> loadWork() async {
    loading.value = true;
    error.value = null;
    try {
      work.value = await api.fetchWork(workId);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  /// 拉取作品曲目并整理成播放队列。
  Future<void> loadTracks() async {
    tracksLoading.value = true;
    tracksError.value = null;
    try {
      final nodes = await api.fetchTracks(workId);
      plan.value = TrackPlan.fromNodes(
        nodes: nodes,
        workId: workId,
        workTitle: work.value?.title ?? '',
        coverUrl: api.coverUrl(workId),
      );
    } on ApiException catch (e) {
      tracksError.value = e.message;
    } finally {
      tracksLoading.value = false;
    }
  }

  /// 播放整部作品。
  Future<void> playAll() => _player.playQueue(plan.value.items);

  /// 播放队列中的第 [index] 项。
  Future<void> playIndex(int index) =>
      _player.playQueue(plan.value.items, index: index);
}
