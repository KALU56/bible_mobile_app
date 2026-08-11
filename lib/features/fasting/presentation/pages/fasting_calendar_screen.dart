import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart' as kenat;
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/fasts.dart';

class FastingCalendarScreen extends StatefulWidget {
  const FastingCalendarScreen({super.key});

  @override
  State<FastingCalendarScreen> createState() => _FastingCalendarScreenState();
}

class _FastingCalendarScreenState extends State<FastingCalendarScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  late EthiopianDate _todayEt;
  late EthiopianDate _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final ec = kenat.toEC(now.year, now.month, now.day);
    _selectedYear = ec['year']!;
    _selectedMonth = ec['month']!;
    _todayEt = EthiopianDate(
      year: ec['year']!,
      month: ec['month']!,
      day: ec['day']!,
    );
    _selectedDate = _todayEt;
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 13;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 13) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _selectedYear = _todayEt.year;
      _selectedMonth = _todayEt.month;
      _selectedDate = _todayEt;
    });
  }

  @override
  Widget build(BuildContext meContext) {
    final l10n = L10n.of(meContext);
    final isAmharic = l10n is AmStrings;
    final settings = Settings.of(meContext);
    final theme = Theme.of(meContext);
    final isDark = theme.brightness == Brightness.dark;

    final lang = isAmharic ? 'amharic' : 'english';
    final gridData = kenat.createMonthGrid({
      'year': _selectedYear,
      'month': _selectedMonth,
      'useGeez': settings.useGeezNumbers,
      'weekdayLang': lang,
      'mode': 'orthodox',
    });

    final monthName = gridData['monthName'] as String? ?? '';
    final yearLabel = settings.useGeezNumbers
        ? kenat.toGeez(_selectedYear)
        : _selectedYear.toString();
    final headers = (gridData['headers'] as List?)?.cast<String>() ?? [];
    final days =
        (gridData['days'] as List?)?.cast<Map<String, dynamic>?>() ?? [];

    final selectedDayStatus = fastStatusFor(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fastingCalendarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: l10n.savedToday,
            onPressed: _goToToday,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Header & Navigation
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _previousMonth,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$monthName $yearLabel',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),

            // Weekday Headers Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: headers
                    .map(
                      (h) => Expanded(
                        child: Center(
                          child: Text(
                            h,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Calendar Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final cell = days[index];
                  if (cell == null) {
                    return const SizedBox.shrink();
                  }

                  final etMap = cell['ethiopian'] as Map<String, dynamic>;
                  final dayNum = etMap['day'] as int;
                  final dayDate = EthiopianDate(
                    year: etMap['year'] as int,
                    month: etMap['month'] as int,
                    day: dayNum,
                  );

                  final isToday = dayDate == _todayEt;
                  final isSelected = dayDate == _selectedDate;
                  final dayStatus = fastStatusFor(dayDate);

                  final dayStr = settings.useGeezNumbers
                      ? kenat.toGeez(dayNum)
                      : dayNum.toString();

                  final c = meContext.colors;
                  final Color cellBg;
                  if (isSelected) {
                    cellBg = theme.colorScheme.primaryContainer;
                  } else if (dayStatus.isFasting) {
                    cellBg = c.fastingActiveCardBg;
                  } else {
                    cellBg = isDark
                        ? theme.colorScheme.surfaceContainer
                        : theme.colorScheme.surfaceContainerLow;
                  }

                  final Color textColor = isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : (dayStatus.isFasting
                            ? c.fastingActiveBadge
                            : theme.textTheme.bodyMedium?.color ??
                                  Colors.black);

                  return Material(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedDate = dayDate;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : (isSelected
                                    ? Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 1,
                                      )
                                    : null),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayStr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                fontWeight:
                                    (isToday ||
                                        isSelected ||
                                        dayStatus.isFasting)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (dayStatus.isFasting)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: c.fastingActiveBadge,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Selected Day Detail View
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Title Row
                    Row(
                      children: [
                        Text(
                          _formatEthiopianDateHeader(
                            _selectedDate,
                            isAmharic,
                            settings.useGeezNumbers,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selectedDayStatus.isFasting
                                ? meContext.colors.fastingActiveCardBg
                                : meContext.colors.fastingInactiveCardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            selectedDayStatus.isFasting
                                ? l10n.fastingToday
                                : l10n.notFasting,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selectedDayStatus.isFasting
                                  ? meContext.colors.fastingActiveBadge
                                  : meContext.colors.fastingInactiveBadge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (selectedDayStatus.isFasting) ...[
                      Text(
                        isAmharic ? 'የዕለቱ ጾሞች' : 'Fasting Periods',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...selectedDayStatus.active.map(
                        (fast) => _buildFastDetailCard(
                          context: context,
                          fast: fast,
                          isAmharic: isAmharic,
                          useGeez: settings.useGeezNumbers,
                        ),
                      ),
                    ] else ...[
                      if (selectedDayStatus.next != null) ...[
                        Text(
                          isAmharic ? 'ሚቀጥለው ጾም' : 'Next Upcoming Fast',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildNextFastCard(
                          context: context,
                          fast: selectedDayStatus.next!,
                          daysRemaining: selectedDayStatus.daysRemaining ?? 0,
                          isAmharic: isAmharic,
                          useGeez: settings.useGeezNumbers,
                          daysRemainingText: l10n.daysRemaining,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEthiopianDateHeader(
    EthiopianDate date,
    bool isAmharic,
    bool useGeez,
  ) {
    final monthName = isAmharic
        ? kenat.MonthNames.amharic[date.month - 1]
        : kenat.MonthNames.english[date.month - 1];
    final dayStr = useGeez ? kenat.toGeez(date.day) : date.day.toString();
    final yearStr = useGeez ? kenat.toGeez(date.year) : date.year.toString();
    return '$monthName $dayStr, $yearStr';
  }

  Widget _buildFastDetailCard({
    required BuildContext context,
    required FastPeriod fast,
    required bool isAmharic,
    required bool useGeez,
  }) {
    final theme = Theme.of(context);
    final title = isAmharic ? fast.nameAm : fast.nameEn;

    final info = kenat.getFastingInfo(
      _mapToKenatKey(fast.key),
      fast.start.year,
      {'lang': isAmharic ? 'amharic' : 'english'},
    );
    final description = info?['description'] as String? ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bookmark_rounded,
                size: 18,
                color: context.colors.fastingActiveBadge,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextFastCard({
    required BuildContext context,
    required FastPeriod fast,
    required int daysRemaining,
    required bool isAmharic,
    required bool useGeez,
    required String daysRemainingText,
  }) {
    final theme = Theme.of(context);
    final title = isAmharic ? fast.nameAm : fast.nameEn;
    final diffStr = useGeez
        ? kenat.toGeez(daysRemaining)
        : daysRemaining.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.upcoming_rounded,
            size: 20,
            color: context.colors.fastingInactiveBadge,
          ),

          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$diffStr $daysRemainingText',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mapToKenatKey(String key) {
    switch (key) {
      case 'nineveh':
        return kenat.FastingKeys.nineveh;
      case 'abiyTsome':
        return kenat.FastingKeys.abiyTsome;
      case 'tsomeHawaryat':
        return kenat.FastingKeys.tsomeHawaryat;
      case 'tsomeNebiyat':
        return kenat.FastingKeys.tsomeNebiyat;
      case 'filseta':
        return kenat.FastingKeys.filseta;
      case 'tsomeDihnet':
        return kenat.FastingKeys.tsomeDihenet;
      default:
        return kenat.FastingKeys.abiyTsome;
    }
  }
}
