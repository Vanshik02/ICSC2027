import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

import 'screens/home/home_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/speakers/speakers_screen.dart';
import 'screens/my_schedule/my_schedule_screen.dart';
import 'screens/more/more_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ICSCApp());
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
      MyScheduleScreen( key: ValueKey(myScheduleRefreshKey)),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
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
