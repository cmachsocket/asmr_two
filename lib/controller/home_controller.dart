import "package:flutter/material.dart" show ValueNotifier;
import "package:get/get.dart";

class HomeController extends GetxController {
  ValueNotifier<int> appbarSelector = ValueNotifier(0);
  final RxInt index = 0.obs;
  void change(int i) {
    index.value = i;
    appbarSelector.value = i;
  }
}
