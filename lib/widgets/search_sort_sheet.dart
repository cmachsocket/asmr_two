import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/search_controller.dart';
import '../core/models/work.dart';

/// 排序面板。
class SearchSortSheet extends GetView<SearchScreenController> {
  const SearchSortSheet({super.key});

  /// 可选的排序字段。
  static const List<(WorkOrder, String)> orders = [
    (WorkOrder.createDate, '入库时间'),
    (WorkOrder.release, '发售时间'),
    (WorkOrder.dlCount, '下载量'),
    (WorkOrder.rateAverage, '评分'),
    (WorkOrder.reviewCount, '评论数'),
    (WorkOrder.price, '价格'),
    (WorkOrder.id, '编号'),
  ];

  /// 可选的排序方向。
  static const List<(SortDirection, String)> directions = [
    (SortDirection.desc, '降序'),
    (SortDirection.asc, '升序'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('排序方式')),
          Obx(
            () => Column(
              children: [
                for (final (order, label) in orders)
                  ListTile(
                    title: Text(label),
                    trailing: controller.order.value == order
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => controller.changeOrder(order),
                  ),
              ],
            ),
          ),
          const Divider(),
          const ListTile(title: Text('排序方向')),
          Obx(
            () => Column(
              children: [
                for (final (direction, label) in directions)
                  ListTile(
                    title: Text(label),
                    trailing: controller.sort.value == direction
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => controller.changeSort(direction),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
