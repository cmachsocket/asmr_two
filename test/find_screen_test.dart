import 'package:asmr_two/screens/find_screen.dart';
import 'package:asmr_two/widgets/asmr_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('发现页渲染示例作品且不触发 Obx 误用', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: FindScreenBinding(),
        home: const FindScreen(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AsmrCard), findsWidgets);
  });
}
