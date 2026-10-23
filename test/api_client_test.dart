import 'package:asmr_two/core/api/api_client.dart';
import 'package:asmr_two/core/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_adapter.dart';

void main() {
  group('ApiClient 线路故障转移', () {
    test('当前线路连接失败时自动切到下一条线路', () async {
      final (client, adapter) = buildClient((options) async {
        if (options.uri.host == Uri.parse(ApiHosts.all.first).host) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: '线路不可达',
          );
        }
        return jsonBody({'ok': true});
      });

      final result = await client.get('/api/health');

      expect(result, {'ok': true});
      expect(adapter.requests.length, 2);
      expect(
        adapter.requests.first.uri.host,
        Uri.parse(ApiHosts.all.first).host,
      );
      expect(adapter.requests.last.uri.host, Uri.parse(ApiHosts.all[1]).host);
    });

    test('线路恢复后后续请求沿用可用线路', () async {
      final (client, adapter) = buildClient((options) async {
        if (options.uri.host == Uri.parse(ApiHosts.all.first).host) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: '线路不可达',
          );
        }
        return jsonBody({'ok': true});
      });

      await client.get('/api/health');
      final hosts = adapter.requests.map((r) => r.uri.host).toList();

      expect(hosts, [
        Uri.parse(ApiHosts.all.first).host,
        Uri.parse(ApiHosts.all[1]).host,
      ]);
      expect(client.baseUrlHost, Uri.parse(ApiHosts.all[1]).host);
    });
  });

  group('ApiClient 错误处理', () {
    test('鉴权失败抛出可识别的异常', () async {
      final (client, _) = buildClient(
        (options) async => errorBody(
          statusCode: 401,
          message: 'No authorization token was found',
        ),
      );

      await expectLater(
        client.get('/api/tags/', auth: true),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('服务端错误文案会被转成中文提示', () async {
      final (client, _) = buildClient(
        (options) async => errorBody(statusCode: 404, message: 'Not Found'),
      );

      await expectLater(
        client.get('/api/work/1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            '内容不存在或已被删除。',
          ),
        ),
      );
    });

    test('参数非法时给出通用提示', () async {
      final (client, _) = buildClient(
        (options) async => errorBody(statusCode: 400, message: 'Invalid value'),
      );

      await expectLater(
        client.post('/api/review'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            '请求参数不被服务端接受。',
          ),
        ),
      );
    });
  });

  group('ApiClient 鉴权头', () {
    test('带令牌的请求会附加 Bearer 头', () async {
      final adapter = FakeAdapter((options) async => jsonBody({'ok': true}));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = ApiClient(tokenProvider: () => 'jwt-token', dio: dio);

      await client.get('/api/auth/me', auth: true);

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer jwt-token',
      );
    });

    test('未带令牌的请求不会附加 Authorization 头', () async {
      final adapter = FakeAdapter((options) async => jsonBody({'ok': true}));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = ApiClient(tokenProvider: () => 'jwt-token', dio: dio);

      await client.get('/api/works');

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });
}
