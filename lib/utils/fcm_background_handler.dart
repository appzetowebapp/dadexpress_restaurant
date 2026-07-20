// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_master_app/config/app_config.dart';

// /// Background message handler for Firebase Cloud Messaging
// /// This must be a top-level function
// /// Handles notifications when app is in background or terminated state
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint('📨 Background message received: ${message.messageId}');
//   debugPrint('📨 Message data: ${message.data}');

//   // Initialize notification plugin for background messages
//   final FlutterLocalNotificationsPlugin notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // Use AppConfig for consistency
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings(AppConfig.notificationIcon);

//   const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//     requestAlertPermission: true,
//     requestBadgePermission: true,
//     requestSoundPermission: true,
//   );

//   const InitializationSettings initSettings = InitializationSettings(
//     android: androidSettings,
//     iOS: iosSettings,
//   );

//   await notificationsPlugin.initialize(initSettings);

//   // Create notification channel for Android using AppConfig
//   final AndroidNotificationChannel channel = AndroidNotificationChannel(
//     AppConfig.notificationChannelId,
//     AppConfig.notificationChannelName,
//     description: AppConfig.notificationChannelDescription,
//     importance: Importance.high,
//     playSound: true,
//     enableVibration: true,
//     showBadge: true,
//     enableLights: true,
//     ledColor: AppConfig.notificationColor,
//   );

//   await notificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

//   RemoteNotification? notification = message.notification;
//   Map<String, dynamic>? data = message.data;

//   // Create unique ID for this notification
//   final String notificationId = message.messageId ??
//       '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

//   debugPrint('📨 Background notification ID: $notificationId');

//   // Handle notification payload (when app is in background/terminated)
//   if (notification != null) {
//     // Android notification details using AppConfig
//     final AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       AppConfig.notificationChannelId, // Must match channel ID
//       AppConfig.notificationChannelName,
//       channelDescription: AppConfig.notificationChannelDescription,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//       icon: AppConfig.notificationIcon,
//       showWhen: true,
//       styleInformation: const BigTextStyleInformation(''),
//       color: AppConfig.notificationColor,
//     );

//     // iOS notification details
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     final NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     // Show notification
//     // Use a hash of the notification ID to generate a consistent integer ID
//     // This prevents duplicate notifications even if the same message is processed multiple times
//     final int localNotificationId = notificationId.hashCode.abs() % 2147483647;

//     await notificationsPlugin.show(
//       localNotificationId,
//       notification.title ?? 'Notification',
//       notification.body ?? '',
//       notificationDetails,
//       payload: data.toString(),
//     );

//     debugPrint(
//         '✅ Background notification shown: ${notification.title} (ID: $localNotificationId)');
//   } else if (data.isNotEmpty) {
//     // Handle data-only messages (messages without notification payload)
//     debugPrint('📨 Data-only message received in background');
//     final title = data['title']?.toString() ?? 'Notification';
//     final body = data['body']?.toString() ?? data['message']?.toString() ?? '';

//     // Android notification details using AppConfig
//     final AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       AppConfig.notificationChannelId,
//       AppConfig.notificationChannelName,
//       channelDescription: AppConfig.notificationChannelDescription,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//       icon: AppConfig.notificationIcon,
//       showWhen: true,
//       styleInformation: const BigTextStyleInformation(''),
//       color: AppConfig.notificationColor,
//     );

//     // iOS notification details
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     final NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     // Generate notification ID from data
//     final int localNotificationId = notificationId.hashCode.abs() % 2147483647;

//     await notificationsPlugin.show(
//       localNotificationId,
//       title,
//       body,
//       notificationDetails,
//       payload: data.toString(),
//     );

//     debugPrint(
//         '✅ Background data-only notification shown: $title (ID: $localNotificationId)');
//   }
// }















import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:webview_master_app/config/app_config.dart';

