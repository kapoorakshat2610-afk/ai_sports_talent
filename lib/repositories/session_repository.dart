import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';
import '../services/auth_service.dart';

class SessionRepository {
  static const String storageKey =
      'runner_analysis_sessions';

  static const String backendUrl =
      'https://runner-analyzer-api-1.onrender.com';

  final AuthService _authService =
      AuthService();

  Future<List<SessionModel>> getSessions() async {
    try {
      final role =
          await _authService.getRole();

      final username =
          await _authService.getUsername();

      final headers =
          await _authService.authHeaders();

      late final http.Response response;

      // --------------------------------------------------------
      // COACH
      // --------------------------------------------------------

      if (role == 'coach') {
        response = await http.get(
          Uri.parse(
            '$backendUrl/sessions/',
          ),
          headers: headers,
        );
      }

      // --------------------------------------------------------
      // ATHLETE
      // --------------------------------------------------------

      else {
        if (username == null ||
            username.isEmpty) {
          throw Exception(
            'Authenticated username not found.',
          );
        }

        response = await http.get(
          Uri.parse(
            '$backendUrl/sessions/athlete/'
            '${Uri.encodeComponent(username)}',
          ),
          headers: headers,
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Backend returned '
          '${response.statusCode}: '
          '${response.body}',
        );
      }

      final List<dynamic> data =
          jsonDecode(response.body);

      final sessions = data
          .map(
            (json) =>
                SessionModel.fromBackendJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();

      await _cacheSessions(sessions);

      return sessions;
    } catch (e) {
      debugPrint(
        'Backend getSessions failed: $e',
      );

      return _getLocalSessions();
    }
  }

  Future<void> saveSession(
    SessionModel session,
  ) async {
    try {
      final headers =
          await _authService.authHeaders();

      final response = await http.post(
        Uri.parse(
          '$backendUrl/sessions/',
        ),
        headers: headers,
        body: jsonEncode(
          session.toBackendJson(),
        ),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'Backend returned '
          '${response.statusCode}: '
          '${response.body}',
        );
      }

      await _saveLocalSession(session);
    } catch (e) {
      debugPrint(
        'Backend saveSession failed: $e',
      );

      await _saveLocalSession(session);
    }
  }

  Future<List<SessionModel>>
      getAthleteSessions(
    String athlete,
  ) async {
    try {
      final headers =
          await _authService.authHeaders();

      final response = await http.get(
        Uri.parse(
          '$backendUrl/sessions/athlete/'
          '${Uri.encodeComponent(athlete)}',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Backend returned '
          '${response.statusCode}',
        );
      }

      final List<dynamic> data =
          jsonDecode(response.body);

      return data
          .map(
            (json) =>
                SessionModel.fromBackendJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'Backend athlete sessions failed: $e',
      );

      return _getLocalSessions();
    }
  }

  Future<List<SessionModel>>
      fetchFromBackend() async {
    return getSessions();
  }

  Future<List<SessionModel>>
      syncFromBackend() async {
    final sessions =
        await getSessions();

    await _cacheSessions(sessions);

    return sessions;
  }

  Future<int>
      migrateLocalSessionsToBackend() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final localEntries = <String>[];

    localEntries.addAll(
      prefs.getStringList(
            storageKey,
          ) ??
          [],
    );

    localEntries.addAll(
      prefs.getStringList(
            'history',
          ) ??
          [],
    );

    if (localEntries.isEmpty) {
      return 0;
    }

    final uniqueEntries =
        localEntries.toSet();

    List<SessionModel>
        backendSessions = [];

    try {
      backendSessions =
          await getSessions();
    } catch (_) {}

    final existingKeys =
        backendSessions
            .map(_sessionKey)
            .toSet();

    int migrated = 0;

    for (final raw
        in uniqueEntries) {
      try {
        final decoded =
            jsonDecode(raw);

        if (decoded is! Map) {
          continue;
        }

        final session =
            SessionModel.fromJson(
          Map<String, dynamic>.from(
            decoded,
          ),
        );

        final key =
            _sessionKey(session);

        if (existingKeys
            .contains(key)) {
          continue;
        }

        await saveSession(session);

        existingKeys.add(key);
        migrated++;
      } catch (e) {
        debugPrint(
          'Migration skipped: $e',
        );
      }
    }

    return migrated;
  }

  Future<void> deleteAll() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(storageKey);
    await prefs.remove('history');
  }

  Future<int> totalSessions() async {
    final sessions =
        await getSessions();

    return sessions.length;
  }

  Future<void> _cacheSessions(
    List<SessionModel> sessions,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setStringList(
      storageKey,
      sessions
          .map(
            (session) =>
                jsonEncode(
              session.toJson(),
            ),
          )
          .toList(),
    );
  }

  Future<List<SessionModel>>
      _getLocalSessions() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final raw =
        prefs.getStringList(
              storageKey,
            ) ??
            [];

    return raw.map(
      (value) {
        return SessionModel.fromJson(
          jsonDecode(value),
        );
      },
    ).toList();
  }

  Future<void> _saveLocalSession(
    SessionModel session,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final list =
        prefs.getStringList(
              storageKey,
            ) ??
            [];

    list.insert(
      0,
      jsonEncode(
        session.toJson(),
      ),
    );

    await prefs.setStringList(
      storageKey,
      list,
    );
  }

  String _sessionKey(
    SessionModel session,
  ) {
    final score =
        session.metrics[
              'overall_score']
            ?.toString() ??
        '0';

    final knee =
        session.metrics[
              'average_knee_angle']
            ?.toString() ??
        '0';

    return '${session.athlete}|'
        '${session.date.toIso8601String()}|'
        '$score|'
        '$knee';
  }
}