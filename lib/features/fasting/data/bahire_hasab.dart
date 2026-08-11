import 'package:kenat/kenat.dart' as kenat;
import 'fasts.dart';

/// Thin wrapper around kenat's Bahire Hasab calculations.
class BahireHasabWrapper {
  BahireHasabWrapper._();

  /// Computes full Bahire Hasab calculation map for a given Ethiopian year.
  static Map<String, dynamic> getBahireHasab(
    int ethiopianYear, [
    Map<String, dynamic>? options,
  ]) {
    return kenat.getBahireHasab(ethiopianYear, options);
  }

  /// Calculates the Ethiopian date of Fasika (Resurrection/Easter) for a given Ethiopian year.
  static EthiopianDate getFasika(int ethiopianYear) {
    final map = kenat.getMovableHoliday('fasika', ethiopianYear);
    return EthiopianDate(
      year: map['year']!,
      month: map['month']!,
      day: map['day']!,
    );
  }

  /// Calculates the Ethiopian date of any movable holiday/feast for a given Ethiopian year.
  static EthiopianDate getMovableHoliday(
    dynamic holidayKey,
    int ethiopianYear,
  ) {
    final map = kenat.getMovableHoliday(holidayKey, ethiopianYear);
    return EthiopianDate(
      year: map['year']!,
      month: map['month']!,
      day: map['day']!,
    );
  }
}
