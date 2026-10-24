import "package:get/get.dart";

class HomeController extends GetxController {
  final RxInt index = 0.obs;
  void change(int i) => index.value = i;
}
