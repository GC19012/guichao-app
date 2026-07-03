// Holiday static data — Gregorian dates hardcoded through 2030

class GchHoliday {
  final String key;
  final String name;
  final String emoji;
  final String lunarDesc; // empty for solar holidays
  final DateTime date;
  final List<String> greetings;

  const GchHoliday({
    required this.key,
    required this.name,
    required this.emoji,
    required this.lunarDesc,
    required this.date,
    required this.greetings,
  });
}

class GchHolidayData {
  GchHolidayData._();

  static List<GchHoliday> allHolidays() {
    final now = DateTime.now();
    final year = now.year;
    final all = <GchHoliday>[];
    for (int y = year; y <= year + 4; y++) {
      all.addAll(_forYear(y));
    }
    return all;
  }

  static List<GchHoliday> upcomingHolidays({int limit = 20}) {
    final now = DateTime.now();
    return allHolidays()
        .where((h) => !h.date.isBefore(DateTime(now.year, now.month, now.day)))
        .take(limit)
        .toList();
  }

  static GchHoliday? nextHoliday() {
    final list = upcomingHolidays(limit: 1);
    return list.isEmpty ? null : list.first;
  }

  static int daysUntil(GchHoliday h) {
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    return h.date.difference(t).inDays;
  }

  static List<GchHoliday> _forYear(int y) => [
        GchHoliday(
          key: 'yuandan_$y',
          name: '元旦',
          emoji: '🎆',
          lunarDesc: '',
          date: DateTime(y, 1, 1),
          greetings: [
            '新年伊始，万象更新！愿新的一年里，你平安喜乐，事事顺心，元旦快乐！',
            '辞旧迎新，岁月流金。愿你在新的一年里，阖家幸福，万事如意，元旦快乐！',
            '新年新气象，新年新希望。愿你的每一天都充满阳光，元旦快乐！',
          ],
        ),
        GchHoliday(
          key: 'chunjie_$y',
          name: '春节',
          emoji: '🧧',
          lunarDesc: '农历正月初一',
          date: _springFestival(y),
          greetings: [
            '爆竹声中辞旧岁，春风送暖入屠苏。愿新春佳节，阖家团圆，幸福安康！',
            '新春大吉，万事如意！愿你在新的一年里，财源广进，健康平安，春节快乐！',
            '岁月更迭，新春如约而至。愿你鸿运当头，心想事成，新年快乐！',
            '喜迎新春，福满人间！愿你和家人团聚一堂，共享天伦之乐，春节快乐！',
          ],
        ),
        GchHoliday(
          key: 'qingming_$y',
          name: '清明节',
          emoji: '🌿',
          lunarDesc: '',
          date: _qingming(y),
          greetings: [
            '清明时节，春和景明。愿你在这柔和的春日里，心情舒畅，一切安好。',
            '清明节气，缅怀先人，珍惜当下。愿逝者安息，生者平安幸福。',
            '春风拂面，杨柳依依。清明时节，愿你踏青出游，身心舒畅。',
          ],
        ),
        GchHoliday(
          key: 'laodong_$y',
          name: '劳动节',
          emoji: '🌷',
          lunarDesc: '',
          date: DateTime(y, 5, 1),
          greetings: [
            '劳动最光荣！五一劳动节，愿你在休假中充分放松，享受美好时光！',
            '五一假期快乐！愿你劳逸结合，收获满满，生活幸福美满！',
            '平凡的劳动创造不平凡的生活。劳动节快乐，愿你一切安好！',
          ],
        ),
        GchHoliday(
          key: 'haizi_$y',
          name: '儿童节',
          emoji: '🎠',
          lunarDesc: '',
          date: DateTime(y, 6, 1),
          greetings: [
            '六一儿童节，愿每个孩子都能在快乐与爱中成长，无忧无虑！',
            '童年是最美好的时光。祝小朋友们儿童节快乐，健康成长！',
            '愿我们心中那个孩子永远不会老去，儿童节快乐！',
          ],
        ),
        GchHoliday(
          key: 'duanwu_$y',
          name: '端午节',
          emoji: '🎋',
          lunarDesc: '农历五月初五',
          date: _dragonBoat(y),
          greetings: [
            '粽香飘四海，龙舟竞渡忙。端午节快乐，愿你身体健康，百毒不侵！',
            '艾香满室，粽叶飘香。端午佳节，愿你和家人快乐幸福，平安安康！',
            '五月五，是端阳。愿你端午节吃粽子，喝雄黄，百病不生，安康快乐！',
          ],
        ),
        GchHoliday(
          key: 'qixi_$y',
          name: '七夕节',
          emoji: '💕',
          lunarDesc: '农历七月初七',
          date: _qixi(y),
          greetings: [
            '七夕情人节，愿天下有情人终成眷属，爱情甜蜜，幸福长久！',
            '银河渡鹊桥，牛郎会织女。七夕节，愿你爱情美满，幸福永驻！',
            '此刻，星河灿烂，爱意绵绵。七夕快乐，愿你与挚爱携手，岁月静好。',
          ],
        ),
        GchHoliday(
          key: 'zhongqiu_$y',
          name: '中秋节',
          emoji: '🌕',
          lunarDesc: '农历八月十五',
          date: _midAutumn(y),
          greetings: [
            '月圆人团圆，愿你阖家幸福，万事如意，中秋节快乐！',
            '皓月当空照，思念随风飘。愿你中秋节快乐，与家人共享团圆之喜！',
            '花好月圆夜，共享团圆情。愿你中秋节和家人幸福美满，共度良宵！',
            '明月千里寄相思，但愿人长久，千里共婵娟。中秋节快乐！',
          ],
        ),
        GchHoliday(
          key: 'guoqing_$y',
          name: '国庆节',
          emoji: '🇨🇳',
          lunarDesc: '',
          date: DateTime(y, 10, 1),
          greetings: [
            '举国同庆，华诞共贺！祝祖国繁荣昌盛，愿你国庆假期快乐！',
            '红旗飘扬，盛世华章。国庆节快乐，愿祖国山河壮美，人民幸福安康！',
            '国庆佳节，普天同庆。愿你假期愉快，阖家幸福，国泰民安！',
          ],
        ),
        GchHoliday(
          key: 'chongyang_$y',
          name: '重阳节',
          emoji: '🍂',
          lunarDesc: '农历九月初九',
          date: _doubleNinth(y),
          greetings: [
            '九九重阳，登高望远。愿长辈们身体健康，福寿安康，重阳节快乐！',
            '重阳佳节，愿家中老人笑口常开，健康长寿，幸福每一天！',
            '金秋送爽，丹桂飘香。重阳节，愿你敬老爱幼，阖家欢乐！',
          ],
        ),
        GchHoliday(
          key: 'dongzhi_$y',
          name: '冬至',
          emoji: '❄️',
          lunarDesc: '',
          date: _winterSolstice(y),
          greetings: [
            '冬至大如年，愿你吃上热腾腾的饺子，暖身又暖心，冬至快乐！',
            '冬至到，阳气升。愿你在这寒冷的冬日，温暖如春，阖家幸福！',
            '数九寒天，温情依旧。冬至快乐，愿你和家人团聚，温暖度冬！',
          ],
        ),
        GchHoliday(
          key: 'shengdan_$y',
          name: '圣诞节',
          emoji: '🎄',
          lunarDesc: '',
          date: DateTime(y, 12, 25),
          greetings: [
            'Merry Christmas！愿圣诞节带给你无尽的欢乐与幸福，平安夜安康！',
            '圣诞快乐！愿这个冬天，你的生活充满温暖与爱，幸福每一天！',
            '雪花飘飘，圣诞来到。愿你和家人共度温馨圣诞，快乐无比！',
          ],
        ),
        GchHoliday(
          key: 'muthers_$y',
          name: '母亲节',
          emoji: '💐',
          lunarDesc: '五月第二个周日',
          date: _mothersDay(y),
          greetings: [
            '母爱如阳光，温暖而无私。母亲节快乐，愿妈妈身体健康，幸福安康！',
            '感谢妈妈的爱与付出。母亲节快乐，愿您青春永驻，笑口常开！',
            '世上只有妈妈好。母亲节，愿天下所有母亲健康快乐，幸福一生！',
          ],
        ),
        GchHoliday(
          key: 'fathers_$y',
          name: '父亲节',
          emoji: '👔',
          lunarDesc: '六月第三个周日',
          date: _fathersDay(y),
          greetings: [
            '父爱如山，深沉而厚重。父亲节快乐，愿爸爸身体健康，万事顺意！',
            '感谢父亲一路的陪伴与守护。父亲节快乐，愿您快乐每一天！',
            '老爸，您是我人生最坚实的依靠。父亲节快乐，祝您健康长寿！',
          ],
        ),
        GchHoliday(
          key: 'jiaoshi_$y',
          name: '教师节',
          emoji: '📚',
          lunarDesc: '',
          date: DateTime(y, 9, 10),
          greetings: [
            '三尺讲台，传道授业解惑。教师节快乐，感谢老师们的辛勤付出！',
            '春蚕到死丝方尽，蜡炬成灰泪始干。教师节，愿老师们幸福安康！',
            '感谢恩师的谆谆教诲。教师节快乐，愿您桃李满天下，幸福每一天！',
          ],
        ),
      ].where((h) => h.date.year == y).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  // ── 农历/浮动节日换算 ──────────────────────────────────────────

