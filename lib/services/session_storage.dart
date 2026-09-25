import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const String _storageKey = "runner_analysis_sessions";

  /// Save one analysis session
  static Future<void> saveSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> sessions =
        prefs.getStringList(_storageKey) ?? [];

    // Add timestamp if not present
    

    sessions.insert(0, jsonEncode(session));

    await prefs.setStringList(_storageKey, sessions);
  }

  /// Load all saved sessions
  static Future<List<Map<String, dynamic>>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> sessions =
        prefs.getStringList(_storageKey) ?? [];

    return sessions
        .map(
          (e) => Map<String, dynamic>.from(jsonDecode(e)),
        )
        .toList();
  }

  /// Latest session
  static Future<Map<String, dynamic>?> latestSession() async {
    final sessions = await loadSessions();

    if (sessions.isEmpty) return null;

    return sessions.first;
  }

  /// Delete one session
  static Future<void> deleteSession(int index) async {
    final prefs = await SharedPreferences.getInstance();

    final sessions =
        prefs.getStringList(_storageKey) ?? [];

    if (index >= 0 && index < sessions.length) {
      sessions.removeAt(index);
      await prefs.setStringList(_storageKey, sessions);
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Total sessions
  static Future<int> totalSessions() async {
    final sessions = await loadSessions();
    return sessions.length;
  }

  /// Best score
  static Future<double> bestScore() async {
    final sessions = await loadSessions();

    if (sessions.isEmpty) return 0;

    double best = 0;

    for (final s in sessions) {
      final score =
          double.tryParse(s["overall_score"].toString()) ?? 0;

      if (score > best) best = score;
    }

    return best;
  }

  /// Average score
  static Future<double> averageScore() async {
    final sessions = await loadSessions();

    if (sessions.isEmpty) return 0;

    double sum = 0;

    for (final s in sessions) {
      sum +=
          double.tryParse(s["overall_score"].toString()) ??
              0;
    }

    return sum / sessions.length;
  }
}