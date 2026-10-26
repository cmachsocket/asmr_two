import 'dart:io';

import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/default.dart';
import 'package:asmr_two/core/storage/session_store.dart';
import 'package:asmr_two/screens/login_screen.dart';
import 'package:asmr_two/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_adapter.dart';
import 'support/fake_storage.dart';

void main() {
  late Directory storageDir;
  late AuthController auth;

  setUp(() async {
    Get.testMode = true;
    storageDir = await initFakeStorage();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final (client, fake) = buildClient((options) async {
      if (options.method == 'POST') {
        return jsonBody({
          'token': 'test-token',
          'user': {'loggedIn': true, 'name': 'tester'},
        });
      }
      return jsonBody({
        'user': {'loggedIn': true, 'name': 'tester'},
        'auth': true,
        'reg': true,
      });
    });
    Get.put<AsmrApi>(AsmrApi(client));
    Get.put<SessionStore>(SessionStore(prefs));
    auth = Get.put(
      AuthController(
        api: Get.find<AsmrApi>(),
        sessionStore: Get.find<SessionStore>(),
      ),
    );
    expect(fake.requests, isEmpty);
  });

  tearDown(() async {
    Get.reset();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  /// 渲染登录页。
  ///
  /// 页面挂在跟首页外壳同款的嵌套导航器上，Get.back(id:) 才找得到路由。
  Future<void> pumpLogin(WidgetTester tester) async {
    final key = Get.nestedKey(DefaultValues.shellNavigatorId);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Navigator(
            key: key,
            initialRoute: '/',
            onGenerateRoute: (settings) => settings.name == '/'
                ? GetPageRoute(
                    page: () => const LoginScreen(),
                    binding: LoginScreenBinding(),
                  )
                : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('登录页有账号与密码两个输入框', (tester) async {
    await pumpLogin(tester);

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('登录'), findsWidgets);
  });

  testWidgets('没填完账号密码时登录按钮不可点', (tester) async {
    await pumpLogin(tester);

    ElevatedButton button() =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'tester');
    await tester.pumpAndSettle();
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pumpAndSettle();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('登录成功后保存令牌', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField).first, 'tester');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    // 登录成功会弹一次提示，等它自己消失，别把定时器留在用例里。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(auth.isLoggedIn, isTrue);
    expect(Get.find<SessionStore>().token, 'test-token');
  });
}
