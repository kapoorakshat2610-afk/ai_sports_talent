import 'package:flutter/material.dart';

import 'navigation/bottom_navigation.dart';
import 'screens/auth_screen.dart';
import 'screens/coach_dashboard.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RunnerAnalyzerApp());
}

class RunnerAnalyzerApp extends StatelessWidget {
  const RunnerAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      title: 'Runner Analyzer',

      

      home: const AuthGate(),

      routes: {
        '/auth': (_) => const AuthScreen(),
        '/app': (_) => const AppBottomNavigation(),
        '/coach': (_) => const CoachRouteGuard(),
      },
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  bool isLoading = true;
  bool isLoggedIn = false;

  String role = 'athlete';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final loggedIn =
          await _authService.isLoggedIn();

      if (!loggedIn) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isLoggedIn = false;
        });

        return;
      }

      final user =
          await _authService.loadCurrentUser();

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isLoggedIn = true;
        role =
            user['role']?.toString() ??
                'athlete';
      });
    } catch (_) {
      await _authService.logout();

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isLoggedIn = false;
        role = 'athlete';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------
    // Checking authentication
    // --------------------------------------------------------

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // --------------------------------------------------------
    // Not authenticated
    // --------------------------------------------------------

    if (!isLoggedIn) {
      return const AuthScreen();
    }

    // --------------------------------------------------------
    // Coach
    // --------------------------------------------------------

    if (role == 'coach') {
      return const CoachRouteGuard();
    }

    // --------------------------------------------------------
    // Athlete
    // --------------------------------------------------------

    return const AppBottomNavigation();
  }
}

// ============================================================
// COACH ROUTE GUARD
// ============================================================

class CoachRouteGuard extends StatefulWidget {
  const CoachRouteGuard({super.key});

  @override
  State<CoachRouteGuard> createState() =>
      _CoachRouteGuardState();
}

class _CoachRouteGuardState
    extends State<CoachRouteGuard> {
  final AuthService _authService =
      AuthService();

  bool loading = true;
  bool allowed = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final role =
          await _authService.getRole();

      if (!mounted) return;

      setState(() {
        loading = false;
        allowed = role == 'coach';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        allowed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------
    // Loading
    // --------------------------------------------------------

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // --------------------------------------------------------
    // User is NOT a coach
    // --------------------------------------------------------

    if (!allowed) {
      return const AppBottomNavigation();
    }

    // --------------------------------------------------------
    // User is a coach
    // --------------------------------------------------------

    return const CoachDashboard();
  }
}