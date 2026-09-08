import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a local notification (with sound) for the moment a rest period
/// ends, so the user is nudged to start their next set even if they've
/// locked their phone or switched apps.
///
/// Uses the OS's own notification scheduler rather than a Dart `Timer`,
/// since a plain in-app timer gets suspended once the app is backgrounded.
class RestNotificationService {
  RestNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  static const _restCompleteId = 1001;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initAttempted = false;
  bool _ready = false;

  Future<void> initialize() async {
    if (_initAttempted) return;
    _initAttempted = true;

    try {
      tzdata.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (error, stackTrace) {
      debugPrint('Rest notification setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> scheduleRestComplete({
    required int afterSeconds,
    required String exerciseName,
  }) async {
    await initialize();
    if (!_ready) return;

    try {
      await _plugin.zonedSchedule(
        id: _restCompleteId,
        title: 'Rest complete',
        body: 'Time for your next set: $exerciseName',
        scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: afterSeconds)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'rest_timer',
            'Rest timer',
            channelDescription: "Lets you know when a workout's rest period is over.",
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to schedule rest notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelRestComplete() async {
    if (!_ready) return;

    try {
      await _plugin.cancel(id: _restCompleteId);
    } catch (error, stackTrace) {
      debugPrint('Failed to cancel rest notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
