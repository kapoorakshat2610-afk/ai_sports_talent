
class AICoach {
  static Map<String, dynamic> generateAdvice(Map<String, dynamic> result) {
    final score = (double.tryParse(result["overall_score"].toString()) ?? 0);
    final level = (result["performance_level"] ?? "unknown").toString().toLowerCase();

    String title;
    String message;
    List<String> workout;

    if (score >= 85) {
      title = "Excellent Performance";
      message = "Your running form is strong. Focus on consistency and race-specific training.";
      workout = [
        "5×200m fast strides",
        "Core training (15 min)",
        "Single-leg balance drills",
        "Mobility routine"
      ];
    } else if (score >= 60) {
      title = "Good Progress";
      message = "You have a solid base. Improve cadence and knee drive.";
      workout = [
        "High-knee drills",
        "Cadence runs",
        "Lunges",
        "Hip mobility"
      ];
    } else {
      title = "Needs Improvement";
      message = "Work on basic mechanics before increasing speed.";
      workout = [
        "Walking lunges",
        "High knees",
        "Skipping drills",
        "Easy recovery run"
      ];
    }

    return {
      "title": title,
      "message": message,
      "workout": workout,
      "recovery": "Hydrate well, sleep 8 hours, and stretch after training."
    };
  }

  static List<String> strengths(Map<String,dynamic> result){
    return ["Running analysis completed","Performance data recorded"];
  }

  static List<String> improvements(Map<String,dynamic> result){
    return ["Improve knee drive","Maintain consistent cadence"];
  }

  static List<String> generateRecommendations(Map<String,dynamic> result){
    return [
      "Practice dynamic warm-up before runs.",
      "Review your running form weekly.",
      "Increase training load gradually."
    ];
  }
}
