/// 假接口用的示例播放列表。
const String mockPlaylistCoverUrl = 'https://cmach.ccwu.cc/4.png';

/// 播放列表列表响应。
Map<String, dynamic> playlistsResponse() => {
  'playlists': [
    {
      'id': 'uuid-1',
      'name': '默认收藏',
      'privacy': 2,
      'works_count': 3,
      'user_name': 'tester',
      'mainCoverUrl': mockPlaylistCoverUrl,
    },
    {
      'id': 'uuid-2',
      'name': '__SYS_PLAYLIST_LIKED',
      'privacy': 0,
      'works_count': 5,
    },
  ],
  'pagination': {'currentPage': 1, 'pageSize': 12, 'totalCount': 2},
};
