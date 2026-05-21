import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.useGeezNumbers = false,
    this.bodyFontIndex = 0,
    this.titleFontIndex = 0,
    this.fontSize = 17.0,
    this.isDarkReader = false,
    this.continuousReading = false,
    this.dailyVerseNotificationEnabled = false,
    this.readingTimeNotificationEnabled = false,
    this.dailyVerseNotificationTime,
    this.readingTimeNotificationTime,
  });

  final bool useGeezNumbers;

  /// Index into readerFonts[] for verse body text.
  final int bodyFontIndex;

  /// Index into readerFonts[] for section/chapter titles.
  final int titleFontIndex;

  /// Base font size for reading.
  final double fontSize;

  /// App + reader dark theme (Settings “night mode”).
  final bool isDarkReader;

  /// When true, verses flow as a paragraph instead of one verse per line.
  final bool continuousReading;

  /// Whether daily verse notification is enabled.
  final bool dailyVerseNotificationEnabled;

  /// Whether reading time reminder is enabled.
  final bool readingTimeNotificationEnabled;

  /// Daily verse notification time.
  final TimeOfDay? dailyVerseNotificationTime;

  /// Reading time reminder time.
  final TimeOfDay? readingTimeNotificationTime;

  static const _keyUseGeezNumbers = 'useGeezNumbers';
  static const _keyBodyFontIndex = 'bodyFontIndex';
  static const _keyTitleFontIndex = 'titleFontIndex';
  static const _keyFontSize = 'fontSize';
  static const _keyIsDarkReader = 'isDarkReader';
  static const _keyContinuousReading = 'continuousReading';
  static const _keyDailyVerseNotificationEnabled =
      'dailyVerseNotificationEnabled';
  static const _keyReadingTimeNotificationEnabled =
      'readingTimeNotificationEnabled';
  static const _keyDailyVerseNotificationTimeHour =
      'dailyVerseNotificationTimeHour';
  static const _keyDailyVerseNotificationTimeMinute =
      'dailyVerseNotificationTimeMinute';
  static const _keyReadingTimeNotificationTimeHour =
      'readingTimeNotificationTimeHour';
  static const _keyReadingTimeNotificationTimeMinute =
      'readingTimeNotificationTimeMinute';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      useGeezNumbers: prefs.getBool(_keyUseGeezNumbers) ?? false,
      bodyFontIndex: prefs.getInt(_keyBodyFontIndex) ?? 0,
      titleFontIndex: prefs.getInt(_keyTitleFontIndex) ?? 0,
      fontSize: prefs.getDouble(_keyFontSize) ?? 17.0,
      isDarkReader: prefs.getBool(_keyIsDarkReader) ?? false,
      continuousReading: prefs.getBool(_keyContinuousReading) ?? false,
      dailyVerseNotificationEnabled:
          prefs.getBool(_keyDailyVerseNotificationEnabled) ?? false,
      readingTimeNotificationEnabled:
          prefs.getBool(_keyReadingTimeNotificationEnabled) ?? false,
      dailyVerseNotificationTime: _timeOfDayFromPrefs(
        prefs,
        _keyDailyVerseNotificationTimeHour,
        _keyDailyVerseNotificationTimeMinute,
      ),
      readingTimeNotificationTime: _timeOfDayFromPrefs(
        prefs,
        _keyReadingTimeNotificationTimeHour,
        _keyReadingTimeNotificationTimeMinute,
      ),
    );
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseGeezNumbers, settings.useGeezNumbers);
    await prefs.setInt(_keyBodyFontIndex, settings.bodyFontIndex);
    await prefs.setInt(_keyTitleFontIndex, settings.titleFontIndex);
    await prefs.setDouble(_keyFontSize, settings.fontSize);
    await prefs.setBool(_keyIsDarkReader, settings.isDarkReader);
    await prefs.setBool(_keyContinuousReading, settings.continuousReading);
    await prefs.setBool(
      _keyDailyVerseNotificationEnabled,
      settings.dailyVerseNotificationEnabled,
    );
    await prefs.setBool(
      _keyReadingTimeNotificationEnabled,
      settings.readingTimeNotificationEnabled,
    );

    if (settings.dailyVerseNotificationTime != null) {
      await prefs.setInt(
        _keyDailyVerseNotificationTimeHour,
        settings.dailyVerseNotificationTime!.hour,
      );
      await prefs.setInt(
        _keyDailyVerseNotificationTimeMinute,
        settings.dailyVerseNotificationTime!.minute,
      );
    } else {
      await prefs.remove(_keyDailyVerseNotificationTimeHour);
      await prefs.remove(_keyDailyVerseNotificationTimeMinute);
    }

    if (settings.readingTimeNotificationTime != null) {
      await prefs.setInt(
        _keyReadingTimeNotificationTimeHour,
        settings.readingTimeNotificationTime!.hour,
      );
      await prefs.setInt(
        _keyReadingTimeNotificationTimeMinute,
        settings.readingTimeNotificationTime!.minute,
      );
    } else {
      await prefs.remove(_keyReadingTimeNotificationTimeHour);
      await prefs.remove(_keyReadingTimeNotificationTimeMinute);
    }
  }

  static TimeOfDay? _timeOfDayFromPrefs(
    SharedPreferences prefs,
    String hourKey,
    String minuteKey,
  ) {
    final hour = prefs.getInt(hourKey);
    final minute = prefs.getInt(minuteKey);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  AppSettings copyWith({
    bool? useGeezNumbers,
    int? bodyFontIndex,
    int? titleFontIndex,
    double? fontSize,
    bool? isDarkReader,
    bool? continuousReading,
    bool? dailyVerseNotificationEnabled,
    bool? readingTimeNotificationEnabled,
    TimeOfDay? dailyVerseNotificationTime,
    TimeOfDay? readingTimeNotificationTime,
  }) => AppSettings(
    useGeezNumbers: useGeezNumbers ?? this.useGeezNumbers,
    bodyFontIndex: bodyFontIndex ?? this.bodyFontIndex,
    titleFontIndex: titleFontIndex ?? this.titleFontIndex,
    fontSize: fontSize ?? this.fontSize,
    isDarkReader: isDarkReader ?? this.isDarkReader,
    continuousReading: continuousReading ?? this.continuousReading,
    dailyVerseNotificationEnabled:
        dailyVerseNotificationEnabled ?? this.dailyVerseNotificationEnabled,
    readingTimeNotificationEnabled:
        readingTimeNotificationEnabled ?? this.readingTimeNotificationEnabled,
    dailyVerseNotificationTime:
        dailyVerseNotificationTime ?? this.dailyVerseNotificationTime,
    readingTimeNotificationTime:
        readingTimeNotificationTime ?? this.readingTimeNotificationTime,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.useGeezNumbers == useGeezNumbers &&
      other.bodyFontIndex == bodyFontIndex &&
      other.titleFontIndex == titleFontIndex &&
      other.fontSize == fontSize &&
      other.isDarkReader == isDarkReader &&
      other.continuousReading == continuousReading &&
      other.dailyVerseNotificationEnabled == dailyVerseNotificationEnabled &&
      other.readingTimeNotificationEnabled == readingTimeNotificationEnabled &&
      other.dailyVerseNotificationTime == dailyVerseNotificationTime &&
      other.readingTimeNotificationTime == readingTimeNotificationTime;

  @override
  int get hashCode => Object.hash(
    useGeezNumbers,
    bodyFontIndex,
    titleFontIndex,
    fontSize,
    isDarkReader,
    continuousReading,
    dailyVerseNotificationEnabled,
    readingTimeNotificationEnabled,
    dailyVerseNotificationTime,
    readingTimeNotificationTime,
  );
}

class Settings extends InheritedNotifier<ValueNotifier<AppSettings>> {
  Settings({super.key, AppSettings? initial, required super.child})
    : super(notifier: ValueNotifier(initial ?? const AppSettings()));

  static AppSettings of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Settings>();
    assert(
      s != null,
      'No Settings found in widget tree. Wrap your app with Settings().',
    );
    return s!.notifier!.value;
  }

  static void update(BuildContext context, AppSettings updated) {
    final s = context.getInheritedWidgetOfExactType<Settings>();
    assert(s != null, 'No Settings found in widget tree.');
    s!.notifier!.value = updated;
    unawaited(AppSettings.save(updated));
  }

  @override
  bool updateShouldNotify(Settings oldWidget) =>
      notifier!.value != oldWidget.notifier!.value;
}
