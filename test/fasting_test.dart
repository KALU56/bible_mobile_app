import 'package:flutter_test/flutter_test.dart';
import 'package:kenat/kenat.dart' as kenat;
import 'package:bibleflutter/features/fasting/data/fasts.dart';
import 'package:bibleflutter/features/fasting/data/bahire_hasab.dart';

void main() {
  group('Fasting Calculations (fastStatusFor)', () {
    test('BahireHasabWrapper returns valid Fasika date', () {
      final fasika2016 = BahireHasabWrapper.getFasika(2016);
      expect(fasika2016.year, equals(2016));
      expect(fasika2016.month, equals(8));
      expect(fasika2016.day, equals(27));
    });

    test(
      'Test Case 1: Wednesday inside the 50 days after Fasika is NOT a fast',
      () {
        // 2016 EC Fasika is Miyazia 27 (Month 8, Day 27).
        // Sene 5, 2016 (Month 10, Day 5) is 27 days after Fasika and falls on a Wednesday.
        final date = const EthiopianDate(year: 2016, month: 10, day: 5);
        final status = fastStatusFor(date);
        expect(status.isFasting, isFalse);
        expect(status.active, isEmpty);
      },
    );

    test('Test Case 2: First and last day of ዐቢይ ጾም (2016 EC)', () {
      final abiyPeriodMap = kenat.getFastingPeriod(
        kenat.FastingKeys.abiyTsome,
        2016,
      )!;
      final firstDay = EthiopianDate.fromMap(abiyPeriodMap['start']!);
      final lastDay = EthiopianDate.fromMap(abiyPeriodMap['end']!);

      final statusFirst = fastStatusFor(firstDay);
      expect(statusFirst.isFasting, isTrue);
      expect(statusFirst.active.any((f) => f.key == 'abiyTsome'), isTrue);

      final statusLast = fastStatusFor(lastDay);
      expect(statusLast.isFasting, isTrue);
      expect(statusLast.active.any((f) => f.key == 'abiyTsome'), isTrue);
      expect(statusLast.daysRemaining, equals(1));
    });

    test(
      'Test Case 3: ጳጉሜን days in 5-day year (2016 EC) and 6-day year (2015 EC)',
      () {
        // 2015 EC is a leap year (2015 % 4 == 3) -> Pagume has 6 days
        final pagume6_2015 = const EthiopianDate(year: 2015, month: 13, day: 6);
        expect(pagume6_2015.daysInMonth, equals(6));
        final statusPagume6 = fastStatusFor(pagume6_2015);
        expect(statusPagume6, isNotNull);

        // 2016 EC is non-leap year (2016 % 4 == 0) -> Pagume has 5 days
        final pagume5_2016 = const EthiopianDate(year: 2016, month: 13, day: 5);
        expect(pagume5_2016.daysInMonth, equals(5));
        final statusPagume5 = fastStatusFor(pagume5_2016);
        expect(statusPagume5, isNotNull);
      },
    );

    test('Test Case 4: Ethiopian leap year detection', () {
      expect(
        const EthiopianDate(year: 2015, month: 1, day: 1).isLeapYear,
        isTrue,
      );
      expect(
        const EthiopianDate(year: 2016, month: 1, day: 1).isLeapYear,
        isFalse,
      );
      expect(
        const EthiopianDate(year: 2019, month: 1, day: 1).isLeapYear,
        isTrue,
      );
    });

    test('Test Case 5: Friday inside ጾመ ፍልሰታ (Overlap case)', () {
      // ጾመ ፍልሰታ is Nehase 1 to Nehase 14.
      // Nehase 3, 2016 is a Friday (weekday = 5).
      final date = const EthiopianDate(year: 2016, month: 12, day: 3);
      expect(date.weekday, equals(5));

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      // Active fasts should contain both Filseta and Tsome Dihnet (Friday)
      expect(status.active.length, greaterThanOrEqualTo(2));
      expect(status.active.any((f) => f.key == 'filseta'), isTrue);
      expect(status.active.any((f) => f.key == 'tsomeDihnet'), isTrue);
    });

    test('Comprehensive 20+ Date Verification Suite across 2014-2018 EC', () {
      final testDates = <Map<String, dynamic>>[
        // 1. Fast of Nineveh (2016 EC: Yekatit 18 to Yekatit 20)
        {
          'date': const EthiopianDate(year: 2016, month: 6, day: 18),
          'isFasting': true,
          'fastKey': 'nineveh',
        },
        // 2. Mid-Lent (Debre Zeit day - inside Abiy Tsome)
        {
          'date': const EthiopianDate(year: 2016, month: 7, day: 4),
          'isFasting': true,
          'fastKey': 'abiyTsome',
        },
        // 3. Good Friday / Siklet (inside Abiy Tsome)
        {
          'date': const EthiopianDate(year: 2016, month: 8, day: 25),
          'isFasting': true,
          'fastKey': 'abiyTsome',
        },
        // 4. Easter Sunday / Fasika 2016 (Miyazia 27 - NOT a fast)
        {
          'date': const EthiopianDate(year: 2016, month: 8, day: 27),
          'isFasting': false,
        },
        // 5. Wednesday inside 50 days of Pentecost (Sene 5, 2016 - NOT a fast)
        {
          'date': const EthiopianDate(year: 2016, month: 10, day: 5),
          'isFasting': false,
        },
        // 6. Fast of Apostles start (2016 EC: Sene 17)
        {
          'date': const EthiopianDate(year: 2016, month: 10, day: 17),
          'isFasting': true,
          'fastKey': 'tsomeHawaryat',
        },
        // 7. Fast of Apostles end (Hamle 4)
        {
          'date': const EthiopianDate(year: 2016, month: 11, day: 4),
          'isFasting': true,
          'fastKey': 'tsomeHawaryat',
        },
        // 8. Day after Fast of Apostles (Hamle 6 - non fast if not Wed/Fri)
        {
          'date': const EthiopianDate(year: 2016, month: 11, day: 6),
          'isFasting': false,
        },
        // 9. Filseta start (Nehase 1)
        {
          'date': const EthiopianDate(year: 2016, month: 12, day: 1),
          'isFasting': true,
          'fastKey': 'filseta',
        },
        // 10. Filseta end (Nehase 14)
        {
          'date': const EthiopianDate(year: 2016, month: 12, day: 14),
          'isFasting': true,
          'fastKey': 'filseta',
        },
        // 11. Regular Wednesday outside Pentecost (Meskerem 8, 2017)
        {
          'date': const EthiopianDate(year: 2017, month: 1, day: 8),
          'isFasting': true,
          'fastKey': 'tsomeDihnet',
        },
        // 12. Regular Friday outside Pentecost (Meskerem 10, 2017)
        {
          'date': const EthiopianDate(year: 2017, month: 1, day: 10),
          'isFasting': true,
          'fastKey': 'tsomeDihnet',
        },
        // 13. Regular Tuesday non-fast (Meskerem 7, 2017)
        {
          'date': const EthiopianDate(year: 2017, month: 1, day: 7),
          'isFasting': false,
        },
        // 14. Advent / Tsome Nebiyat start (Hidar 15)
        {
          'date': const EthiopianDate(year: 2017, month: 3, day: 15),
          'isFasting': true,
          'fastKey': 'tsomeNebiyat',
        },
        // 15. Advent / Tsome Nebiyat mid (Tahsas 10)
        {
          'date': const EthiopianDate(year: 2017, month: 4, day: 10),
          'isFasting': true,
          'fastKey': 'tsomeNebiyat',
        },
        // 16. Gahad / Eve of Christmas (Tahsas 28)
        {
          'date': const EthiopianDate(year: 2017, month: 4, day: 28),
          'isFasting': true,
          'fastKey': 'gahad',
        },
        // 17. Christmas / Genna (Tahsas 29 - Feast)
        {
          'date': const EthiopianDate(year: 2017, month: 4, day: 29),
          'isFasting': false,
        },
        // 18. Gahad / Eve of Epiphany (Tirr 10)
        {
          'date': const EthiopianDate(year: 2017, month: 5, day: 10),
          'isFasting': true,
          'fastKey': 'gahad',
        },
        // 19. Epiphany / Timkat (Tirr 11 - Feast)
        {
          'date': const EthiopianDate(year: 2017, month: 5, day: 11),
          'isFasting': false,
        },
        // 20. Nineveh 2015 EC (uses calculated start date)
        {
          'date': EthiopianDate.fromMap(
            kenat.getFastingPeriod(kenat.FastingKeys.nineveh, 2015)!['start']!,
          ),
          'isFasting': true,
          'fastKey': 'nineveh',
        },
      ];

      for (final tc in testDates) {
        final date = tc['date'] as EthiopianDate;
        final expectedFasting = tc['isFasting'] as bool;
        final expectedKey = tc['fastKey'] as String?;

        final status = fastStatusFor(date);
        expect(
          status.isFasting,
          equals(expectedFasting),
          reason: 'Failed for date: $date',
        );

        if (expectedKey != null) {
          expect(
            status.active.any((f) => f.key == expectedKey),
            isTrue,
            reason: 'Expected $expectedKey for date $date',
          );
        }
      }
    });
  });
}
