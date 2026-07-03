// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';

/// Date pattern constants.
class GchDatePatterns {
  GchDatePatterns._();

  static const String iso8601 = 'yyyy-MM-ddTHH:mm:ss';
  static const String iso8601Z = 'yyyy-MM-ddTHH:mm:ssZ';
  static const String isoDate = 'yyyy-MM-dd';
  static const String isoTime = 'HH:mm:ss';
  static const String isoDateTime = 'yyyy-MM-dd HH:mm:ss';
  static const String usDate = 'MM/dd/yyyy';
  static const String usDateTime = 'MM/dd/yyyy hh:mm a';
  static const String euDate = 'dd.MM.yyyy';
  static const String euDateTime = 'dd.MM.yyyy HH:mm';
  static const String cnDate = 'yyyy年MM月dd日';
  static const String cnDateTime = 'yyyy年MM月dd日 HH时mm分ss秒';
  static const String rfcDate = 'EEE, dd MMM yyyy HH:mm:ss';
  static const String shortDate = 'MMM d, yyyy';
  static const String shortDateTime = 'MMM d, yyyy h:mm a';
  static const String longDate = 'MMMM d, yyyy';
  static const String longDateTime = 'MMMM d, yyyy h:mm:ss a';
  static const String timeOnly = 'HH:mm';
  static const String timeWithSeconds = 'HH:mm:ss';
  static const String time12h = 'hh:mm a';
  static const String monthYear = 'MMMM yyyy';
  static const String yearMonth = 'yyyy-MM';
  static const String dayMonth = 'dd MMM';
  static const String weekdayDate = 'EEEE, MMMM d';
  static const String compactDate = 'yyyyMMdd';
  static const String compactDateTime = 'yyyyMMddHHmmss';
  static const String slashDate = 'dd/MM/yyyy';
  static const String dotDate = 'dd.MM.yy';
  static const String quarterYear = 'Q yyyy';
  static const String weekYear = 'Www yyyy';
  static const String julianDay = 'DDD yyyy';
}

/// Comprehensive date/time utility class.
class GchDateUtil {
  GchDateUtil._();

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const List<String> _shortWeekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// Formats a [DateTime] using a pattern string.
  /// Supports: yyyy, yy, MM, M, dd, d, HH, H, hh, h, mm, m, ss, s,
  ///           a (AM/PM), EEEE, EEE, E, MMMM, MMM, Q, W, DDD.
  static String format(DateTime dt, String pattern) {
    String result = pattern;

    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final weekdayIdx = dt.weekday - 1; // weekday: 1=Mon, 7=Sun
    final monthIdx = dt.month - 1;
    final week = weekOfYear(dt);
    final quarter = quarterOfYear(dt);
    final dayOfYear = dt.difference(DateTime(dt.year, 1, 1)).inDays + 1;

    result = result.replaceAll('yyyy', dt.year.toString().padLeft(4, '0'));
    result = result.replaceAll('yy', (dt.year % 100).toString().padLeft(2, '0'));
    result = result.replaceAll('MMMM', _monthNames[monthIdx]);
    result = result.replaceAll('MMM', _shortMonthNames[monthIdx]);
    result = result.replaceAll('MM', dt.month.toString().padLeft(2, '0'));
    result = result.replaceAll('M', dt.month.toString());
    result = result.replaceAll('dd', dt.day.toString().padLeft(2, '0'));
    result = result.replaceAll('d', dt.day.toString());
    result = result.replaceAll('EEEE', _weekdayNames[weekdayIdx]);
    result = result.replaceAll('EEE', _shortWeekdayNames[weekdayIdx]);
    result = result.replaceAll('E', _shortWeekdayNames[weekdayIdx].substring(0, 2));
    result = result.replaceAll('HH', dt.hour.toString().padLeft(2, '0'));
    result = result.replaceAll('H', dt.hour.toString());
    result = result.replaceAll('hh', hour12.toString().padLeft(2, '0'));
    result = result.replaceAll('h', hour12.toString());
    result = result.replaceAll('mm', dt.minute.toString().padLeft(2, '0'));
    result = result.replaceAll('ss', dt.second.toString().padLeft(2, '0'));
    result = result.replaceAll('a', ampm);
    result = result.replaceAll('Q', quarter.toString());
    result = result.replaceAll('W', week.toString().padLeft(2, '0'));
    result = result.replaceAll('DDD', dayOfYear.toString().padLeft(3, '0'));

    return result;
  }

