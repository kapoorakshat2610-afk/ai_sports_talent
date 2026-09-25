class PerformanceAI {
  static List<String> generateInsights({
    required double averageScore,
    required double bestScore,
    required double averageKneeAngle,
    required int totalSessions,
  }) {
    List<String> insights = [];

    if (totalSessions < 3) {
      insights.add(
          "Complete a few more sessions for more accurate AI analysis.");
      return insights;
    }

    if (averageScore >= 90) {
      insights.add(
          "Excellent performance consistency. Keep maintaining your current training routine.");
    } else if (averageScore >= 75) {
      insights.add(
          "Good overall performance. Small improvements in running form could further increase your score.");
    } else {
      insights.add(
          "Your performance still has room for improvement. Focus on posture and knee mechanics.");
    }

    if ((averageKneeAngle - 165).abs() <= 5) {
      insights.add(
          "Your average knee angle is very close to the ideal running posture.");
    } else if (averageKneeAngle < 160) {
      insights.add(
          "Try increasing knee drive slightly to achieve a more efficient stride.");
    } else {
      insights.add(
          "Your knee lift is higher than ideal. Focus on smoother running mechanics.");
    }

    insights.add(
        "Current personal best is ${bestScore.toStringAsFixed(1)}. Aim to exceed it in your next training session.");

    return insights;
  }
}