import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';

class SessionRepository {
  static const String storageKey = "runner_analysis_sessions";

  Future<List<SessionModel>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();

    final raw =
        prefs.getStringList(storageKey) ?? [];

    return raw
        .map((e) => SessionModel.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> saveSession(SessionModel session) async {
    final prefs = await SharedPreferences.getInstance();

    final list =
        prefs.getStringList(storageKey) ?? [];

    list.insert(
      0,
      jsonEncode(session.toJson()),
    );

    await prefs.setStringList(storageKey, list);
  }

  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(storageKey);
  }

  Future<int> totalSessions() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs
            .getStringList(storageKey)
            ?.length ??
        0;
  }
}