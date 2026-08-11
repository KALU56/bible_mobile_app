import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart' as kenat;
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/fasts.dart';
import '../pages/fasting_calendar_screen.dart';

class FastingHomeCard extends StatelessWidget {
  const FastingHomeCard({super.key});

  @override
  Widget build(BuildContext meContext) {
    final c = meContext.colors;
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
      badgeColor = c.fastingActiveBadge;
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
      badgeColor = c.fastingInactiveBadge;
    }

    final cardBg = c.surfaceDim;
    final cardBorder = Border.all(color: c.borderSubtle);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: c.scrim.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            Navigator.of(meContext).push(
              MaterialPageRoute<void>(
                builder: (_) => const FastingCalendarScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Icon Box matching _FreezeCard style
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  alignment: Alignment.center,
                  child: Icon(iconData, color: badgeColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusHeader,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            l10n.fastingCalendarTitle,
                            style: AppTypography.amharicCaption.copyWith(
                              color: c.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: c.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (fastTitle.isNotEmpty)
                        Text(
                          fastTitle,
                          style: AppTypography.amharicLabel.copyWith(
                            color: c.textOnParchment,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (subtitleText.isNotEmpty)
                        Text(
                          subtitleText,
                          style: AppTypography.amharicCaption.copyWith(
                            color: c.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