  /// Parses a date string according to a pattern.
  static DateTime? parse(String s, String pattern) {
    try {
      int? year, month, day, hour, minute, second;
      year = month = day = hour = minute = second = 0;
      month = 1;
      day = 1;

      final patternParts = <String, int>{};

      int getPos(String token) => pattern.indexOf(token);

      if (pattern.contains('yyyy')) {
        final pos = getPos('yyyy');
        year = int.tryParse(s.substring(pos, pos + 4));
      } else if (pattern.contains('yy')) {
        final pos = getPos('yy');
        final y = int.tryParse(s.substring(pos, pos + 2));
        year = y != null ? (y >= 70 ? 1900 + y : 2000 + y) : null;
      }

      if (pattern.contains('MM')) {
        final pos = getPos('MM');
        month = int.tryParse(s.substring(pos, pos + 2));
      }
      if (pattern.contains('dd')) {
        final pos = getPos('dd');
        day = int.tryParse(s.substring(pos, pos + 2));
      }
      if (pattern.contains('HH')) {
        final pos = getPos('HH');
        hour = int.tryParse(s.substring(pos, pos + 2));
      }
      if (pattern.contains('mm')) {
        final pos = getPos('mm');
        minute = int.tryParse(s.substring(pos, pos + 2));
      }
      if (pattern.contains('ss')) {
        final pos = getPos('ss');
        second = int.tryParse(s.substring(pos, pos + 2));
      }

      if (year == null || month == null || day == null) return null;
      return DateTime(year, month, day, hour ?? 0, minute ?? 0, second ?? 0);
    } catch (_) {
      return null;
    }
  }

  /// Converts a Unix timestamp in milliseconds to [DateTime].
  static DateTime fromTimestamp(int ms) {
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Converts a [DateTime] to a Unix timestamp in milliseconds.
  static int toTimestamp(DateTime dt) {
    return dt.millisecondsSinceEpoch;
  }

  /// Returns midnight of the given date.
  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Returns the last moment of the given date.
  static DateTime endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
  }

  /// Returns the Monday of the week containing [dt].
  static DateTime startOfWeek(DateTime dt) {
    final offset = dt.weekday - DateTime.monday;
    return startOfDay(dt.subtract(Duration(days: offset)));
  }

  /// Returns the Sunday of the week containing [dt].
  static DateTime endOfWeek(DateTime dt) {
    final offset = DateTime.sunday - dt.weekday;
    return endOfDay(dt.add(Duration(days: offset)));
  }

