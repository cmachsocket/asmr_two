import '../json/json_reader.dart';

/// 当前登录用户。
///
/// 未登录时接口返回 `{loggedIn: false}`。
class AccountUser {
  const AccountUser({
    required this.loggedIn,
    this.id,
    this.name,
    this.email,
    this.group,
    this.recommenderUuid,
  });

  final bool loggedIn;
  final String? id;
  final String? name;
  final String? email;

  /// 用户组，例如 `user` / `admin`。
  final String? group;

  /// 推荐系统的用户标识，上报浏览反馈时使用。
  final String? recommenderUuid;

  static const anonymous = AccountUser(loggedIn: false);

  String get displayName => name ?? '未登录';

  factory AccountUser.fromJson(Map<String, dynamic> json) => AccountUser(
    loggedIn: Json.boolean(json['loggedIn'], fallback: true),
    id: Json.stringOrNull(json['id']),
    name: Json.stringOrNull(json['name']),
    email: Json.stringOrNull(json['email']),
    group: Json.stringOrNull(json['group']),
    recommenderUuid: Json.stringOrNull(json['recommenderUuid']),
  );
}

/// `/api/auth/me` 的完整响应：用户信息加服务端能力开关。
class SessionInfo {
  const SessionInfo({
    required this.user,
    required this.authEnabled,
    required this.registrationEnabled,
  });

  final AccountUser user;

  /// 服务端是否开启登录。
  final bool authEnabled;

  /// 服务端是否开启注册。
  final bool registrationEnabled;

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
    user: AccountUser.fromJson(Json.map(json['user'])),
    authEnabled: Json.boolean(json['auth'], fallback: true),
    registrationEnabled: Json.boolean(json['reg'], fallback: true),
  );

  static const anonymous = SessionInfo(
    user: AccountUser.anonymous,
    authEnabled: true,
    registrationEnabled: true,
  );
}

/// 登录或注册成功后返回的凭据。
class AuthToken {
  const AuthToken({
    required this.token,
    required this.user,
    this.recommenderUuid,
  });

  /// JWT 令牌。
  final String token;

  final AccountUser user;
  final String? recommenderUuid;

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
    token: Json.string(json['token']),
    user: AccountUser.fromJson(Json.map(json['user'])),
    recommenderUuid: Json.stringOrNull(
      json['user'] is Map ? Json.map(json['user'])['recommenderUuid'] : null,
    ),
  );
}
