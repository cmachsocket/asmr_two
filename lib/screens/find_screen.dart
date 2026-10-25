import "package:flutter/material.dart";
import "package:get/get.dart";

import "../controller/find_controller.dart";
import '../widgets/asmr_body.dart';

class FindScreen extends GetView<DiscoverController> {
  const FindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ASMRBody(works: controller.works);
  }
}

class FindScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiscoverController>(() => DiscoverController());
  }
}
