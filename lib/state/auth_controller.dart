import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/api/asmr_api.dart';
import '../core/models/user.dart';
import '../core/storage/session_store.dart';

/// 登录状态管理。
class AuthController extends GetxController {
  AuthController({required this.api, required this.sessionStore});

  final AsmrApi api;
  final SessionStore sessionStore;

  /// 当前会话信息。
  final Rx<SessionInfo> session = SessionInfo.anonymous.obs;

  /// 是否正在执行登录相关请求。
  final RxBool busy = false.obs;

  /// 上一次操作的错误文案。
  final RxnString error = RxnString();

  bool get isLoggedIn => session.value.user.loggedIn;

  /// 当前登录用户的名称。
  String get userName => session.value.user.name ?? '';

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  /// 启动时用已保存的令牌恢复会话。
  Future<void> restore() async {
    if (!sessionStore.hasToken) {
      session.value = SessionInfo.anonymous;
      return;
    }
    busy.value = true;
    try {
      session.value = await api.fetchSession();
      if (!session.value.user.loggedIn) {
        await sessionStore.clearToken();
      }
    } on ApiException catch (e) {
      if (e.isUnauthorized) await sessionStore.clearToken();
      session.value = SessionInfo.anonymous;
      error.value = e.message;
    } finally {
      busy.value = false;
    }
  }

  /// 登录，服务端在账号不存在时会自动创建。
  Future<bool> login(String name, String password) async {
    error.value = null;
    busy.value = true;
    try {
      final result = await api.login(name, password);
      await sessionStore.saveToken(result.token);
      await refreshSession();
      return true;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } finally {
      busy.value = false;
    }
  }

  /// 注册。
  Future<bool> register(
    String name,
    String password, {
    String? recommenderUuid,
  }) async {
    error.value = null;
    busy.value = true;
    try {
      final result = await api.register(
        name,
        password,
        recommenderUuid: recommenderUuid,
      );
      await sessionStore.saveToken(result.token);
      await refreshSession();
      return true;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } finally {
      busy.value = false;
    }
  }

  /// 退出登录。
  Future<void> logout() async {
    await sessionStore.clearToken();
    session.value = SessionInfo.anonymous;
  }

  /// 重新拉取会话信息。
  Future<void> refreshSession() async {
    try {
      session.value = await api.fetchSession();
    } on ApiException catch (e) {
      error.value = e.message;
    }
  }
}
