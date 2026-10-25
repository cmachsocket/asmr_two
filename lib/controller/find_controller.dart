import 'package:get/get.dart';

import '../core/models/work.dart';

/// 发现页控制器。
///
/// 目前只提供示例数据，接口接入后换成真实列表。
class DiscoverController extends GetxController {
  /// 作品列表，接口接入后由接口数据替换。
  final RxList<Work> _works = mockWorks.obs;

  /// 页面展示的作品。
  ///
  /// 读取列表会注册 Obx 监听，直接把 [RxList] 传给界面不会触发刷新。
  List<Work> get works => _works.toList();

  /// 示例作品：20 条，标题长度与标签数量不一，用于查看瀑布流的排布效果。
  static final List<Work> mockWorks = [
    _work(id: 1, title: '雨夜耳语', tags: []),
    _work(id: 2, title: 'ASMR 耳语合集', tags: ['ASMR', '耳语']),
    _work(id: 3, title: 'Beginners guide to sleep', tags: ['治愈', '放松']),
    _work(
      id: 4,
      title: '耳ほじ と くすぐり masters collection',
      tags: ['ASMR', '耳ほじ', '日语'],
    ),
    _work(id: 5, title: '深夜的厨房', tags: ['环境音', '雨声', 'ASMR', '耳语', '放松']),
    _work(id: 6, title: '早安', tags: ['ASMR']),
    _work(
      id: 7,
      title: 'A Very Long Work Title That Should Wrap Onto Another Line',
      tags: ['ASMR', '耳语', '环境音'],
    ),
    _work(id: 8, title: '猫と猫', tags: ['动物', '治愈'], duration: 92),
    _work(id: 9, title: '图书馆', tags: ['环境音', '翻书', '白噪音'], duration: 5430),
    _work(id: 10, title: '笔尖', tags: ['ASMR', '写字', '笔音']),
    _work(id: 11, title: '泡沫音', tags: ['ASMR', '水音', '耳语', '放松', '治愈', '清洁']),
    _work(id: 12, title: '心跳', tags: []),
    _work(id: 13, title: 'そっと囁く', tags: ['耳语', '日语']),
    _work(
      id: 14,
      title: '雨天列车',
      tags: ['环境音', '雨声', '列车', '放松'],
      duration: 3600,
    ),
    _work(id: 15, title: '敲击', tags: ['ASMR', '敲击']),
    _work(id: 16, title: '深夜のlantenn 灯', tags: ['ASMR', '日语', '环境音', '夜']),
    _work(id: 17, title: '棉花糖', tags: ['甜食', 'ASMR', '咀嚼']),
    _work(id: 18, title: '风', tags: ['环境音', '白噪音', '放松', '治愈'], duration: 725),
    _work(id: 19, title: '指尖', tags: ['ASMR', '触摸']),
    _work(
      id: 20,
      title: '長いタイトルテスト長いタイトルテスト長いタイトルテスト',
      tags: ['ASMR', '耳语', '环境音', '日语', '放松'],
    ),
  ];
}

/// 示例封面图地址。
const String _coverUrl = 'https://cmach.ccwu.cc/4.png';

/// 构造一条示例作品。
Work _work({
  required int id,
  required String title,
  required List<String> tags,
  int? duration,
}) => Work(
  id: id,
  title: title,
  circleId: 1,
  circleName: '示例社团',
  nsfw: false,
  release: '2026-01-01',
  dlCount: 0,
  price: 0,
  reviewCount: 0,
  rateCount: 0,
  rateAverage: 0,
  duration: duration,
  tags: [for (var i = 0; i < tags.length; i++) Tag(id: i + 1, name: tags[i])],
  mainCoverUrl: _coverUrl,
);
