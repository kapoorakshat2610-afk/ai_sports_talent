class PerformanceMetrics {
  static double kneeMechanics(
    double knee,
    double ideal,
  ) {
    final diff = (ideal - knee).abs();

    return (100 - diff).clamp(0, 100);
  }

  static double stability(
    double confidence,
  ) {
    return confidence.clamp(0, 100);
  }

  static double efficiency(
    double score,
    double confidence,
  ) {
    return ((score * 0.7) +
            (confidence * 0.3))
        .clamp(0, 100);
  }

  static double consistency(
    double confidence,
    double frames,
  ) {
    final frameScore =
        (frames / 500 * 100)
            .clamp(0, 100);

    return ((confidence + frameScore) / 2)
        .clamp(0, 100);
  }

  static double technique(
    double score,
    double kneeMechanics,
  ) {
    return ((score + kneeMechanics) / 2)
        .clamp(0, 100);
  }
}