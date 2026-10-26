import "package:flutter/material.dart";
import "package:get/get.dart";

/// 刷新按钮，重新加载列表。
///
/// 加载中显示进度圈并禁用点击，避免重复请求。
class RefreshButton extends StatelessWidget {
  const RefreshButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  /// 加载状态，加载中按钮换成进度圈。
  final RxBool loading;

  /// 刷新动作。
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => IconButton(
        tooltip: '刷新',
        onPressed: loading.value ? null : onPressed,
        icon: loading.value
            ? const CircularProgressIndicator()
            : const Icon(Icons.refresh),
      ),
    );
  }
}
