import 'dart:io';

import 'package:asmr_two/app/app_binding.dart';
import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/models/user.dart';
import 'package:asmr_two/core/storage/session_store.dart';
import 'package:asmr_two/screens/settings_screen.dart';
import 'package:asmr_two/state/auth_controller.dart';
import 'package:asmr_two/state/settings_controller.dart';
import 'package:asmr_two/state/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_adapter.dart';
import 'support/fake_storage.dart';

void main() {
  late Directory storageDir;

  setUp(() async {
    Get.testMode = true;
    storageDir = await initFakeStorage();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final (client, _) = buildClient((options) async => jsonBody({}));
    Get.put<AsmrApi>(AsmrApi(client));
    Get.put<SessionStore>(SessionStore(prefs));
    Get.put<ThemeController>(ThemeController());
  });

  tearDown(() async {
    Get.reset();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  /// 渲染设置页。
  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: AppBinding(),
        home: const Scaffold(body: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('设置页列出迁移过来的条目', (tester) async {
    await pumpSettings(tester);

    expect(find.text('主题'), findsOneWidget);
    expect(find.text('强调色'), findsOneWidget);
    expect(find.text('登录账号'), findsOneWidget);
    expect(find.text('窗口退出按钮'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('设置页没有下载入口', (tester) async {
    await pumpSettings(tester);

    expect(find.text('下载模式'), findsNothing);
  });

  testWidgets('退出到托盘的开关会写进本地存储', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(Get.find<SettingsController>().exitToTray.value, isTrue);
  });

  testWidgets('登录后显示已登录，点一下退出登录', (tester) async {
    await pumpSettings(tester);

    final auth = Get.find<AuthController>();
    auth.session.value = const SessionInfo(
      user: AccountUser(loggedIn: true, name: 'tester'),
      authEnabled: true,
      registrationEnabled: true,
    );
    await tester.pumpAndSettle();
    expect(find.text('已登录'), findsOneWidget);

    await tester.tap(find.text('已登录'));
    await tester.pump();
    // 退出登录会弹一次提示，等它自己消失，别把定时器留在用例里。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('登录账号'), findsOneWidget);
  });
}
