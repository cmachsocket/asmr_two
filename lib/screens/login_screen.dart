import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/login_controller.dart';
import '../core/default.dart';
import '../state/auth_controller.dart';

/// 登录页（账号 + 密码）。
///
/// 服务端在账号不存在时会自动创建，所以登录与注册是同一个动作。
class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(id: DefaultValues.shellNavigatorId),
        ),
        title: const Text('登录'),
      ),
      body: ListView(
        children: [
          TextField(
            controller: controller.nameController,
            decoration: const InputDecoration(
              labelText: '账号',
              hintText: '请输入账号',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          TextField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.canLogin ? () => _submit(context) : null,
              child: controller.auth.busy.value
                  ? const CircularProgressIndicator()
                  : const Text('登录'),
            ),
          ),
        ],
      ),
    );
  }

  /// 登录：成功退回设置页并提示，失败把接口错误显示出来。
  Future<void> _submit(BuildContext context) async {
    final ok = await controller.login();
    if (!context.mounted) return;
    if (ok) {
      Get.back(id: DefaultValues.shellNavigatorId);
      Get.snackbar(
        '登录成功',
        '已保存登录状态, 下次启动自动恢复',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        '登录失败',
        controller.auth.error.value ?? '请检查账号和密码',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// 登录页 binding。
class LoginScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(auth: Get.find<AuthController>()),
    );
  }
}
