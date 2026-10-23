/// 接口调用失败时抛出的异常，附带可展示文案与原始错误。
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.rawError});

  final String message;

  /// HTTP 状态码，网络层错误时为 null。
  final int? statusCode;

  /// 服务端返回的原始错误文案。
  final String? rawError;

  /// 是否为鉴权失败（需要登录或登录已过期）。
  bool get isUnauthorized {
    if (statusCode == 401) return true;
    final raw = (rawError ?? '').toLowerCase();
    return raw.contains('authorization token') || raw.contains('unauthorized');
  }

  @override
  String toString() => message;
}
