import "package:flutter/material.dart";
import "package:get/get.dart";

import "../controller/settings_controllers.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Settings Screen")));
  }
}

class SettingsScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
