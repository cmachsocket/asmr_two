import "package:flutter/material.dart";
import "package:get/get.dart";

import "../controller/library_controller.dart";

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Library Screen")));
  }
}

class LibraryScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LibraryController>(() => LibraryController());
  }
}
