class SessionModel {
  final String sessionId;
  final String athlete;
  final DateTime date;
  final Map<String, dynamic> metrics;

  SessionModel({
    required this.sessionId,
    required this.athlete,
    required this.date,
    required this.metrics,
  });

  // ============================================================
  // Flutter / Local Storage JSON
  // ============================================================

  factory SessionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    // Backend format
    if (json.containsKey("overall_score") ||
        json.containsKey("average_knee_angle") ||
        json.containsKey("created_at")) {
      return SessionModel.fromBackendJson(json);
    }

    // Old local-storage format
    return SessionModel(
      sessionId: json["session_id"]?.toString() ?? "",
      athlete: json["athlete"]?.toString() ?? "Unknown",
      date: DateTime.tryParse(
            json["time"]?.toString() ?? "",
          ) ??
          DateTime.now(),
      metrics: Map<String, dynamic>.from(
        json["data"] ?? {},
      ),
    );
  }

  // ============================================================
  // Backend JSON → Flutter Model
  // ============================================================

  factory SessionModel.fromBackendJson(
    Map<String, dynamic> json,
  ) {
    return SessionModel(
      sessionId: json["id"]?.toString() ?? "",
      athlete: json["athlete"]?.toString() ?? "Unknown",
      date: DateTime.tryParse(
            json["created_at"]?.toString() ?? "",
          ) ??
          DateTime.now(),
      metrics: {
        "overall_score":
            json["overall_score"] ?? 0.0,
        "average_knee_angle":
            json["average_knee_angle"] ?? 0.0,
        "confidence":
            json["confidence"] ?? 0.0,
        "frames":
            json["frames"] ?? 0,
        "performance_level":
            json["performance_level"] ?? "unknown",
      },
    );
  }

  // ============================================================
  // Flutter Model → Local Storage JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      "session_id": sessionId,
      "athlete": athlete,
      "time": date.toIso8601String(),
      "data": metrics,
    };
  }

  // ============================================================
  // Flutter Model → Backend JSON
  // ============================================================

  Map<String, dynamic> toBackendJson() {
    return {
      "athlete": athlete,
      "overall_score":
          _toDouble(metrics["overall_score"]),
      "average_knee_angle":
          _toDouble(metrics["average_knee_angle"]),
      "confidence":
          _toDouble(metrics["confidence"]),
      "frames":
          _toInt(metrics["frames"]),
      "performance_level":
          metrics["performance_level"]?.toString() ??
              "unknown",
    };
  }

  // ============================================================
  // Helpers
  // ============================================================

  static double _toDouble(dynamic value) {
    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0.0;
  }

  static int _toInt(dynamic value) {
    return int.tryParse(
          value?.toString() ?? "",
        ) ??
        0;
  }
}