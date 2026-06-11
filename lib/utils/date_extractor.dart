import 'package:intl/intl.dart';

/// 日期提取工具
class DateExtractor {
  /// 从文件名提取日期
  /// 支持格式: IMG_20240101_120000, 2024-01-01, 20240101 等
  static DateTime? fromFilename(String filename) {
    // IMG_YYYYMMDD_HHMMSS
    final imgPattern = RegExp(r'IMG[_-](\d{4})(\d{2})(\d{2})');
    final match1 = imgPattern.firstMatch(filename);
    if (match1 != null) {
      return DateTime(
        int.parse(match1.group(1)!),
        int.parse(match1.group(2)!),
        int.parse(match1.group(3)!),
      );
    }

    // YYYY-MM-DD
    final datePattern = RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})');
    final match2 = datePattern.firstMatch(filename);
    if (match2 != null) {
      return DateTime(
        int.parse(match2.group(1)!),
        int.parse(match2.group(2)!),
        int.parse(match2.group(3)!),
      );
    }

    // YYYYMMDD
    final compactPattern = RegExp(r'(\d{8})');
    final match3 = compactPattern.firstMatch(filename);
    if (match3 != null) {
      final dateStr = match3.group(1)!;
      return DateTime(
        int.parse(dateStr.substring(0, 4)),
        int.parse(dateStr.substring(4, 6)),
        int.parse(dateStr.substring(6, 8)),
      );
    }

    return null;
  }

  /// 按年份分组照片
  static Map<int, List<T>> groupByYear<T>(
    List<T> photos,
    DateTime? Function(T) getDate,
  ) {
    final groups = <int, List<T>>{};
    for (final photo in photos) {
      final date = getDate(photo);
      final year = date?.year ?? DateTime.now().year;
      groups.putIfAbsent(year, () => []).add(photo);
    }
    return groups;
  }

  /// 按月份分组照片
  static Map<String, List<T>> groupByMonth<T>(
    List<T> photos,
    DateTime? Function(T) getDate,
  ) {
    final groups = <String, List<T>>{};
    for (final photo in photos) {
      final date = getDate(photo);
      if (date == null) continue;
      final key = DateFormat('yyyy-MM').format(date);
      groups.putIfAbsent(key, () => []).add(photo);
    }
    return groups;
  }

  /// 格式化日期
  static String formatDate(DateTime date, {String format = 'yyyy年M月d日'}) {
    return DateFormat(format).format(date);
  }

  /// 获取中文月份名
  static String monthName(int month) {
    const names = [
      '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月',
    ];
    return month >= 1 && month <= 12 ? names[month - 1] : '';
  }
}