  static DateTime _springFestival(int y) {
    const Map<int, List<int>> dates = {
      2025: [1, 29], 2026: [2, 17], 2027: [2, 6],
      2028: [1, 26], 2029: [2, 13], 2030: [2, 3],
    };
    final d = dates[y] ?? [2, 1];
    return DateTime(y, d[0], d[1]);
  }

  static DateTime _dragonBoat(int y) {
    const Map<int, List<int>> dates = {
      2025: [5, 31], 2026: [6, 19], 2027: [6, 9],
      2028: [5, 28], 2029: [6, 16], 2030: [6, 5],
    };
    final d = dates[y] ?? [6, 5];
    return DateTime(y, d[0], d[1]);
  }

  static DateTime _qixi(int y) {
    const Map<int, List<int>> dates = {
      2025: [8, 29], 2026: [8, 19], 2027: [8, 8],
      2028: [8, 26], 2029: [8, 15], 2030: [9, 3],
    };
    final d = dates[y] ?? [8, 7];
    return DateTime(y, d[0], d[1]);
  }

  static DateTime _midAutumn(int y) {
    const Map<int, List<int>> dates = {
      2025: [10, 6], 2026: [9, 25], 2027: [10, 15],
      2028: [10, 3], 2029: [9, 22], 2030: [10, 11],
    };
    final d = dates[y] ?? [9, 15];
    return DateTime(y, d[0], d[1]);
  }

