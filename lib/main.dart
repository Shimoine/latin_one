import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert'; // jsonを使用するため
import 'package:flutter/foundation.dart'; // kIsWebを使用

import './page.dart' as page;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MaterialApp(
    title: 'LatinOne',
    home: ConnectionChecker(),
  ));
}

class ConnectionChecker extends StatefulWidget {
  const ConnectionChecker({Key? key}) : super(key: key);

  @override
  _ConnectionCheckerState createState() => _ConnectionCheckerState();
}

class _ConnectionCheckerState extends State<ConnectionChecker> {
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoConnectionDialog();
    } else {
      await _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.maybeGet('SUPABASE_URL') ?? 'default_url',
      anonKey: dotenv.maybeGet('SUPABASE_KEY') ?? 'default_key',
    );

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }

    final messagingInstance = FirebaseMessaging.instance;
    messagingInstance.requestPermission();

    try {
      final fcmToken = await messagingInstance.getToken();
      debugPrint('FCM TOKEN: $fcmToken');
      await messagingInstance.subscribeToTopic('allUsers');
    } catch (e) {
      debugPrint('Failed to get FCM token or subscribe to topic: $e');
    }

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (!kIsWeb) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'default_notification_channel',
          'プッシュ通知のチャンネル名',
          importance: Importance.max,
        ),
      );
    }

    _initNotification();
  }

  Future<void> _initNotification() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (!kIsWeb && notification != null) {
        await flutterLocalNotificationsPlugin.show(
          0,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'default_notification_channel',
              'プッシュ通知のチャンネル名',
              importance: Importance.max,
              icon: notification.android?.smallIcon,
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    });

    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final payloadMap =
              json.decode(details.payload!) as Map<String, dynamic>;
          debugPrint(payloadMap.toString());
        }
      },
    );
  }

  void _showNoConnectionDialog() {
    if (_isDialogShowing) return; // ダイアログが既に表示されている場合は表示しない

    _isDialogShowing = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ネットワーク接続なし'),
          content: const Text('インターネットに接続されていません。接続を確認してください。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isDialogShowing = false;
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return page.Page(title: 'LatinOne');
  }
}