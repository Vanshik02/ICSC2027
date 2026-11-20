
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

import 'screens/home/home_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/speakers/speakers_screen.dart';
import 'screens/my_schedule/my_schedule_screen.dart';
import 'screens/more/more_screen.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel notificationChannel =
    AndroidNotificationChannel(
  'icsc_notifications',
  'ICSC 2027 Notifications',
  description: 'Announcements and important conference updates',
  importance: Importance.high,
);

// Handles messages received while the app is in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );

  await localNotifications.initialize(settings);

  final androidPlugin = localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(notificationChannel);
}

Future<void> configureNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Ask the attendee for notification permission.
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notification permission: ${permission.authorizationStatus}');

    // Subscribe attendees who have granted permission.
    if (permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional) {
      await messaging.subscribeToTopic('icsc_2027_all');
      debugPrint('Subscribed to ICSC 2027 notifications.');
    }

    // Handle notifications received while the app is open.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();

      if (title == null && body == null) return;

      await localNotifications.show(
        message.hashCode,
        title ?? 'ICSC 2027',
        body ?? '',
        const NotificationDetails(
        android: AndroidNotificationDetails(
        'icsc_notifications',
        'ICSC 2027 Notifications',
        channelDescription:
          'Announcements and important conference updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  payload: message.data.toString(),
);
    });

    // Handle notification taps when the app is in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.data}');
    });

    // Handle notification taps that launch a terminated app.
    final initialMessage = await messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.data}');
    }
  } catch (e) {
    debugPrint('Notification setup error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await initializeLocalNotifications();

  runApp(const ICSCApp());

  // Request permission after the app has started.
  unawaited(
    Future.delayed(
      const Duration(seconds: 1),
      configureNotifications,
    ),
  );
}

class ICSCApp extends StatelessWidget {
  const ICSCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ICSC 2027',
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  int myScheduleRefreshKey = 0;

  void navigateTo(int index) {
    setState(() {
      selectedIndex = index;

      if (index == 3) {
        myScheduleRefreshKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigate: navigateTo),
      const ScheduleScreen(),
      const SpeakersScreen(),
      MyScheduleScreen(key: ValueKey(myScheduleRefreshKey)),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: navigateTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Programme',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Speakers',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'My Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
