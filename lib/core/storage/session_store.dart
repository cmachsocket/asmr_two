import 'package:shared_preferences/shared_preferences.dart';

/// 本地会话存储，负责保存登录令牌与线路偏好。
class SessionStore {
  SessionStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _tokenKey = 'jwt-token';
  static const String _lineKey = 'api-line-index';

  /// 读取已保存的登录令牌。
  String? get token {
    final value = _prefs.getString(_tokenKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool get hasToken => token != null;

  /// 保存登录令牌。
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// 清除登录令牌。
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  /// 手动指定的线路下标，null 表示自动选择。
  int? get pinnedLineIndex => _prefs.getInt(_lineKey);

  /// 保存手动指定的线路下标，传 null 表示恢复自动选择。
  Future<void> savePinnedLineIndex(int? index) async {
    if (index == null) {
      await _prefs.remove(_lineKey);
      return;
    }
    await _prefs.setInt(_lineKey, index);
  }
}
