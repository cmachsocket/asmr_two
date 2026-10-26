import 'package:flutter/widgets.dart' show TextEditingController;
import 'package:get/get.dart';

import '../state/auth_controller.dart';

/// 登录页控制器：输入框状态与登录编排。
///
/// 真正的登录请求由 [AuthController] 负责，这里只管界面输入。
class LoginController extends GetxController {
  LoginController({required this.auth});

  /// 登录状态与令牌都归 [AuthController] 管。
  final AuthController auth;

  /// 账号输入框。
  final TextEditingController nameController = TextEditingController();

  /// 密码输入框。
  final TextEditingController passwordController = TextEditingController();

  final RxString name = ''.obs;
  final RxString password = ''.obs;

  /// 输入齐了且没有正在进行的登录请求时才能登录。
  bool get canLogin =>
      name.value.trim().isNotEmpty &&
      password.value.isNotEmpty &&
      !auth.busy.value;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_syncName);
    passwordController.addListener(_syncPassword);
  }

  @override
  void onClose() {
    nameController.removeListener(_syncName);
    nameController.dispose();
    passwordController.removeListener(_syncPassword);
    passwordController.dispose();
    super.onClose();
  }

  void _syncName() => name.value = nameController.text;

  void _syncPassword() => password.value = passwordController.text;

  /// 登录，成功返回 true，失败时错误文案在 [AuthController.error] 里。
  Future<bool> login() async {
    if (!canLogin) return false;
    return auth.login(name.value.trim(), password.value);
  }
}
