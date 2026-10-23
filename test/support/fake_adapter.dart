import 'dart:convert';
import 'dart:typed_data';

import 'package:asmr_two/core/api/api_client.dart';
import 'package:dio/dio.dart';

/// 可编程的假适配器，用来在测试里模拟各条线路的响应。
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  /// 根据请求决定响应。
  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// 记录收到的请求，便于断言。
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }
}

/// 构造一个 JSON 响应体。
ResponseBody jsonBody(
  Object? data, {
  int statusCode = 200,
  Map<String, List<String>>? headers,
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers:
        headers ??
        const {
          'content-type': ['application/json'],
        },
  );
}

/// 构造一个请求失败的响应体（模拟线路不可达）。
ResponseBody errorBody({int statusCode = 500, String message = 'boom'}) {
  return ResponseBody.fromString(
    jsonEncode({'error': message}),
    statusCode,
    headers: const {
      'content-type': ['application/json'],
    },
  );
}

/// 创建接入了假适配器的客户端。
(ApiClient, FakeAdapter) buildClient(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final adapter = FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  return (ApiClient(tokenProvider: () => null, dio: dio), adapter);
}
