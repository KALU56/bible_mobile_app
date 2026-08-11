import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart' as kenat;
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../data/fasts.dart';
import '../pages/fasting_calendar_screen.dart';

class FastingHomeCard extends StatelessWidget {
  const FastingHomeCard({super.key});

  @override
  Widget build(BuildContext meContext) {
    final l10n = L10n.of(meContext);
    final isAmharic = l10n is AmStrings;
    final settings = Settings.of(meContext);
    final theme = Theme.of(meContext);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final ec = kenat.toEC(now.year, now.month, now.day);
    final todayEt = EthiopianDate(
      year: ec['year']!,
      month: ec['month']!,
      day: ec['day']!,
    );

    final status = fastStatusFor(todayEt);

    final String statusHeader;
    final String fastTitle;
    final String subtitleText;
    final IconData iconData;
    final Color badgeColor;

    if (status.isFasting) {
      statusHeader = l10n.fastingToday;
      final activeFast = status.active.firstWhere(
        (f) => f.key != 'tsomeDihnet',
        orElse: () => status.active.first,
      );

      fastTitle = isAmharic ? activeFast.nameAm : activeFast.nameEn;

      final remaining = status.daysRemaining ?? 1;
      final remainingStr = settings.useGeezNumbers
          ? kenat.toGeez(remaining)
          : remaining.toString();
      subtitleText = '$remainingStr ${l10n.daysRemaining}';

      iconData = Icons.church_rounded;
      badgeColor = isDark ? const Color(0xFFD97706) : const Color(0xFFB45309);
    } else {
      statusHeader = l10n.notFasting;
      if (status.next != null) {
        final nextFast = status.next!;
        final name = isAmharic ? nextFast.nameAm : nextFast.nameEn;
        final diff = status.daysRemaining ?? 0;

        if (diff == 1) {
          fastTitle = '$name (${l10n.fastBeginsTomorrow})';
          subtitleText = l10n.fastBeginsTomorrow;
        } else {
          fastTitle = name;
          final diffStr = settings.useGeezNumbers
              ? kenat.toGeez(diff)
              : diff.toString();
          subtitleText = '$diffStr ${l10n.daysRemaining}';
        }
      } else {
        fastTitle = '';
        subtitleText = '';
      }
      iconData = Icons.calendar_today_rounded;
      badgeColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    }

    final cardBg = isDark
        ? Theme.of(meContext).colorScheme.surfaceContainerHigh
        : Theme.of(meContext).colorScheme.surface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(10.0),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: () {
            Navigator.of(meContext).push(
              MaterialPageRoute<void>(
                builder: (_) => const FastingCalendarScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: badgeColor, size: 16),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            statusHeader,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            l10n.fastingCalendarTitle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (fastTitle.isNotEmpty)
                            Flexible(
                              child: Text(
                                fastTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (fastTitle.isNotEmpty && subtitleText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                              ),
                              child: Text(
                                '•',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          if (subtitleText.isNotEmpty)
                            Text(
                              subtitleText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
