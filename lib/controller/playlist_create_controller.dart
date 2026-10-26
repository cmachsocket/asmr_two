import 'package:flutter/material.dart' show TextEditingController;
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/models/playlist.dart';
import 'library_controller.dart';

/// 创建播放列表页的控制器：表单状态与创建请求。
class PlaylistCreateController extends GetxController {
  PlaylistCreateController({required this.api, required this.library});

  final AsmrApi api;

  /// 收藏库页的状态，创建成功后刷新列表。
  final LibraryController library;

  /// 名称输入框。
  final TextEditingController nameController = TextEditingController();

  /// 描述输入框。
  final TextEditingController descriptionController = TextEditingController();

  /// 名称原文。
  final RxString name = ''.obs;

  /// 可见性。
  final Rx<PlaylistPrivacy> privacy = PlaylistPrivacy.private.obs;

  /// 是否正在创建。
  final RxBool busy = false.obs;

  /// 上一次操作的错误文案。
  final RxnString error = RxnString();

  /// 播放列表需要登录才能创建。
  bool get loggedIn => library.loggedIn;

  /// 填了名称、已登录且没有正在进行的请求时才能创建。
  bool get canCreate => loggedIn && name.value.trim().isNotEmpty && !busy.value;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_syncName);
  }

  @override
  void onClose() {
    nameController.removeListener(_syncName);
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// 改可见性。
  void changePrivacy(PlaylistPrivacy value) {
    privacy.value = value;
  }

  /// 创建播放列表，成功返回 true。
  Future<bool> create() async {
    if (!canCreate) return false;
    busy.value = true;
    error.value = null;
    try {
      await api.createPlaylist(
        name: name.value.trim(),
        privacy: privacy.value,
        description: descriptionController.text.trim(),
      );
      await library.reload();
      return true;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } catch (_) {
      error.value = '创建失败，请稍后重试。';
      return false;
    } finally {
      busy.value = false;
    }
  }

  void _syncName() => name.value = nameController.text;
}
