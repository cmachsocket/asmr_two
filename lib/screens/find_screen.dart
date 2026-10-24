import "package:flutter/material.dart";
import "package:get/get.dart";

import "../controller/find_controller.dart";

class FindScreen extends StatelessWidget {
  const FindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Find Screen")));
  }
}

class FindScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiscoverController>(() => DiscoverController());
  }
}