  /// Returns the first day of the month.
  static DateTime startOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month, 1);
  }

  /// Returns the last moment of the month.
  static DateTime endOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month, daysInMonth(dt.year, dt.month), 23, 59, 59, 999);
  }

  /// Returns January 1st of the year.
  static DateTime startOfYear(DateTime dt) {
    return DateTime(dt.year, 1, 1);
  }

  /// Returns December 31st, last moment of the year.
  static DateTime endOfYear(DateTime dt) {
    return DateTime(dt.year, 12, 31, 23, 59, 59, 999);
  }

  /// Adds [days] calendar days, handling DST.
  static DateTime addDays(DateTime dt, int days) {
    return dt.add(Duration(days: days));
  }

  /// Adds [weeks] weeks.
  static DateTime addWeeks(DateTime dt, int weeks) {
    return dt.add(Duration(days: weeks * 7));
  }

  /// Adds [months] months, clamping to the last day of the target month.
  static DateTime addMonths(DateTime dt, int months) {
    int newYear = dt.year;
    int newMonth = dt.month + months;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    final maxDay = daysInMonth(newYear, newMonth);
    final newDay = dt.day > maxDay ? maxDay : dt.day;
    return DateTime(newYear, newMonth, newDay, dt.hour, dt.minute, dt.second, dt.millisecond);
  }

  /// Adds [years] years, clamping Feb 29 in non-leap years to Feb 28.
  static DateTime addYears(DateTime dt, int years) {
    final newYear = dt.year + years;
    final maxDay = daysInMonth(newYear, dt.month);
    final newDay = dt.day > maxDay ? maxDay : dt.day;
    return DateTime(newYear, dt.month, newDay, dt.hour, dt.minute, dt.second, dt.millisecond);
  }

  /// Returns number of calendar days between [a] and [b] (absolute).
  static int daysBetween(DateTime a, DateTime b) {
    final da = startOfDay(a);
    final db = startOfDay(b);
    return da.difference(db).inDays.abs();
  }

  /// Returns complete weeks between [a] and [b].
  static int weeksBetween(DateTime a, DateTime b) {
    return daysBetween(a, b) ~/ 7;
  }

  /// Returns complete months between [a] and [b].
  static int monthsBetween(DateTime a, DateTime b) {
    final earlier = a.isBefore(b) ? a : b;
    final later = a.isBefore(b) ? b : a;
    int months = (later.year - earlier.year) * 12 + (later.month - earlier.month);
    if (later.day < earlier.day) months--;
    return months;
  }

  /// Returns true if [dt] falls on a Saturday or Sunday.
  static bool isWeekend(DateTime dt) {
    return dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
  }

  /// Returns true if [dt] falls Monday through Friday.
  static bool isWeekday(DateTime dt) {
    return !isWeekend(dt);
  }

  /// Returns true if [year] is a leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Returns the number of days in the given month.
  static int daysInMonth(int year, int month) {
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return days[month];
  }

  /// Returns the ISO 8601 week number of the year.
  static int weekOfYear(DateTime dt) {
    final thursday = dt.add(Duration(days: DateTime.thursday - dt.weekday));
    final firstThursday = DateTime(thursday.year, 1, 1).add(
      Duration(days: (4 - DateTime(thursday.year, 1, 1).weekday + 7) % 7),
    );
    return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
  }

  /// Returns the quarter of the year (1-4).
  static int quarterOfYear(DateTime dt) {
    return ((dt.month - 1) ~/ 3) + 1;
  }

  /// Returns true if [dt] is today.
  static bool isToday(DateTime dt) {
    return isSameDay(dt, DateTime.now());
  }

  /// Returns true if [dt] is yesterday.
  static bool isYesterday(DateTime dt) {
    return isSameDay(dt, DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Returns true if [dt] is tomorrow.
  static bool isTomorrow(DateTime dt) {
    return isSameDay(dt, DateTime.now().add(const Duration(days: 1)));
  }

  /// Returns true if [a] and [b] represent the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns true if [a] and [b] are in the same year and month.
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Returns true if [a] and [b] are in the same year.
  static bool isSameYear(DateTime a, DateTime b) {
    return a.year == b.year;
  }

  /// Returns a human-readable relative time string.
  static String relativeTime(DateTime dt, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final diff = base.difference(dt);
    final absDiff = diff.abs();

    if (absDiff.inSeconds < 45) return 'just now';
    if (absDiff.inSeconds < 90) return diff.isNegative ? 'in a minute' : 'a minute ago';
    if (absDiff.inMinutes < 45) {
      final mins = absDiff.inMinutes;
      return diff.isNegative ? 'in $mins minutes' : '$mins minutes ago';
    }
    if (absDiff.inMinutes < 90) return diff.isNegative ? 'in an hour' : 'an hour ago';
    if (absDiff.inHours < 22) {
      final hrs = absDiff.inHours;
      return diff.isNegative ? 'in $hrs hours' : '$hrs hours ago';
    }
    if (absDiff.inHours < 36) return diff.isNegative ? 'tomorrow' : 'yesterday';
    if (absDiff.inDays < 26) {
      final days = absDiff.inDays;
      return diff.isNegative ? 'in $days days' : '$days days ago';
    }
    if (absDiff.inDays < 45) return diff.isNegative ? 'in a month' : 'a month ago';
    if (absDiff.inDays < 345) {
      final months = (absDiff.inDays / 30).round();
      return diff.isNegative ? 'in $months months' : '$months months ago';
    }
    if (absDiff.inDays < 545) return diff.isNegative ? 'in a year' : 'a year ago';
    final years = (absDiff.inDays / 365).round();
    return diff.isNegative ? 'in $years years' : '$years years ago';
  }

  /// Calculates age in whole years from [birthdate].
  static int ageFromBirthdate(DateTime birthdate, {DateTime? now}) {
    final base = now ?? DateTime.now();
    int age = base.year - birthdate.year;
    if (base.month < birthdate.month ||
        (base.month == birthdate.month && base.day < birthdate.day)) {
      age--;
    }
    return max(0, age);
  }

  /// Returns the next occurrence of [weekday] (1=Mon, 7=Sun) after [from].
  static DateTime nextWeekday(DateTime from, int weekday) {
    int daysAhead = weekday - from.weekday;
    if (daysAhead <= 0) daysAhead += 7;
    return startOfDay(from.add(Duration(days: daysAhead)));
  }

  /// Returns the previous occurrence of [weekday] before [from].
  static DateTime previousWeekday(DateTime from, int weekday) {
    int daysBehind = from.weekday - weekday;
    if (daysBehind <= 0) daysBehind += 7;
    return startOfDay(from.subtract(Duration(days: daysBehind)));
  }

  /// Counts business days (Mon-Fri) between [start] and [end] (inclusive of start).
  static int businessDaysBetween(DateTime start, DateTime end) {
    if (start.isAfter(end)) return -businessDaysBetween(end, start);
    int count = 0;
    DateTime current = startOfDay(start);
    final endDay = startOfDay(end);
    while (current.isBefore(endDay)) {
      if (isWeekday(current)) count++;
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  /// Adds [days] business days (Mon-Fri) to [start].
  static DateTime addBusinessDays(DateTime start, int days) {
    if (days == 0) return start;
    int remaining = days.abs();
    int direction = days > 0 ? 1 : -1;
    DateTime current = startOfDay(start);
    while (remaining > 0) {
      current = current.add(Duration(days: direction));
      if (isWeekday(current)) remaining--;
    }
    return current;
  }

  /// Returns the abbreviated time zone name for [dt].
  static String timeZoneAbbreviation(DateTime dt) {
    final name = dt.timeZoneName;
    if (name.isNotEmpty) return name;
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutes';
  }

  /// Formats a [Duration] into a readable string.
  static String formatDuration(Duration d, {bool short = false}) {
    final total = d.inSeconds.abs();
    final days = total ~/ 86400;
    final hours = (total % 86400) ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;

    if (short) {
      if (days > 0) return '${days}d ${hours}h';
      if (hours > 0) return '${hours}h ${minutes}m';
      if (minutes > 0) return '${minutes}m ${seconds}s';
      return '${seconds}s';
    }

    final parts = <String>[];
    if (days > 0) parts.add('$days ${days == 1 ? "day" : "days"}');
    if (hours > 0) parts.add('$hours ${hours == 1 ? "hour" : "hours"}');
    if (minutes > 0) parts.add('$minutes ${minutes == 1 ? "minute" : "minutes"}');
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds ${seconds == 1 ? "second" : "seconds"}');
    }
    return parts.join(', ');
  }
}

/// Calendar grid generator and holiday data.
class GchCalendar {
  GchCalendar._();

  /// Returns a 6x7 grid of dates for a month calendar.
  /// Cells before the first day and after the last day are null.
  static List<List<DateTime?>> monthGrid(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final totalDays = GchDateUtil.daysInMonth(year, month);
    // weekday 1=Mon, 7=Sun; we want grid starting Monday
    int startOffset = firstDay.weekday - 1;

    final grid = List.generate(6, (_) => List<DateTime?>.filled(7, null));
    int day = 1;
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < startOffset || day > totalDays) {
          grid[row][col] = null;
        } else {
          grid[row][col] = DateTime(year, month, day++);
        }
      }
    }
    return grid;
  }

  /// Returns a full year calendar as 12 month grids.
  static List<List<List<DateTime?>>> yearCalendar(int year) {
    return List.generate(12, (i) => monthGrid(year, i + 1));
  }

  /// Returns a list of national holidays for the given year and country code.
  /// Supports 'CN', 'US', 'UK'.
  static List<DateTime> holidays(int year, String countryCode) {
    final code = countryCode.toUpperCase();
    switch (code) {
      case 'CN':
        return _cnHolidays(year);
      case 'US':
        return _usHolidays(year);
      case 'UK':
        return _ukHolidays(year);
      default:
        return [];
    }
  }

  static List<DateTime> _cnHolidays(int year) {
    return [
      DateTime(year, 1, 1),   // New Year's Day
      DateTime(year, 1, 29),  // Spring Festival Eve (approx)
      DateTime(year, 1, 30),  // Spring Festival Day 1
      DateTime(year, 1, 31),  // Spring Festival Day 2
      DateTime(year, 2, 1),   // Spring Festival Day 3
      DateTime(year, 2, 2),   // Spring Festival Day 4
      DateTime(year, 4, 4),   // Qingming Festival (approx)
      DateTime(year, 5, 1),   // International Labor Day
      DateTime(year, 5, 2),   // Labor Day Holiday
      DateTime(year, 5, 3),   // Labor Day Holiday
      DateTime(year, 6, 1),   // Dragon Boat Festival (approx)
      DateTime(year, 9, 17),  // Mid-Autumn Festival (approx)
      DateTime(year, 10, 1),  // National Day
      DateTime(year, 10, 2),  // National Day Holiday
      DateTime(year, 10, 3),  // National Day Holiday
      DateTime(year, 10, 4),  // National Day Holiday
      DateTime(year, 10, 5),  // National Day Holiday
      DateTime(year, 10, 6),  // National Day Holiday
      DateTime(year, 10, 7),  // National Day Holiday
    ];
  }

  static List<DateTime> _usHolidays(int year) {
    // Martin Luther King Day: 3rd Monday in January
    final mlkDay = _nthWeekdayOfMonth(year, 1, DateTime.monday, 3);
    // Presidents Day: 3rd Monday in February
    final presidentsDay = _nthWeekdayOfMonth(year, 2, DateTime.monday, 3);
    // Memorial Day: last Monday in May
    final memorialDay = _lastWeekdayOfMonth(year, 5, DateTime.monday);
    // Labor Day: 1st Monday in September
    final laborDay = _nthWeekdayOfMonth(year, 9, DateTime.monday, 1);
    // Columbus Day: 2nd Monday in October
    final columbusDay = _nthWeekdayOfMonth(year, 10, DateTime.monday, 2);
    // Thanksgiving: 4th Thursday in November
    final thanksgiving = _nthWeekdayOfMonth(year, 11, DateTime.thursday, 4);

    return [
      DateTime(year, 1, 1),   // New Year's Day
      mlkDay,
      presidentsDay,
      memorialDay,
      DateTime(year, 7, 4),   // Independence Day
      laborDay,
      columbusDay,
      DateTime(year, 11, 11), // Veterans Day
      thanksgiving,
      thanksgiving.add(const Duration(days: 1)), // Black Friday (informal)
      DateTime(year, 12, 25), // Christmas Day
      DateTime(year, 12, 26), // Boxing Day (informal)
    ];
  }

  static List<DateTime> _ukHolidays(int year) {
    // Easter calculations (Anonymous Gregorian algorithm)
    final easter = _calculateEaster(year);
    final goodFriday = easter.subtract(const Duration(days: 2));
    final easterMonday = easter.add(const Duration(days: 1));
    // Early May Bank Holiday: 1st Monday in May
    final earlyMay = _nthWeekdayOfMonth(year, 5, DateTime.monday, 1);
    // Spring Bank Holiday: last Monday in May
    final springBank = _lastWeekdayOfMonth(year, 5, DateTime.monday);
    // Summer Bank Holiday: last Monday in August
    final summerBank = _lastWeekdayOfMonth(year, 8, DateTime.monday);

    return [
      DateTime(year, 1, 1),   // New Year's Day
      goodFriday,
      easterMonday,
      earlyMay,
      springBank,
      summerBank,
      DateTime(year, 12, 25), // Christmas Day
      DateTime(year, 12, 26), // Boxing Day
    ];
  }

  static DateTime _calculateEaster(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static DateTime _nthWeekdayOfMonth(int year, int month, int weekday, int nth) {
    DateTime day = DateTime(year, month, 1);
    int count = 0;
    while (true) {
      if (day.weekday == weekday) {
        count++;
        if (count == nth) return day;
      }
      day = day.add(const Duration(days: 1));
      if (day.month != month) break;
    }
    return DateTime(year, month, 1);
  }

  static DateTime _lastWeekdayOfMonth(int year, int month, int weekday) {
    final lastDay = DateTime(year, month, GchDateUtil.daysInMonth(year, month));
    DateTime day = lastDay;
    while (day.weekday != weekday) {
      day = day.subtract(const Duration(days: 1));
    }
    return day;
  }

  /// Returns the calendar week label for a given date (e.g., "W23 2025").
  static String weekLabel(DateTime dt) {
    final week = GchDateUtil.weekOfYear(dt).toString().padLeft(2, '0');
    return 'W$week ${dt.year}';
  }

  /// Returns true if [dt] is a holiday in the given country.
  static bool isHoliday(DateTime dt, String countryCode) {
    final hs = holidays(dt.year, countryCode);
    return hs.any((h) => GchDateUtil.isSameDay(h, dt));
  }

  /// Returns the number of holidays in [year] for the given country.
  static int holidayCount(int year, String countryCode) {
    return holidays(year, countryCode).length;
  }

  /// Generates a list of all working days in a month.
  static List<DateTime> workingDaysInMonth(int year, int month, {String? countryCode}) {
    final result = <DateTime>[];
    final totalDays = GchDateUtil.daysInMonth(year, month);
    for (int day = 1; day <= totalDays; day++) {
      final dt = DateTime(year, month, day);
      if (GchDateUtil.isWeekday(dt)) {
        if (countryCode != null && isHoliday(dt, countryCode)) continue;
        result.add(dt);
      }
    }
    return result;
  }

  /// Returns all dates in a given week (Mon-Sun) containing [dt].
  static List<DateTime> weekDates(DateTime dt) {
    final monday = GchDateUtil.startOfWeek(dt);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Returns all dates in the month of [dt].
  static List<DateTime> monthDates(DateTime dt) {
    final total = GchDateUtil.daysInMonth(dt.year, dt.month);
    return List.generate(total, (i) => DateTime(dt.year, dt.month, i + 1));
  }

  /// Returns all months in [year] as their first days.
  static List<DateTime> monthsInYear(int year) {
    return List.generate(12, (i) => DateTime(year, i + 1, 1));
  }

  /// Returns the number of weeks in a year (52 or 53 per ISO 8601).
  static int weeksInYear(int year) {
    final dec28 = DateTime(year, 12, 28);
    return GchDateUtil.weekOfYear(dec28);
  }

  /// Returns a list of all ISO week-start dates (Mondays) in [year].
  static List<DateTime> weekStartsInYear(int year) {
    final result = <DateTime>[];
    DateTime current = GchDateUtil.startOfWeek(DateTime(year, 1, 4));
    while (current.year <= year || GchDateUtil.weekOfYear(current) <= weeksInYear(year)) {
      if (current.year > year && GchDateUtil.weekOfYear(current) == 1) break;
      result.add(current);
      current = current.add(const Duration(days: 7));
      if (result.length > 53) break;
    }
    return result;
  }

  /// Returns a short representation of a month grid cell label.
  static String cellLabel(DateTime? dt) {
    if (dt == null) return '';
    return dt.day.toString();
  }

  /// Returns the season name for the given date (Northern Hemisphere).
  static String season(DateTime dt) {
    final month = dt.month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Autumn';
    return 'Winter';
  }

  /// Returns the day of the year (1-366).
  static int dayOfYear(DateTime dt) {
    return dt.difference(DateTime(dt.year, 1, 1)).inDays + 1;
  }

  /// Returns the number of remaining days in the year.
  static int daysRemainingInYear(DateTime dt) {
    final lastDay = GchDateUtil.isLeapYear(dt.year) ? 366 : 365;
    return lastDay - dayOfYear(dt);
  }

  /// Returns the fiscal quarter for a date (assuming fiscal year starts October).
  static int fiscalQuarter(DateTime dt, {int fiscalYearStartMonth = 10}) {
    final adjusted = (dt.month - fiscalYearStartMonth + 12) % 12;
    return adjusted ~/ 3 + 1;
  }
}

// ─── GchDateRange ─────────────────────────────────────────────────────────

/// Represents a range between two dates and provides range queries.
class GchDateRange {
  final DateTime start;
  final DateTime end;

  GchDateRange({required this.start, required this.end})
      : assert(!start.isAfter(end), 'Start must not be after end');

  /// Returns true if [dt] falls within this range (inclusive).
  bool contains(DateTime dt) {
    return !dt.isBefore(start) && !dt.isAfter(end);
  }

  /// Returns true if this range overlaps with [other].
  bool overlaps(GchDateRange other) {
    return !start.isAfter(other.end) && !end.isBefore(other.start);
  }

  /// Returns the intersection of this range and [other], or null if no overlap.
  GchDateRange? intersection(GchDateRange other) {
    final s = start.isAfter(other.start) ? start : other.start;
    final e = end.isBefore(other.end) ? end : other.end;
    if (s.isAfter(e)) return null;
    return GchDateRange(start: s, end: e);
  }

  /// Returns the total duration of this range.
  Duration get duration => end.difference(start);

  /// Returns the number of calendar days in this range.
  int get dayCount => GchDateUtil.daysBetween(start, end) + 1;

  /// Splits this range into chunks of [chunkDays] days.
  List<GchDateRange> splitByDays(int chunkDays) {
    final result = <GchDateRange>[];
    DateTime current = start;
    while (!current.isAfter(end)) {
      final chunkEnd = current.add(Duration(days: chunkDays - 1));
      result.add(GchDateRange(
        start: current,
        end: chunkEnd.isAfter(end) ? end : chunkEnd,
      ));
      current = current.add(Duration(days: chunkDays));
    }
    return result;
  }

  /// Splits into calendar months.
  List<GchDateRange> splitByMonths() {
    final result = <GchDateRange>[];
    DateTime current = GchDateUtil.startOfMonth(start);
    while (!current.isAfter(end)) {
      final monthEnd = GchDateUtil.endOfMonth(current);
      result.add(GchDateRange(
        start: current.isBefore(start) ? start : current,
        end: monthEnd.isAfter(end) ? end : monthEnd,
      ));
      current = GchDateUtil.addMonths(GchDateUtil.startOfMonth(current), 1);
    }
    return result;
  }

  /// Returns all dates within the range.
  List<DateTime> toDateList() {
    final result = <DateTime>[];
    DateTime current = GchDateUtil.startOfDay(start);
    final endDay = GchDateUtil.startOfDay(end);
    while (!current.isAfter(endDay)) {
      result.add(current);
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  String toString() => 'GchDateRange(${GchDateUtil.format(start, "yyyy-MM-dd")} - ${GchDateUtil.format(end, "yyyy-MM-dd")})';
}

// ─── GchTimer ─────────────────────────────────────────────────────────────

/// A simple stopwatch-like timer utility.
class GchTimer {
  DateTime? _startTime;
  DateTime? _stopTime;
  final List<({String label, Duration elapsed})> _laps = [];

  /// Starts or restarts the timer.
  void start() {
    _startTime = DateTime.now();
    _stopTime = null;
    _laps.clear();
  }

  /// Stops the timer.
  Duration stop() {
    _stopTime = DateTime.now();
    return elapsed;
  }

  /// Records a lap split with an optional [label].
  void lap({String label = ''}) {
    _laps.add((label: label.isEmpty ? 'Lap ${_laps.length + 1}' : label, elapsed: elapsed));
  }

  /// Returns time elapsed since start (or until stop).
  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    final end = _stopTime ?? DateTime.now();
    return end.difference(_startTime!);
  }

  /// Returns elapsed milliseconds.
  int get elapsedMs => elapsed.inMilliseconds;

  /// Returns true if the timer is currently running.
  bool get isRunning => _startTime != null && _stopTime == null;

  /// Returns all recorded laps.
  List<({String label, Duration elapsed})> get laps => List.unmodifiable(_laps);

  /// Returns the elapsed time as a formatted string (e.g., "1.234s").
  String get formattedElapsed {
    final ms = elapsedMs;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(3)}s';
  }
}

// ─── GchDateMath ──────────────────────────────────────────────────────────

/// Advanced date arithmetic utilities.
class GchDateMath {
  GchDateMath._();

  /// Returns the number of Sundays (or given [weekday]) in a month.
  static int weekdayCountInMonth(int year, int month, int weekday) {
    int count = 0;
    final totalDays = GchDateUtil.daysInMonth(year, month);
    for (int day = 1; day <= totalDays; day++) {
      if (DateTime(year, month, day).weekday == weekday) count++;
    }
    return count;
  }

  /// Returns the date of the nth occurrence of [weekday] in the month,
  /// or null if there are fewer than [nth] occurrences.
  static DateTime? nthWeekdayInMonth(int year, int month, int weekday, int nth) {
    int count = 0;
    final totalDays = GchDateUtil.daysInMonth(year, month);
    for (int day = 1; day <= totalDays; day++) {
      final dt = DateTime(year, month, day);
      if (dt.weekday == weekday) {
        count++;
        if (count == nth) return dt;
      }
    }
    return null;
  }

  /// Returns the last occurrence of [weekday] in the given month.
  static DateTime lastWeekdayInMonth(int year, int month, int weekday) {
    final totalDays = GchDateUtil.daysInMonth(year, month);
    for (int day = totalDays; day >= 1; day--) {
      final dt = DateTime(year, month, day);
      if (dt.weekday == weekday) return dt;
    }
    return DateTime(year, month, totalDays);
  }

  /// Snaps [dt] to the nearest [intervalMinutes]-minute boundary.
  static DateTime snapToInterval(DateTime dt, int intervalMinutes) {
    final totalMinutes = dt.hour * 60 + dt.minute;
    final snapped = (totalMinutes / intervalMinutes).round() * intervalMinutes;
    final h = snapped ~/ 60;
    final m = snapped % 60;
    return DateTime(dt.year, dt.month, dt.day, h % 24, m);
  }

  /// Returns the number of full years between [a] and [b].
  static int fullYearsBetween(DateTime a, DateTime b) {
    final earlier = a.isBefore(b) ? a : b;
    final later = a.isBefore(b) ? b : a;
    int years = later.year - earlier.year;
    if (later.month < earlier.month ||
        (later.month == earlier.month && later.day < earlier.day)) {
      years--;
    }
    return years;
  }
}
