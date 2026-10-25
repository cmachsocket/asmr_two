/// 假接口用的示例作品。
///
/// 字段与接口返回结构一致，标题长度与标签数量不一，
/// 便于查看瀑布流的排布效果。
const String mockCoverUrl = 'https://cmach.ccwu.cc/4.png';

/// 示例作品列表。
List<Map<String, dynamic>> mockWorks() => [
  _work(1, '雨夜耳语', const []),
  _work(2, 'ASMR 耳语合集', const ['ASMR', '耳语']),
  _work(3, 'Beginners guide to sleep', const ['治愈', '放松']),
  _work(4, '耳ほじ と くすぐり masters collection', const ['ASMR', '耳ほじ', '日语']),
  _work(5, '深夜的厨房', const ['环境音', '雨声', 'ASMR', '耳语', '放松']),
  _work(6, '早安', const ['ASMR']),
  _work(7, 'A Very Long Work Title That Should Wrap Onto Another Line', const [
    'ASMR',
    '耳语',
    '环境音',
  ]),
  _work(8, '猫と猫', const ['动物', '治愈'], duration: 92),
  _work(9, '图书馆', const ['环境音', '翻书', '白噪音'], duration: 5430),
  _work(10, '笔尖', const ['ASMR', '写字', '笔音']),
  _work(11, '泡沫音', const ['ASMR', '水音', '耳语', '放松', '治愈', '清洁']),
  _work(12, '心跳', const []),
  _work(13, 'そっと囁く', const ['耳语', '日语']),
  _work(14, '雨天列车', const ['环境音', '雨声', '列车', '放松'], duration: 3600),
  _work(15, '敲击', const ['ASMR', '敲击']),
  _work(16, '深夜のlantenn 灯', const ['ASMR', '日语', '环境音', '夜']),
  _work(17, '棉花糖', const ['甜食', 'ASMR', '咀嚼']),
  _work(18, '风', const ['环境音', '白噪音', '放松', '治愈'], duration: 725),
  _work(19, '指尖', const ['ASMR', '触摸']),
  _work(20, '長いタイトルテスト長いタイトルテスト長いタイトルテスト', const [
    'ASMR',
    '耳语',
    '环境音',
    '日语',
    '放松',
  ]),
];

/// 作品列表响应。
Map<String, dynamic> worksResponse({
  int page = 1,
  int pageSize = 20,
  int totalCount = 100,
}) {
  return {
    'works': mockWorks(),
    'pagination': {
      'currentPage': page,
      'pageSize': pageSize,
      'totalCount': totalCount,
    },
  };
}

Map<String, dynamic> _work(
  int id,
  String title,
  List<String> tags, {
  int? duration,
}) {
  return {
    'id': id,
    'title': title,
    'circle_id': 1,
    'name': '示例社团',
    'nsfw': false,
    'release': '2026-01-01',
    'dl_count': 0,
    'price': 0,
    'review_count': 0,
    'rate_count': 0,
    'rate_average_2dp': 0,
    'duration': duration,
    'tags': [
      for (var i = 0; i < tags.length; i++) {'id': i + 1, 'name': tags[i]},
    ],
    'mainCoverUrl': mockCoverUrl,
  };
}
