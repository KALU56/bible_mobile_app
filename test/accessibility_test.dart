import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bibleflutter/core/theme/app_colors.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/widgets/app_bottom_nav.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/verse_action_bar.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/toolbar.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/chapter_page.dart';
import 'package:bibleflutter/features/books/presentation/widgets/edition_switcher.dart';
import 'package:bibleflutter/features/books/data/models/book.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/core/annotations/annotation_models.dart';
import 'package:bibleflutter/core/l10n/l10n.dart';

void main() {
  final AppStrings sEn = EnStrings();
  final testTheme = ThemeData(
    extensions: const [AppColorScheme.light],
  );

  group('Accessibility & Semantics Tests', () {
    testWidgets('VerseActionBar renders semantic labels and handles state announcements',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: VerseActionBar(
              s: sEn,
              isDark: false,
              surfaceColor: Colors.white,
              textColor: Colors.black,
              isBookmarked: true,
              highlightColor: null,
              hasNote: false,
              onBookmark: () {},
              onHighlight: () {},
              onNote: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify active state for Bookmark ("Bookmarked")
      expect(find.bySemanticsLabel(RegExp(r'Bookmarked')), findsOneWidget);
      // Verify inactive state for Note ("Add note")
      expect(find.bySemanticsLabel(RegExp(r'Add note')), findsOneWidget);
      // Verify other actions
      expect(find.bySemanticsLabel(RegExp(r'Share verse')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Highlight verse')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Copy verse')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ReaderToolbar has proper Semantics buttons and labels',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      const entry = BookIndexEntry(
        id: '1',
        bookNumber: 1,
        bookNameEn: 'Genesis',
        bookNameAm: 'ኦሪት ዘፍጥረት',
        bookShortNameEn: 'GEN',
        bookShortNameAm: 'ዘፍ',
        chapterCount: 50,
        testament: 'ot',
      );

      const sheetTheme = EditionSheetTheme(
        surface: Colors.white,
        text: Colors.black,
        muted: Colors.grey,
        accent: Colors.amber,
        border: Colors.grey,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: L10n(
            initialLanguage: AppLanguage.english,
            child: MaterialApp(
              theme: testTheme,
              home: Scaffold(
                body: ReaderToolbar(
                  entry: entry,
                  currentChapter: 0,
                  useGeez: false,
                  isAmharic: false,
                  bgColor: Colors.white,
                  textColor: Colors.black,
                  mutedColor: Colors.grey,
                  accentColor: Colors.amber,
                  sheetTheme: sheetTheme,
                  s: sEn,
                  onBack: () {},
                  onFontSettings: () {},
                  onSearch: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Font settings')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Search')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Chapter selector')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('AppBottomNav wraps tabs in Semantics with hints',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: Settings(
              notifier: ValueNotifier(const AppSettings()),
              child: L10n(
                initialLanguage: AppLanguage.english,
                child: AppBottomNav(
                  selectedIndex: 0,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Home')), findsAtLeastNWidgets(1));
      expect(find.bySemanticsLabel(RegExp(r'Books')), findsAtLeastNWidgets(1));
      handle.dispose();
    });

    testWidgets('VerseView uses MergeSemantics to unify verse number and body',
        (WidgetTester tester) async {
      const verse = Verse(
        ord: 1,
        verseNumber: 1,
        label: '1',
        text: 'In the beginning God created the heavens and the earth.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: VerseView(
              verse: verse,
              verseKey: '1_1_1',
              selected: false,
              fontSize: 18.0,
              fontFamily: 'Inter',
              textColor: Colors.black,
              accentColor: Colors.amber,
              isDark: false,
              useGeez: false,
              annotations: const ChapterAnnotations(),
              onVerseTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mergeSemanticsFinder = find.byType(MergeSemantics);
      expect(mergeSemanticsFinder, findsOneWidget);

      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(find.byType(MergeSemantics));
      expect(node.label, contains('In the beginning'));
      handle.dispose();
    });

    test('Color contrast audit meets WCAG AA (>= 4.5:1) for reader themes', () {
      double calculateLuminance(Color color) {
        double r = color.r;
        double g = color.g;
        double b = color.b;
        r = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
        g = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
        b = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
      }

      double contrastRatio(Color c1, Color c2) {
        final l1 = calculateLuminance(c1);
        final l2 = calculateLuminance(c2);
        final lighter = math.max(l1, l2);
        final darker = math.min(l1, l2);
        return (lighter + 0.05) / (darker + 0.05);
      }

      // Parchment theme
      const parchmentBg = AppColors.parchment;
      const parchmentText = AppColors.textOnParchment;
      final parchmentRatio = contrastRatio(parchmentBg, parchmentText);
      expect(parchmentRatio, greaterThanOrEqualTo(4.5));

      // Dark / Night theme
      const darkBg = AppColors.readerShellDarkBg;
      const darkText = AppColors.readerShellDarkText;
      final darkRatio = contrastRatio(darkBg, darkText);
      expect(darkRatio, greaterThanOrEqualTo(4.5));
    });
  });
}
