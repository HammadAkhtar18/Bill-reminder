import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/bill.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes notification channels and time zones.
  Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedule reminders 3 days, 1 day, and on the due date.
  Future<void> scheduleBillNotifications(Bill bill) async {
    if (bill.id == null) return;
    if (!await _notificationsAllowed()) return;
    await cancelBillNotifications(bill.id!);

    final dueDate = bill.dueDate;
    final notifications = <_BillNotificationRequest>[
      _BillNotificationRequest(
        id: bill.id! * 10 + 1,
        dateTime: dueDate.subtract(const Duration(days: 3)),
        title: 'Upcoming bill in 3 days',
        body: '${bill.name} is due soon.',
      ),
      _BillNotificationRequest(
        id: bill.id! * 10 + 2,
        dateTime: dueDate.subtract(const Duration(days: 1)),
        title: 'Bill due tomorrow',
        body: '${bill.name} is due tomorrow.',
      ),
      _BillNotificationRequest(
        id: bill.id! * 10 + 3,
        dateTime: dueDate,
        title: 'Bill due today',
        body: '${bill.name} is due today.',
      ),
    ];

    for (final notification in notifications) {
      if (notification.dateTime.isAfter(DateTime.now())) {
        await _scheduleNotification(notification);
      }
    }
  }

  Future<void> cancelBillNotifications(int billId) async {
    for (final offset in [1, 2, 3]) {
      await _notificationsPlugin.cancel(billId * 10 + offset);
    }
  }

  Future<bool> _notificationsAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> _scheduleNotification(_BillNotificationRequest request) async {
    const androidDetails = AndroidNotificationDetails(
      'bill_reminders',
      'Bill Reminders',
      channelDescription: 'Notifications for upcoming bill payments',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final scheduledDate = tz.TZDateTime.from(request.dateTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      request.id,
      request.title,
      request.body,
      scheduledDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}

class _BillNotificationRequest {
  _BillNotificationRequest({
    required this.id,
    required this.dateTime,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime dateTime;
  final String title;
  final String body;
}
