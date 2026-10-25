import 'package:dio/dio.dart';

import '../json/json_reader.dart';
import 'api_exception.dart';

/// asmr.one 的可用线路。
///
/// 官网前端会在这些镜像之间切换，接口地址相同的线路，
/// 只是在部分地区或运营商下可用性不同。
class ApiHosts {
  const ApiHosts._();

  /// 线路列表，顺序与官网一致，第一条为默认线路。
  static const List<String> all = [
    'https://api.asmr-200.com',
    'https://api.asmr.one',
    'https://api.asmr-100.com',
    'https://api.asmr-300.com',
  ];

  /// 官网主域，用于生成 Referer 与分享链接。
  static const String site = 'https://asmr.one';
}

/// 提供当前登录令牌的回调。
typedef TokenProvider = String? Function();

/// 接口传输层。
///
/// 负责线路故障转移、鉴权头注入与错误归一化，
/// 不关心具体接口的语义。
class ApiClient {
  ApiClient({required this.tokenProvider, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'ASMROneClient/1.0 (Flutter)',
      }
      // 交由业务层统一判断状态码，避免非 2xx 抛出裸异常。
      ..validateStatus = (code) => code != null && code >= 200 && code < 400;
  }

  final Dio _dio;

  /// 提供当前登录令牌的回调。
  final TokenProvider tokenProvider;

  int _hostIndex = 0;

  /// 手动指定的线路下标，null 表示自动选择。
  int? pinnedHostIndex;

  /// 当前生效的线路地址。
  String get baseUrl => ApiHosts.all[_hostIndex % ApiHosts.all.length];

  /// 当前线路的主机名。
  String get baseUrlHost => Uri.parse(baseUrl).host;

  /// 当前登录令牌。
  String? get token => tokenProvider();

  bool get hasToken => (token ?? '').isNotEmpty;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
  }) => _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('POST', path, body: body, query: query, auth: auth);

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('PUT', path, body: body, query: query, auth: auth);

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('DELETE', path, body: body, query: query, auth: auth);

  /// 拉取二进制内容（字幕、台本等）。
  ///
  /// [path] 可以是接口路径，也可以是字幕节点给出的 CDN 绝对地址。
  Future<List<int>> getBytes(String path) async {
    Object? lastError;
    final startIndex = pinnedHostIndex ?? _hostIndex;

    for (var attempt = 0; attempt < 3; attempt++) {
      final index = (startIndex + attempt) % ApiHosts.all.length;
      _hostIndex = index;
      final uri = Uri.tryParse(path);
      final url = uri != null && uri.hasScheme
          ? path
          : '${ApiHosts.all[index]}$path';

      try {
        final response = await _dio.get<List<int>>(
          url,
          options: Options(
            headers: _headers(false),
            responseType: ResponseType.bytes,
          ),
        );
        final code = response.statusCode ?? 0;
        if (code >= 200 && code < 300) {
          return response.data ?? const <int>[];
        }
        throw ApiException('请求失败（HTTP $code）', statusCode: code);
      } on DioException catch (error) {
        lastError = error;
        if (_isRetryable(error) && attempt < 2) {
          continue; // 换下一条线路
        }
        throw _toApiException(error);
      }
    }
    throw ApiException('网络请求失败，请检查网络连接后再试。', rawError: lastError?.toString());
  }

  /// 发送请求，失败时按顺序切换线路重试。
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    required bool auth,
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    final startIndex = pinnedHostIndex ?? _hostIndex;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final index = (startIndex + attempt) % ApiHosts.all.length;
      _hostIndex = index;
      try {
        final response = await _dio.request<dynamic>(
          '${ApiHosts.all[index]}$path',
          data: body,
          queryParameters: query,
          options: Options(
            method: method,
            headers: _headers(auth),
            responseType: ResponseType.json,
          ),
        );
        return _unwrap(response);
      } on DioException catch (error) {
        lastError = error;
        if (_isRetryable(error) && attempt < maxAttempts - 1) {
          continue; // 换下一条线路
        }
        throw _toApiException(error);
      }
    }
    throw ApiException('网络请求失败，请检查网络连接后再试。', rawError: lastError?.toString());
  }

  Map<String, String> _headers(bool auth) {
    final current = token;
    return {
      if (auth && current != null && current.isNotEmpty)
        'Authorization': 'Bearer $current',
      'Referer': '${ApiHosts.site}/',
    };
  }

  /// 线路级错误（连接失败、超时、5xx）值得换一条线路重试。
  bool _isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
        return false;
    }
  }

  dynamic _unwrap(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) return response.data;

    final body = Json.map(response.data);
    final raw = Json.stringOrNull(body['error']);
    throw ApiException(
      _humanize(raw) ?? '请求失败（HTTP $code）',
      statusCode: code,
      rawError: raw,
    );
  }

  ApiException _toApiException(DioException error) {
    final body = Json.map(error.response?.data);
    final raw = Json.stringOrNull(body['error']);
    final code = error.response?.statusCode;
    final message =
        _humanize(raw) ??
        switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout => '连接超时，请稍后重试。',
          DioExceptionType.connectionError => '无法连接到服务器，请检查网络或切换线路。',
          DioExceptionType.cancel => '请求已取消。',
          DioExceptionType.badCertificate => '服务器证书无效。',
          DioExceptionType.badResponse => '请求失败（HTTP ${code ?? 0}）。',
          DioExceptionType.transformTimeout => '响应解析超时，请稍后重试。',
          DioExceptionType.unknown =>
            '网络异常：${error.message ?? error.error?.toString() ?? '未知错误'}',
        };
    return ApiException(message, statusCode: code, rawError: raw);
  }

  /// 把服务端返回的英文错误转成可展示文案。
  String? _humanize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    if (lower.contains('authorization token') || lower.contains('jwt')) {
      return '需要登录后才能使用该功能，请先登录账号。';
    }
    if (lower.contains('unauthorized')) return '登录状态已过期，请重新登录。';
    if (lower.contains('not found')) return '内容不存在或已被删除。';
    if (lower.contains('too many')) return '请求过于频繁，请稍后再试。';
    if (lower.contains('invalid value')) return '请求参数不被服务端接受。';
    return raw;
  }
}
