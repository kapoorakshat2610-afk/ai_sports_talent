class SessionComparison {
  static double calculateKneeMechanicScore(double kneeAngle) {
    if (kneeAngle >= 160 && kneeAngle <= 180) {
      return 100;
    } else if (kneeAngle >= 140) {
      return 80;
    } else if (kneeAngle >= 120) {
      return 60;
    }
    return 40;
  }

  static double calculateEfficiency(
      double overallScore,
      double confidence,
      ) {
    return (overallScore * 0.7) + (confidence * 0.3);
  }

  static double calculateConsistency(
      double frames,
      double confidence,
      ) {
    if (frames == 0) return 0;
    return confidence;
  }

  static double calculateTechnique(
      double overallScore,
      double kneeAngle,
      ) {
    return (overallScore + calculateKneeMechanicScore(kneeAngle)) / 2;
  }

  static double weightedScore({
    required double overallScore,
    required double kneeMechanics,
    required double technique,
    required double efficiency,
    required double consistency,
    required double confidence,
  }) {
    return overallScore * 0.40 +
        kneeMechanics * 0.20 +
        technique * 0.15 +
        efficiency * 0.10 +
        consistency * 0.10 +
        confidence * 0.05;
  }

  static bool isSessionABetter(
      double scoreA,
      double scoreB,
      ) {
    return scoreA > scoreB;
  }

  static String generateSummary({
    required double scoreA,
    required double scoreB,
    required double kneeA,
    required double kneeB,
    required double confidenceA,
    required double confidenceB,
  }) {
    String summary = "";

    if (scoreA > scoreB) {
      summary +=
      "Session A achieved a higher overall performance score.\n\n";
    } else if (scoreB > scoreA) {
      summary +=
      "Session B achieved a higher overall performance score.\n\n";
    } else {
      summary += "Both sessions have similar overall scores.\n\n";
    }

    if (kneeA > kneeB) {
      summary +=
      "Session A demonstrated stronger knee mechanics.\n";
    } else if (kneeB > kneeA) {
      summary +=
      "Session B demonstrated stronger knee mechanics.\n";
    }

    if (confidenceA > confidenceB) {
      summary +=
      "Pose estimation confidence was higher in Session A.\n";
    } else if (confidenceB > confidenceA) {
      summary +=
      "Pose estimation confidence was higher in Session B.\n";
    }

    return summary;
  }
}