/// Background message handler for Firebase Cloud Messaging
/// This must be a top-level function
/// Handles notifications when app is in background or terminated state
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background message received: ${message.messageId}');
  debugPrint('📨 Message data: ${message.data}');

  // Notify overlay if this is a new order
  // You can customize the condition based on your backend FCM payload
  final type = message.data['type']?.toString();
  final title = message.notification?.title?.toLowerCase() ?? '';
  final body = message.notification?.body?.toLowerCase() ?? '';
  
  final isOrder = type == 'order' || 
                  type == 'new_order' || 
                  type == 'NEW_ORDER' ||
                  type == 'new_order_available' ||
                  (title.contains('new') && title.contains('order')) ||
                  (body.contains('new') && body.contains('order'));

  if (isOrder) {
    try {
      debugPrint('🔔 New order detected, notifying overlay and playing sound...');
      
      // Start Ringtone via Background Service
      try {
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          debugPrint('📣 Invoking startRingtone in background service');
          service.invoke('startRingtone');
        } else {
          debugPrint('⚠️ Background service is not running, ringtone may not play via AudioPlayer');
        }
      } catch (e) {
        debugPrint('❌ Error invoking background ringtone: $e');
      }

      await FlutterOverlayWindow.shareData(jsonEncode({
        'type': 'NEW_ORDER',
        'orderId': message.data['orderId'] ?? message.data['id'],
        'title': message.notification?.title ?? 'New Order Received! 🍕',
        'body': message.notification?.body ?? 'You have a new order',
      }));
      
      // Auto-open application using multiple methods for reliability
      debugPrint('🚀 Auto-opening application for order...');
      
      // Method 1: Use LaunchApp plugin
      try {
        await LaunchApp.openApp(
          androidPackageName: 'com.dadexpress.restaurant',
          openStore: false,
        );
      } catch (e) {
        debugPrint('❌ LaunchApp.openApp failed: $e');
      }

      // Method 2: Manual "Bring to Front" via MethodChannel
      try {
        const platform = MethodChannel('com.dadexpress.restaurant/geolocation');
        await platform.invokeMethod('bringToFront');
        debugPrint('✅ Manual bringToFront invoked from background');
      } catch (e) {
        debugPrint('❌ Manual bringToFront failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Failed to notify overlay or auto-open app: $e');
    }
  }

  // Initialize notification plugin for background messages
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Use AppConfig for consistency
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings(AppConfig.notificationIcon);

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await notificationsPlugin.initialize(initSettings);

  // Create notification channel for Android using AppConfig
  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    AppConfig.notificationChannelId,
    AppConfig.notificationChannelName,
    description: AppConfig.notificationChannelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    enableLights: true,
    ledColor: AppConfig.notificationColor,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  RemoteNotification? notification = message.notification;
  Map<String, dynamic>? data = message.data;

  // Create unique ID for this notification
  final String notificationId = message.messageId ??
      '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

  debugPrint('📨 Background notification ID: $notificationId');

  // Handle notification payload (when app is in background/terminated)
  if (notification != null) {
    // Android notification details using AppConfig
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConfig.notificationChannelId, // Must match channel ID
      AppConfig.notificationChannelName,
      channelDescription: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: AppConfig.notificationIcon,
      showWhen: true,
      styleInformation: const BigTextStyleInformation(''),
      color: AppConfig.notificationColor,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    // Use a hash of the notification ID to generate a consistent integer ID
    // This prevents duplicate notifications even if the same message is processed multiple times
    final int localNotificationId = notificationId.hashCode.abs() % 2147483647;

    await notificationsPlugin.show(
      localNotificationId,
      notification.title ?? 'Notification',
      notification.body ?? '',
      notificationDetails,
      payload: data.toString(),
    );

    debugPrint(
        '✅ Background notification shown: ${notification.title} (ID: $localNotificationId)');
  } else if (data.isNotEmpty) {
    // Handle data-only messages (messages without notification payload)
    debugPrint('📨 Data-only message received in background');
    final title = data['title']?.toString() ?? 'Notification';
    final body = data['body']?.toString() ?? data['message']?.toString() ?? '';

    // Android notification details using AppConfig
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      channelDescription: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: AppConfig.notificationIcon,
      showWhen: true,
      styleInformation: const BigTextStyleInformation(''),
      color: AppConfig.notificationColor,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generate notification ID from data
    final int localNotificationId = notificationId.hashCode.abs() % 2147483647;

    await notificationsPlugin.show(
      localNotificationId,
      title,
      body,
      notificationDetails,
      payload: data.toString(),
    );

    debugPrint(
        '✅ Background data-only notification shown: $title (ID: $localNotificationId)');
  }
}
