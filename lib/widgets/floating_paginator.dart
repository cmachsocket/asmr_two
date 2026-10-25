import "package:flutter/material.dart";
import 'package:number_paginator/number_paginator.dart';

/// 悬浮分页按钮，点击后弹出页码选择器。
///
/// 页码对外从 1 开始，与接口分页一致；
/// `number_paginator` 内部从 0 开始，转换在此处完成。
class FloatingPaginator extends StatelessWidget {
  const FloatingPaginator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.onPageChange,
  });

  /// 总页数。
  final int pageCount;

  /// 当前页码，从 1 开始。
  final int currentPage;

  /// 页码变化回调，参数为从 1 开始的页码。
  final ValueChanged<int> onPageChange;

  @override
  Widget build(BuildContext context) {
    final pages = pageCount < 1 ? 1 : pageCount;
    final page = currentPage.clamp(1, pages);
    return IconButton(
      tooltip: '第 $page / $pages 页',
      onPressed: pages > 1
          ? () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return NumberPaginator(
                    numberPages: pages,
                    initialPage: page - 1,
                    onPageChange: (index) => onPageChange(index + 1),
                  );
                },
              );
            }
          : null,
      icon: Icon(Icons.pages),
    );
  }
}
