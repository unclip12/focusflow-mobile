import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Provides a true background isolate timer that updates the foreground notification.
class BackgroundTimerService {
  static const int _notificationId = 888;
  static const String _channelId = 'focusflow_timer_bg';
  
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create a dedicated channel for the background service notification
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    if (Platform.isAndroid) {
       await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              'Background Timer',
              description: 'Shows active flow session timer',
              importance: Importance.low, // Low importance so it doesn't pop up over and over
            ),
          );
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'FocusFlow',
        initialNotificationContent: 'Session Active',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.specialUse], // depending on Android 14 requirements, might need 'specialUse' or 'shortService'
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> start({required String activityName, required int elapsedSeconds}) async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    service.invoke('setTimer', {
      'activityName': activityName,
      'elapsedSeconds': elapsedSeconds,
    });
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  static Future<int?> getElapsed() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) return null;
    service.invoke('getElapsed');
    final response = await service.on('elapsedResponse').first;
    if (response == null) return null;
    return response['elapsedSeconds'] as int?;
  }
}

// Ensure this is a top-level function.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  String currentActivity = 'Focus Session';
  int elapsed = 0;
  Timer? timer;

  service.on('setTimer').listen((event) {
    if (event != null) {
      currentActivity = event['activityName'] ?? 'Focus Session';
      elapsed = event['elapsedSeconds'] ?? 0;
    }
  });

  service.on('getElapsed').listen((event) {
    service.invoke('elapsedResponse', {'elapsedSeconds': elapsed});
  });

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  // Tick every second in the background isolate
  timer = Timer.periodic(const Duration(seconds: 1), (t) async {
    elapsed++;

    final dur = Duration(seconds: elapsed);
    final durStr = dur.inHours > 0
        ? '${dur.inHours}h ${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}:${dur.inSeconds.remainder(60).toString().padLeft(2, '0')}s'
        : '${dur.inMinutes.toString().padLeft(2, '0')}:${dur.inSeconds.remainder(60).toString().padLeft(2, '0')}s';

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: '⏳ $currentActivity',
          content: 'Elapsed: $durStr',
        );
      }
    }
    
    // Broadcast back to main isolate just in case we need it
    service.invoke('update', {
      'elapsedSeconds': elapsed,
    });
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
