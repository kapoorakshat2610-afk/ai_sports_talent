import 'api_service.dart';

Future<void> testApi() async {
  final api = ApiService();

  try {
    final sessions = await api.getSessions();

    print("API SUCCESS");
    print("Sessions received: ${sessions.length}");

    for (final session in sessions) {
      print(
        "${session.athlete} | "
        "${session.metrics["overall_score"]}",
      );
    }
  } catch (e) {
    print("API ERROR: $e");
  }
}