import 'package:flutter/material.dart';

/// 一行提示文案，可以带一个重试入口。
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.message, this.onRetry});

  final String message;

  /// 重试回调，为空时不显示重试按钮。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
