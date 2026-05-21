import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kenat/kenat.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../settings/app_settings.dart';
import '../deep_links/deep_link_uri.dart';
import '../../features/books/data/repositories/bible_repository.dart';
import '../../features/books/presentation/pages/reader_screen.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingPayload;
  late final BibleRepository _repository;
  bool _initialized = false;

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;
  set navigatorKey(GlobalKey<NavigatorState>? value) {
    _navigatorKey = value;
    if (_pendingPayload != null) {
      unawaited(_handlePayload(_pendingPayload!));
      _pendingPayload = null;
    }
  }

  static const int dailyVerseId = 1;
  static const int readingReminderId = 2;
  static const String _defaultDailyVerseTitle = 'Daily Verse';
  static const String _defaultReadingReminderTitle = 'Read today';
  static const String _defaultReadingReminderBody =
      'Open the app and read today.';

  Future<void> init({
    required BibleRepository repository,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _repository = repository;
    this.navigatorKey = navigatorKey;

    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        if (_navigatorKey == null) {
          _pendingPayload = payload;
        } else {
          unawaited(_handlePayload(payload));
        }
      }
    }

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      // Use the identifier returned by FlutterTimezone (a String).
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();
    final exactAlarmsGranted = await androidPlugin
        ?.requestExactAlarmsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final macGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    try {
      // ignore: avoid_print
      print(
        '[NotificationService] requestPermissions results: android=$androidGranted exactAlarms=$exactAlarmsGranted ios=$iosGranted macos=$macGranted',
      );
    } catch (_) {}
    if (androidPlugin != null) {
      return (androidGranted ?? true) && (exactAlarmsGranted ?? true);
    }

    return iosGranted ?? macGranted ?? false;
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> scheduleDailyAt(
    int id,
    TimeOfDay time,
    String title,
    String body, {
    String? payload,
  }) async {
    if (!_initialized) return;

    final scheduledDate = _nextInstanceOf(time);
    final androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily reminders',
      channelDescription: 'Daily verse and reading time reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    try {
      // ignore: avoid_print
      print(
        '[NotificationService] zonedSchedule called id=$id scheduled=$scheduledDate payload=$payload',
      );
    } catch (_) {}
  }

  Future<void> scheduleDailyVerse(TimeOfDay time, String title) async {
    final et = Kenat.now().getEthiopian();
    final month = et['month'] as int;
    final day = et['day'] as int;
    final result = await _repository.loadDailyVerse(month, day);
    if (result == null) {
      await scheduleDailyAt(
        dailyVerseId,
        time,
        title,
        'ቀኑን ያንብቡ',
        payload: 'home',
      );
      return;
    }

    final reference = '${result.bookNameAm} ${result.chapter}:${result.verse}';
    final payload = Uri(
      scheme: 'eotcbible',
      host: 'openinapp',
      path:
          '/${verseDeepLinkSlug(result.bookEntry, result.chapter, result.verse)}',
    ).toString();
    await scheduleDailyAt(
      dailyVerseId,
      time,
      title,
      reference,
      payload: payload,
    );
  }

  Future<void> scheduleReadingReminder(
    TimeOfDay time,
    String title,
    String body,
  ) async {
    await scheduleDailyAt(
      readingReminderId,
      time,
      title,
      body,
      payload: 'home',
    );
  }

  Future<void> restoreScheduledNotifications(AppSettings settings) async {
    if (settings.dailyVerseNotificationEnabled) {
      final time =
          settings.dailyVerseNotificationTime ??
          const TimeOfDay(hour: 6, minute: 0);
      await scheduleDailyVerse(time, _defaultDailyVerseTitle);
    } else {
      await cancel(dailyVerseId);
    }

    if (settings.readingTimeNotificationEnabled) {
      final time =
          settings.readingTimeNotificationTime ??
          const TimeOfDay(hour: 20, minute: 0);
      await scheduleReadingReminder(
        time,
        _defaultReadingReminderTitle,
        _defaultReadingReminderBody,
      );
    } else {
      await cancel(readingReminderId);
    }
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    unawaited(_handlePayload(payload));
  }

  Future<void> _handlePayload(String payload) async {
    if (payload == 'home') {
      _navigateHome();
      return;
    }

    try {
      final uri = Uri.parse(payload);
      final index = await _repository.loadIndex();
      final target = parseDeepLink(uri, index);
      if (target == null) {
        _navigateHome();
        return;
      }
      _navigatorPushReader(target);
    } catch (_) {
      _navigateHome();
    }
  }

  void _navigateHome() {
    final state = navigatorKey?.currentState;
    if (state == null) return;
    state.popUntil((route) => route.isFirst);
  }

  void _navigatorPushReader(DeepLinkTarget target) {
    final state = navigatorKey?.currentState;
    if (state == null) return;
    state.push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          entry: target.entry,
          initialChapterNumber: target.chapter,
          initialVerse: target.verse,
        ),
      ),
    );
  }
}
