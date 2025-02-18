import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './screen/home.dart';
import './screen/order.dart';
import './screen/shops.dart';
import './screen/inbox.dart';
import './screen/product.dart';
import './style.dart';
import './network.dart';
import 'dart:convert';

class Page extends StatefulWidget {
  const Page({super.key, required this.title, required this.fcmToken,this.type});
  final String title;
  final String fcmToken;
  final String? type;

  @override
  Pages createState() => Pages();
}

class Pages extends State<Page> {
  int _selectedIndex = 0;
  final List<Map<String, String>> _notifications = []; // 通知リスト
  final _pageWidgets = <Widget>[];
  late NetworkHandler _networkHandler;
  late Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  String? _myToken;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _networkHandler = NetworkHandler();
    _initializeFirebaseMessaging();
    _loadNotifications();

    _pageWidgets.addAll([
      const HomePage(),
      const ShopsPage(),
      OrderPage(fcmToken: widget.fcmToken),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.type != null) {
        _navigateToInbox();
      }
    });
  }

  Future<void> _loadNotifications() async {
    _notifications.clear();
    final prefs = await SharedPreferences.getInstance();
    final savedNotifications = prefs.getStringList('notifications') ?? [];
    debugPrint('Saved notifications in SharedPreferences: $savedNotifications'); // デバッグログ
    setState(() {
      try {
        _notifications.addAll(
          savedNotifications.map((e) {
            final decoded = json.decode(e);
            if (decoded is Map<String, dynamic>) {
              // すべての値を文字列に変換
              return decoded.map((key, value) => MapEntry(key, value.toString()));
            } else {
              throw FormatException('通知データが無効な形式です: $decoded');
            }
          }).toList().reversed.toList(),
        );
      } catch (e) {
        debugPrint('通知データの読み込み中にエラーが発生: $e');
      }
    });
    debugPrint('Loaded notifications in _notifications: $_notifications'); // デバッグログ
  }

  Future<void> _navigateToInbox() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InboxPage(
          notifications: _notifications, // 保存された通知を渡す
          deviceToken: widget.fcmToken,
          initialTab: widget.type ?? '', // type を初期タブとして渡す
        ),
      ),
    );

    if (result == 'shops') {
      setState(() {
        _selectedIndex = 1;
      });
    } else if (result == 'products') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProductPage(isFromHomePage: true),
        ),
      );
    }
  }

  void _initializeFirebaseMessaging() {
    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        if (message.data['to'] == _myToken) {
          final notification = {
            'title': message.notification?.title ?? 'No Title',
            'body': message.notification?.body ?? 'No Body',
          };
          debugPrint(
            "Notification Received for my token: ${message.notification!.title}, ${message.notification!.body}",
          ); // デバッグログ
        } else {
          debugPrint("Notification ignored: Not for my token"); // デバッグログ
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _messageSubscription?.cancel(); // FirebaseMessagingリスナーの解除
    super.dispose();
  }

  void onItemTapped(int index) async{
    if (await _networkHandler.checkConnectivity(context)) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _handlePopInvoked() {
    if (_selectedIndex == 0) {
      SystemNavigator.pop();
    } else {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Standard AppBar',
      home: WillPopScope(
        onWillPop: () async {
          _handlePopInvoked();
          return false;
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56 * (SizeConfig.screenHeightRatio ?? 1.0)),
            child: AppBar(
              centerTitle: true,
              title: Text('LatinOne', style: Default_title_Style(context)),
              backgroundColor: Colors.brown,
              leading: IconButton(
                icon: const Icon(Icons.inbox),
                onPressed: () async {
                  _loadNotifications();
                  if (await _networkHandler.checkConnectivity(context)) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InboxPage(
                          notifications: _notifications, // 保存された通知を渡す
                          deviceToken: widget.fcmToken,
                        ),
                      ),
                    );
                    if (result == 'shops') {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    } else if (result == 'products') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductPage(isFromHomePage: true),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _pageWidgets,
          ),
          bottomNavigationBar: Container(
            height: 65 * (SizeConfig.screenHeightRatio ?? 1.0),
            child: BottomNavigationBar(
              iconSize: 24 * (SizeConfig.screenHeightRatio ?? 1.0),
              selectedLabelStyle: TextStyle(fontSize: 16.0 * (SizeConfig.screenHeightRatio ?? 1.0)),
              unselectedLabelStyle: TextStyle(fontSize: 14.0 * (SizeConfig.screenHeightRatio ?? 1.0)),
              currentIndex: _selectedIndex,
              onTap: onItemTapped,
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'shops',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'order',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