  static DateTime _doubleNinth(int y) {
    const Map<int, List<int>> dates = {
      2025: [10, 29], 2026: [10, 18], 2027: [11, 7],
      2028: [10, 26], 2029: [10, 16], 2030: [11, 4],
    };
    final d = dates[y] ?? [10, 9];
    return DateTime(y, d[0], d[1]);
  }

  static DateTime _qingming(int y) {
    // 清明一般在4月4日或5日
    return y % 4 == 0 ? DateTime(y, 4, 4) : DateTime(y, 4, 5);
  }

  static DateTime _winterSolstice(int y) {
    return DateTime(y, 12, 22);
  }

  static DateTime _mothersDay(int y) {
    // 五月第二个周日
    final firstDay = DateTime(y, 5, 1);
    final firstSunday = firstDay.weekday == 7
        ? firstDay
        : firstDay.add(Duration(days: 7 - firstDay.weekday));
    return firstSunday.add(const Duration(days: 7));
  }

  static DateTime _fathersDay(int y) {
    // 六月第三个周日
    final firstDay = DateTime(y, 6, 1);
    final firstSunday = firstDay.weekday == 7
        ? firstDay
        : firstDay.add(Duration(days: 7 - firstDay.weekday));
    return firstSunday.add(const Duration(days: 14));
  }
}
