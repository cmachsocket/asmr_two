import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// 把 path_provider 指向临时目录，让 GetStorage 在测试里能读写文件。
class FakePathProvider extends PathProviderPlatform {
  FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() => Future.value(root);
}

/// 初始化可用的 GetStorage，返回存放数据的临时目录。
///
/// GetStorage 是按容器名缓存的单例，重复调用 [GetStorage.init] 不会再读盘，
/// 所以每个用例前用 [GetStorage.erase] 清掉上一个用例留下的内容。
Future<Directory> initFakeStorage() async {
  final dir = await Directory.systemTemp.createTemp('asmr_two_storage');
  PathProviderPlatform.instance = FakePathProvider(dir.path);
  await GetStorage.init();
  await GetStorage().erase();
  return dir;
}
