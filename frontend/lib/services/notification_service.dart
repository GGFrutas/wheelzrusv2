import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Request runtime notification permission (Android 13+)
  static Future<void> requestPermission() async {
    if (await Permission.notification.isDenied) {
      PermissionStatus status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint("Notification permission granted");
      } else {
        debugPrint("Notification permission denied");
      }
    }
  }

  /// Initialize notification plugin
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/xlogo');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Show a notification
  static Future<void> showNotification({required String requestNumber}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'upload_channel',
      'Document Uploads',
      channelDescription: 'Upload Status Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      requestNumber.hashCode, // unique id
      'Upload Successful',
      'Request $requestNumber uploaded successfully',
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showAssignmentNotification({
    required String requestNumber,
    required String dispatchType, // DE, PL, DL, PE
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'assignment_channel',
      'New Assignments',
      channelDescription: 'Notifications for new request assignments',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      requestNumber.hashCode,
      '🚚 New Assignment',
      '$dispatchType Request No: $requestNumber has been assigned to you.',
      const NotificationDetails(android: androidDetails),
    );
  }
}
