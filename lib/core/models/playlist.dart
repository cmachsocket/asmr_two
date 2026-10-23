import '../json/json_reader.dart';
import 'pagination.dart';

/// 播放列表可见性，对应接口的 `privacy` 字段（整数）。
enum PlaylistPrivacy {
  /// 仅自己可见。
  private(0),

  /// 登录用户可见。
  known(1),

  /// 公开。
  public(2);

  const PlaylistPrivacy(this.value);

  final int value;

  static PlaylistPrivacy fromValue(dynamic value) {
    final code = Json.integer(value);
    for (final privacy in PlaylistPrivacy.values) {
      if (privacy.value == code) return privacy;
    }
    return PlaylistPrivacy.private;
  }
}

/// 云端播放列表。
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.description = '',
    this.privacy = PlaylistPrivacy.private,
    this.locale = '',
    this.userName = '',
    this.worksCount = 0,
    this.likedCount = 0,
    this.playbackCount = 0,
    this.createdAt,
    this.updatedAt,
    this.exist = false,
  });

  /// 列表 id 为 UUID 字符串。
  final String id;

  final String name;
  final String description;
  final PlaylistPrivacy privacy;

  /// 列表语言标记。
  final String locale;

  final String userName;

  /// 列表内作品数量。
  final int worksCount;

  final int likedCount;
  final int playbackCount;
  final String? createdAt;
  final String? updatedAt;

  /// 该作品是否已在此列表中（仅收藏状态接口返回）。
  final bool exist;

  /// 是否为系统内置列表。
  bool get isSystem => name.startsWith(_systemPrefix);

  static const _systemPrefix = '__SYS_PLAYLIST_';

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: Json.string(json['id']),
    name: Json.string(json['name']),
    description: Json.string(json['description']),
    privacy: PlaylistPrivacy.fromValue(json['privacy']),
    locale: Json.string(json['locale']),
    userName: Json.string(json['user_name']),
    worksCount: Json.integer(json['works_count']),
    likedCount: Json.integer(json['liked_count']),
    playbackCount: Json.integer(json['playback_count']),
    createdAt: Json.stringOrNull(json['created_at']),
    updatedAt: Json.stringOrNull(json['updated_at']),
    exist: Json.boolean(json['exist']),
  );
}

/// 我的播放列表（含收藏状态）。
class PlaylistListPage {
  const PlaylistListPage({required this.playlists, required this.pagination});

  final List<Playlist> playlists;
  final Pagination pagination;

  factory PlaylistListPage.fromJson(Map<String, dynamic> json) {
    final playlists = Json.list(json['playlists'], Playlist.fromJson);
    return PlaylistListPage(
      playlists: playlists,
      pagination: Pagination.fromJson(json, itemCount: playlists.length),
    );
  }
}
