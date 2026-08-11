import 'package:kenat/kenat.dart' as kenat;

/// Representation of a date in the Ethiopian Calendar.

class EthiopianDate implements Comparable<EthiopianDate> {
  final int year;
  final int month;
  final int day;

  const EthiopianDate({
    required this.year,
    required this.month,
    required this.day,
  });

  factory EthiopianDate.fromMap(Map<String, dynamic> map) {
    return EthiopianDate(
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      day: (map['day'] as num).toInt(),
    );
  }

  Map<String, int> toMap() => {'year': year, 'month': month, 'day': day};

  /// Converts this Ethiopian date to a Gregorian [DateTime].
  DateTime toDateTime() {
    final g = kenat.toGC(year, month, day);
    return DateTime(g['year']!, g['month']!, g['day']!);
  }

  /// Day of week: 1 = Monday, ..., 3 = Wednesday, ..., 5 = Friday, 7 = Sunday.
  int get weekday => toDateTime().weekday;

  /// Returns true if this Ethiopian year is a leap year (Pagume has 6 days).
  bool get isLeapYear => kenat.isEthiopianLeapYear(year);

  /// Returns number of days in this month.
  int get daysInMonth => kenat.getEthiopianDaysInMonth(year, month);

  /// Adds [count] days to this Ethiopian date.
  EthiopianDate addDays(int count) {
    final res = kenat.addDays(toMap(), count);
    return EthiopianDate.fromMap(res);
  }

  /// Calculates difference in days (this - other).
  int differenceInDays(EthiopianDate other) {
    return kenat.diffInDays(toMap(), other.toMap());
  }

  bool isBefore(EthiopianDate other) => compareTo(other) < 0;
  bool isAfter(EthiopianDate other) => compareTo(other) > 0;
  bool isSameDay(EthiopianDate other) => compareTo(other) == 0;

  @override
  int compareTo(EthiopianDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthiopianDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'EthiopianDate($year, $month, $day)';
}

/// Represents an EOTC fasting period with start and end dates.
class FastPeriod {
  final String key; // e.g. 'abiyTsome'
  final String nameAm; // e.g. 'ዐቢይ ጾም'
  final String nameEn; // e.g. 'Great Lent'
  final EthiopianDate start;
  final EthiopianDate end;

  const FastPeriod({
    required this.key,
    required this.nameAm,
    required this.nameEn,
    required this.start,
    required this.end,
  });

  /// Checks if [date] falls within [start] and [end] inclusive.
  bool contains(EthiopianDate date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FastPeriod &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          nameAm == other.nameAm &&
          nameEn == other.nameEn &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(key, nameAm, nameEn, start, end);

  @override
  String toString() => 'FastPeriod($key, $nameAm, $start - $end)';
}

/// Immutable status of fasting for a given Ethiopian date.
class FastStatus {
  final bool isFasting;
  final List<FastPeriod> active; // Can contain multiple overlapping fasts
  final FastPeriod? next;
  final int? daysRemaining;

