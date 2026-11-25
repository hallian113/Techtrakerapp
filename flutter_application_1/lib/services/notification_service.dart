// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tracking_app/utils/constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // ✅ Ask permission (Android 13+ / iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ✅ Setup local notifications (for foreground display)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // ✅ Show notification when app is in FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    const androidDetails = AndroidNotificationDetails(
      'techtracker_channel',
      'TechTracker Notifications',
      channelDescription: 'Punch in/out and attendance alerts',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD4AF37), // Gold
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'TechTracker',
      message.notification?.body ?? '',
      details,
    );
  }

  // ✅ Save FCM token to Firestore so Cloud Function can target this user
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));

      // Keep token updated if it refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      });
    } catch (e) {
      // Silent fail - notifications just won't work, not critical
    }
  }
}
