import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/home_screen.dart';
import '../state/theme_controller.dart';
import 'app_binding.dart';

/// 应用根组件。
class AsmrApp extends GetView<ThemeController> {
  const AsmrApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 强调色变了要重建整棵主题树，所以这里跟着主题状态一起重建。
    return Obx(
      () => GetMaterialApp(
        title: 'ASMR One',
        debugShowCheckedModeBanner: false,
        initialBinding: AppBinding(),
        theme: controller.lightTheme,
        darkTheme: controller.darkTheme,
        themeMode: controller.mode.value,
        home: const HomeScreen(),
      ),
    );
  }
}