  const FastStatus({
    required this.isFasting,
    required this.active,
    this.next,
    this.daysRemaining,
  });
}

/// Helper function to generate all multi-day and fixed fast periods for a given year using kenat.
List<FastPeriod> getAllFastsForYear(int year) {
  final result = <FastPeriod>[];

  final fastDefs = <Map<String, String>>[
    {
      'key': 'nineveh',
      'kenatKey': kenat.FastingKeys.nineveh,
      'nameAm': 'ጾመ ነነዌ',
      'nameEn': 'Fast of Nineveh',
    },
    {
      'key': 'abiyTsome',
      'kenatKey': kenat.FastingKeys.abiyTsome,
      'nameAm': 'ዐቢይ ጾም',
      'nameEn': 'Great Lent',
    },
    {
      'key': 'tsomeHawaryat',
      'kenatKey': kenat.FastingKeys.tsomeHawaryat,
      'nameAm': 'ጾመ ሐዋርያት',
      'nameEn': 'Fast of the Apostles',
    },
    {
      'key': 'tsomeNebiyat',
      'kenatKey': kenat.FastingKeys.tsomeNebiyat,
      'nameAm': 'ጾመ ነቢያት',
      'nameEn': 'Fast of the Prophets',
    },
    {
      'key': 'filseta',
      'kenatKey': kenat.FastingKeys.filseta,
      'nameAm': 'ጾመ ፍልሰታ',
      'nameEn': 'Fast of the Assumption',
    },
  ];

  for (final def in fastDefs) {
    final periodMap = kenat.getFastingPeriod(def['kenatKey']!, year);
    if (periodMap != null &&
        periodMap.containsKey('start') &&
        periodMap.containsKey('end')) {
      result.add(
        FastPeriod(
          key: def['key']!,
          nameAm: def['nameAm']!,
          nameEn: def['nameEn']!,
          start: EthiopianDate.fromMap(periodMap['start']!),
          end: EthiopianDate.fromMap(periodMap['end']!),
        ),
      );
    }
  }

  // Gahad fasts: Eve of Christmas (Tahsas 28) and Epiphany (Tirr 10)
  result.add(
    FastPeriod(
      key: 'gahad',
      nameAm: 'ጾመ ገሃድ',
      nameEn: 'Fast of Gahad',
      start: EthiopianDate(year: year, month: 4, day: 28),
      end: EthiopianDate(year: year, month: 4, day: 28),
    ),
  );

  result.add(
    FastPeriod(
      key: 'gahad',
      nameAm: 'ጾመ ገሃድ',
      nameEn: 'Fast of Gahad',
      start: EthiopianDate(year: year, month: 5, day: 10),
      end: EthiopianDate(year: year, month: 5, day: 10),
    ),
  );

  return result;
}

/// Pure function to calculate [FastStatus] for a given [EthiopianDate].
FastStatus fastStatusFor(EthiopianDate date) {
  final activeFasts = <FastPeriod>[];

  // Evaluate multi-day fast periods for current year
  final yearFasts = getAllFastsForYear(date.year);
  for (final fast in yearFasts) {
    if (fast.contains(date)) {
      activeFasts.add(fast);
    }
  }

  // Evaluate Wednesday & Friday fasts (Tsome Dihnet) using kenat's rule calculation
  if (kenat.isTsomeDihnetFastDay(date.toMap())) {
    final tsomeDihnet = FastPeriod(
      key: 'tsomeDihnet',
      nameAm: 'ጾመ ድኅነት',
      nameEn: 'Wednesday and Friday',
      start: date,
      end: date,
    );
    activeFasts.add(tsomeDihnet);
  }

  final isFasting = activeFasts.isNotEmpty;

  if (isFasting) {
    FastPeriod? primaryFast;
    for (final fast in activeFasts) {
      if (fast.key != 'tsomeDihnet') {
        primaryFast = fast;
        break;
      }
    }
    primaryFast ??= activeFasts.first;

    final daysRemaining = primaryFast.end.differenceInDays(date) + 1;

    return FastStatus(
      isFasting: true,
      active: activeFasts,
      next: null,
      daysRemaining: daysRemaining > 0 ? daysRemaining : 1,
    );
  } else {
    // Find next upcoming fast period
    final allUpcoming = <FastPeriod>[];
    allUpcoming.addAll(yearFasts);
    allUpcoming.addAll(getAllFastsForYear(date.year + 1));

    FastPeriod? nextFast;
    int? shortestDiff;

    for (final fast in allUpcoming) {
      if (fast.start.isAfter(date)) {
        final diff = fast.start.differenceInDays(date);
        if (shortestDiff == null || diff < shortestDiff) {
          shortestDiff = diff;
          nextFast = fast;
        }
      }
    }

    return FastStatus(
      isFasting: false,
      active: const [],
      next: nextFast,
      daysRemaining: shortestDiff,
    );
  }
}
