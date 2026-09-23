import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';
import '../models/workout.dart';
import 'timeline.dart';

/// Keeps the workout audible while the app is suspended.
///
/// iOS stops Dart timers in the background, so before the app goes away the
/// upcoming interval changes are handed to the system as local
/// notifications. Each fires three seconds early and plays a bundled sound
/// with the "3, 2, 1" ticks followed by the cue (see
/// tool/gen_notification_sounds.dart). Everything is cancelled as soon as the
/// app is back in front, where [CuePlayer] takes over again.
class BackgroundCues {
  BackgroundCues._();
  static final instance = BackgroundCues._();

  /// iOS keeps at most 64 pending notifications per app.
  static const maxPending = 60;
  static const leadTime = Duration(seconds: 3);

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _init;

  Future<void> _ensureInit() => _init ??= () async {
        tzdata.initializeTimeZones();
        await _plugin.initialize(
          settings: const InitializationSettings(
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestSoundPermission: false,
              requestBadgePermission: false,
            ),
          ),
        );
      }();

  Future<bool> requestPermission() async {
    try {
      await _ensureInit();
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('BackgroundCues permission failed: $e');
      return false;
    }
  }

  Future<void> schedule(
    List<({DateTime at, Segment? next})> changes, {
    required S s,
    required bool sound,
  }) async {
    try {
      await _ensureInit();
      await _plugin.cancelAll();
      final now = DateTime.now();
      var id = 0;
      for (final change in changes.take(maxPending)) {
        final fireAt = change.at.subtract(leadTime);
        if (fireAt.isBefore(now.add(const Duration(milliseconds: 500)))) continue;
        final next = change.next;
        final file = switch (next?.type) {
          null => 'cue_finish.wav',
          IntervalType.rest => 'cue_rest.wav',
          _ => 'cue_work.wav',
        };
        await _plugin.zonedSchedule(
          id: id++,
          title: next == null ? s.bgFinishTitle : '${next.name} · ${formatClock(next.seconds)}',
          body: next == null ? s.bgFinishBody : s.bgInThree,
          scheduledDate: tz.TZDateTime.from(fireAt, tz.UTC),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          notificationDetails: NotificationDetails(
            iOS: DarwinNotificationDetails(
              // Only shown when the app is not in front; in front the app
              // plays its own cues and these are cancelled anyway.
              presentAlert: false,
              presentBanner: false,
              presentList: false,
              presentSound: false,
              sound: sound ? file : null,
              threadIdentifier: 'workout',
              interruptionLevel: InterruptionLevel.active,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('BackgroundCues schedule failed: $e');
    }
  }

  Future<void> cancel() async {
    try {
      if (_init == null) return;
      await _ensureInit();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('BackgroundCues cancel failed: $e');
    }
  }
}
