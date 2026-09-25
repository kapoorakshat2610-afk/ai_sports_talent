import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/session_model.dart';

class ApiService {
  static const String baseUrl = "http://172.16.15.56:8000";

  Future<List<SessionModel>> getSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load sessions: ${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map(
          (json) => SessionModel.fromBackendJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }
}