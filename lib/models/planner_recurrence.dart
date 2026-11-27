class PlannerRecurrence {
  static List<DateTime> occurrences({required DateTime startsAt, required String? rule, required DateTime from, required DateTime to, int limit = 100}) {
    final result = <DateTime>[];
    if (to.isBefore(from)) return result;
    var current = startsAt;
    var monthStep = 0;
    DateTime advance() {
      if (rule == 'monthly') {
        monthStep++;
        final first = DateTime(startsAt.year, startsAt.month + monthStep, 1);
        final lastDay = DateTime(first.year, first.month + 1, 0).day;
        return DateTime(first.year, first.month, startsAt.day > lastDay ? lastDay : startsAt.day, startsAt.hour, startsAt.minute);
      }
      return _next(current, rule ?? 'none');
    }
    if (rule == null || rule.isEmpty || rule == 'none') {
      if (!current.isBefore(from) && current.isBefore(to)) result.add(current);
      return result;
    }
    var safety = 0;
    while (current.isBefore(from) && safety++ < 20000) { current = advance(); }
    while (!current.isBefore(from) && current.isBefore(to) && result.length < limit && safety++ < 20000) {
      result.add(current);
      current = advance();
    }
    return result;
  }
  static DateTime _next(DateTime value, String rule) {
    if (rule == 'daily') return value.add(const Duration(days: 1));
    if (rule == 'weekly') return value.add(const Duration(days: 7));
    if (rule == 'monthly') {
      final first = DateTime(value.year, value.month + 1, 1);
      final lastDay = DateTime(first.year, first.month + 1, 0).day;
      return DateTime(first.year, first.month, value.day > lastDay ? lastDay : value.day, value.hour, value.minute);
    }
    return DateTime(2100);
  }
}
