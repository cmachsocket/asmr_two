import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 用 1x1 图片占住封面缓存，避免 widget 测试发起真实网络请求。
Future<void> mockCoverImage(WidgetTester tester, String url) async {
  final image = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const ui.Color(0xFF000000),
    );
    return recorder.endRecording().toImage(1, 1);
  });
  PaintingBinding.instance.imageCache.putIfAbsent(
    NetworkImage(url),
    () => OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: image!, scale: 1)),
    ),
  );
}
