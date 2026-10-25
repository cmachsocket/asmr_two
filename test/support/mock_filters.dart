/// 假接口用的标签与声优。
///
/// 字段与接口返回结构一致。
List<Map<String, dynamic>> mockTags() => [
  {
    'id': 497,
    'name': 'ASMR',
    'i18n': {
      'zh-cn': {'name': 'ASMR'},
      'ja-jp': {'name': 'ASMR'},
    },
    'count': 100,
  },
  {
    'id': 1,
    'name': '治愈',
    'i18n': {
      'zh-cn': {'name': '治愈'},
      'ja-jp': {'name': '癒し'},
    },
    'count': 50,
  },
  {
    'id': 2,
    'name': '测试标签',
    'i18n': {
      'zh-cn': {'name': '测试标签'},
    },
    'count': 10,
  },
];

/// 假接口用的声优。
List<Map<String, dynamic>> mockVoiceActors() => [
  {'id': 'va-1', 'name': '测试声优', 'count': 20},
  {'id': 'va-2', 'name': '야디', 'count': 1},
];
