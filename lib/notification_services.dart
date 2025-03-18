import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ! Todo check the permissions of the notification service
  void requestNotificationPermission() async {
    final NotificationSettings notificationSettings =
        await firebaseMessaging.requestPermission(
      sound: true,
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );

    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print("Android Notification Permission Active");
      }
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print("IOS Notification Permission Active");
      }
    } else {
      // Todo Send User to setting to open the notification
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
  }

  // ! Todo get devices token
  Future<String> getDeviceToken() async {
    String? token = await firebaseMessaging.getToken();
    return token!;
  }

  // ! Todo refresh token
  void isRefreshToken() async {
    firebaseMessaging.onTokenRefresh.listen((event) {
      event.toString();
    });
  }

  // ! Todo initialize the android and ios settings and icon

  void initLocalNotifications(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var android = const AndroidInitializationSettings("@mipmap/ic_launcher");
    var ios = const DarwinInitializationSettings();
    final initializations = InitializationSettings(android: android, iOS: ios);
    await localNotificationsPlugin.initialize(
      initializations,
      onDidReceiveNotificationResponse: (payload) {
        handleMessage(context, message);
      },
    );
  }

  // ! Todo listen the notification
  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title);
        print(message.notification!.body);
      }
      if (Platform.isIOS) {
        if (context.mounted) {
          forgroundMessage();
        }
      }
      if (Platform.isAndroid) {
        if (context.mounted) {
          initLocalNotifications(context, message);
          showNotification(message);
        }
      }
    });
  }

  //! Todo showNotification
  Future<void> showNotification(RemoteMessage message) async {
    // Check if message.notification is null (important for silent notifications)
    if (message.notification == null) return;

    // Define a default notification channel ID (for Android)
    String channelId = "default_channel";
    String channelName = "General Notifications";

    if (Platform.isAndroid && message.notification!.android != null) {
      channelId = message.notification!.android!.channelId ?? "default_channel";
      channelName =
          message.notification!.android!.channelId ?? "General Notifications";
    }

    // Android Notification Channel (Avoid null errors)
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.max,
      showBadge: true,
      playSound: true,
    );

    // Android Notification Details
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channel.id, // Use the non-null channel ID
      channel.name,
      importance: Importance.high,
      priority: Priority.high,
      ticker: "ticker",
      playSound: true,
    );

    // iOS Notification Details
    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine Android & iOS notification details
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    Future.delayed(Duration.zero, () {
      localNotificationsPlugin.show(
        message.hashCode, // Unique ID for the notification
        message.notification!.title ?? "New Notification",
        message.notification!.body ?? "Tap to open",
        notificationDetails,
      );
    });
  }

  // !Todo when app is background and terminated
  Future<void> setUpInteractMessage(BuildContext context) async {
    //! when app is terminated
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      if (context.mounted) {
        // Show EasyLoading spinner
        // Todo I Use this for the loading not show in splash screen for 3 seconds
        await Future.delayed(Duration(seconds: 3));

        Future.delayed(Duration(seconds: 5), () {
          if (context.mounted) {
            handleMessage(context, message);
          }
        });
      }
    }

    //! when app is background

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      if (context.mounted) {
        handleMessage(context, event);
      }
    });
  }

  // ! Todo ios notification message
  Future forgroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ! when user tap on the notification
  void handleMessage(BuildContext context, RemoteMessage message) {
    if (kDebugMode) {
      print(message.data);
    }
  }
}
