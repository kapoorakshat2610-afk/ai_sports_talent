import 'package:flutter/material.dart';

import '../screens/coach_dashboard.dart';
import '../screens/compare_sessions_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../services/auth_service.dart';

class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({super.key});

  @override
  State<AppBottomNavigation> createState() =>
      _AppBottomNavigationState();
}

class _AppBottomNavigationState
    extends State<AppBottomNavigation> {
  final AuthService _authService = AuthService();

  int _currentIndex = 0;

  bool _loadingRole = true;
  String _role = 'athlete';

  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _items;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _authService.getRole();

    if (!mounted) return;

    _role = role ?? 'athlete';

    _buildNavigation();

    setState(() {
      _loadingRole = false;
    });
  }

  void _buildNavigation() {
  _screens = [
    const HomeScreen(),
    const DashboardScreen(),
    const CompareSessionsScreen(),
    const LeaderboardScreen(),
    const HistoryScreen(),
  ];

  _items = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.compare_arrows),
      label: 'Compare',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.emoji_events),
      label: 'Leaderboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'History',
    ),
  ];

  if (_role == 'coach') {
    // Put Coach before History.
    _screens.insert(
      4,
      const CoachDashboard(),
    );

    _items.insert(
      4,
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups),
        label: 'Coach',
      ),
    );
  }
}

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentIndex >= _screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type:
            BottomNavigationBarType.fixed,
        items: _items,
      ),
    );
  }
}