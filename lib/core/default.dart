import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

@sealed
class DefaultValues {
  static const int shellNavigatorId = 1;
  static const int squardRadio = 1;
  static const double cardImageAspectRatio = 4 / 3;
  // 唯一的硬编码size
  static const EdgeInsets onlyZero = EdgeInsets.only(left: 0, right: 0);
}
