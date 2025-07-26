class DateUtilHelper {
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static DateTime getCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }
}
