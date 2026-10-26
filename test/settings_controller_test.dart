import 'dart:io';

import 'package:asmr_two/core/api/asmr_api.dart';
import 'package:asmr_two/core/storage/session_store.dart';
import 'package:asmr_two/state/auth_controller.dart';
import 'package:asmr_two/state/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
    final (client, _) = buildClient((options) async => jsonBody({}));
    Get.put<AsmrApi>(AsmrApi(client));
    Get.put<SessionStore>(SessionStore(prefs));
    auth = Get.put(
      AuthController(
        api: Get.find<AsmrApi>(),
        sessionStore: Get.find<SessionStore>(),
      ),
    );
  });

  tearDown(() async {
    Get.reset();
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
  });

  test('默认关闭窗口就退出应用', () {
    final settings = SettingsController(auth: auth);
    settings.onInit();

    expect(settings.exitToTray.value, isFalse);
  });

  test('退出到托盘的开关会写进本地存储', () async {
    final settings = SettingsController(auth: auth);
    settings.onInit();

    await settings.setExitToTray(true);
    expect(settings.exitToTray.value, isTrue);
    expect(GetStorage().read<bool>('exit_to_tray_v1'), isTrue);
  });

  test('重新打开应用会读回上次的选择', () async {
    final settings = SettingsController(auth: auth);
    settings.onInit();
    await settings.setExitToTray(true);

    final restored = SettingsController(auth: auth);
    restored.onInit();
    expect(restored.exitToTray.value, isTrue);
  });
}
