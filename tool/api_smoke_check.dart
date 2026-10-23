// ignore_for_file: avoid_print

import 'package:asmr_two/core/api/api_client.dart';
import 'package:asmr_two/core/api/api_exception.dart';
import 'package:asmr_two/core/api/asmr_api.dart';

/// 对线上接口做一次冒烟检查。
///
/// 用法：`dart run tool/api_smoke_check.dart`
Future<void> main() async {
  final api = AsmrApi(ApiClient(tokenProvider: () => null));

  Future<void> run(String label, Future<Object?> Function() action) async {
    try {
      final result = await action();
      print('OK   $label -> $result');
    } on ApiException catch (e) {
      print('FAIL $label -> ${e.message} | raw=${e.rawError}');
    } catch (e) {
      print('ERR  $label -> $e');
    }
  }

  await run(
    'works',
    () async => (await api.fetchWorks(pageSize: 2)).works.length,
  );
  await run('work detail', () async => (await api.fetchWork(1712623)).title);
  await run('workInfo', () async => (await api.fetchWorkInfo(1712623)).title);
  await run('tracks', () async => (await api.fetchTracks(1712623)).length);
  await run(
    'search',
    () async =>
        (await api.searchWorks('ASMR', pageSize: 2)).pagination.totalCount,
  );
  await run('tags', () async => (await api.fetchTags()).length);
  await run('circles', () async => (await api.fetchCircles()).length);
  await run('voice actors', () async => (await api.fetchVoiceActors()).length);
  await run('tag detail', () async => (await api.fetchTag(509)).name);
  await run('circle detail', () async => (await api.fetchCircle(37739)).name);
  await run(
    'similar works',
    () async => (await api.fetchSimilarWorks(workId: 1712623)).works.length,
  );
  await run(
    'popular',
    () async => (await api.fetchPopular(pageSize: 2)).works.length,
  );
  await run('health', () async => api.checkHealth());
  await run('session', () async => (await api.fetchSession()).user.loggedIn);
}
