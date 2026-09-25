import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // IMPORTANT:
  // Replace this with the SAME IP that currently opens
  // http://YOUR_IP:8000/docs
  static const String baseUrl =
      'https://runner-analyzer-api-1.onrender.com';

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'auth_user_id';
  static const String usernameKey = 'auth_username';
  static const String roleKey = 'auth_role';

  // ============================================================
  // REGISTER
  // ============================================================

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse(
      '$baseUrl/auth/register',
    );

    debugPrint('REGISTER URL: $url');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'REGISTER STATUS: ${response.statusCode}',
      );
      debugPrint(
        'REGISTER BODY: ${response.body}',
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'Registration failed '
          '(${response.statusCode}): '
          '${_extractError(response.body)}',
        );
      }

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      throw Exception(
        'Registration request failed: $e',
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse(
      '$baseUrl/auth/login',
    );

    debugPrint('LOGIN URL: $url');
    debugPrint(
      'LOGIN USERNAME: $username',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'LOGIN STATUS: ${response.statusCode}',
      );
      debugPrint(
        'LOGIN BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Login failed '
          '(${response.statusCode}): '
          '${_extractError(response.body)}',
        );
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map) {
        throw Exception(
          'Invalid login response.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        decoded,
      );

      final token =
          data['access_token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Login succeeded but no access token was returned.',
        );
      }

      await _saveToken(token);

      // This is a separate request.
      await loadCurrentUser();

      return data;
    } catch (e) {
      throw Exception(
        'Login request failed: $e',
      );
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  Future<Map<String, dynamic>>
      loadCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'No authentication token found.',
      );
    }

    final url = Uri.parse(
      '$baseUrl/auth/me',
    );

    debugPrint(
      'ME URL: $url',
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'ME STATUS: ${response.statusCode}',
      );
      debugPrint(
        'ME BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'User request failed '
          '(${response.statusCode}): '
          '${_extractError(response.body)}',
        );
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map) {
        throw Exception(
          'Invalid user response.',
        );
      }

      final user =
          Map<String, dynamic>.from(
        decoded,
      );

      final prefs =
          await SharedPreferences
              .getInstance();

      await prefs.setString(
        userIdKey,
        user['id'].toString(),
      );

      await prefs.setString(
        usernameKey,
        user['username']
                ?.toString() ??
            '',
      );

      await prefs.setString(
        roleKey,
        user['role']
                ?.toString() ??
            'athlete',
      );

      return user;
    } catch (e) {
      throw Exception(
        'User profile request failed: $e',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(usernameKey);
    await prefs.remove(roleKey);
  }
  Future<Map<String, String>> authHeaders() async {
  final token = await getToken();

  if (token == null || token.isEmpty) {
    throw Exception('User is not authenticated.');
  }

  return {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> getToken() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      tokenKey,
    );
  }

  // ============================================================
  // ROLE
  // ============================================================

  Future<String?> getRole() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      roleKey,
    );
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<String?> getUsername() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      usernameKey,
    );
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null &&
        token.isNotEmpty;
  }

  // ============================================================
  // ERROR PARSER
  // ============================================================

  String _extractError(
    String body,
  ) {
    try {
      final decoded =
          jsonDecode(body);

      if (decoded is Map &&
          decoded['detail'] != null) {
        return decoded['detail']
            .toString();
      }
    } catch (_) {}

    return body.isEmpty
        ? 'Unknown server error'
        : body;
  }

  // ============================================================
  // SAVE TOKEN
  // ============================================================

  Future<void> _saveToken(
    String token,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      tokenKey,
      token,
    );
  }
}