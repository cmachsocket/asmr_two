/// 宽松的 JSON 取值工具。
///
/// asmr.one 的接口在数值字段上会出现 int / double / String 混用
/// （例如 `rate_average_2dp` 可能是 `5` 也可能是 `4.69`），
/// 统一在这里做转换，业务代码不必再写类型判断。
library;

class Json {
  const Json._();

  /// 把任意值当作对象读取，无法解析时返回空对象。
  static Map<String, dynamic> map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  /// 把任意值当作对象数组读取。
  static List<Map<String, dynamic>> mapList(dynamic value) {
    if (value is! List) return const [];
    return value.map(map).where((item) => item.isNotEmpty).toList();
  }

  /// 把任意值当作对象数组读取并逐项解析。
  static List<T> list<T>(
    dynamic value,
    T Function(Map<String, dynamic> json) parse,
  ) {
    return mapList(value).map(parse).toList();
  }

  static String string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int integer(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? integerOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? numberOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool boolean(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }
    return fallback;
  }
}
