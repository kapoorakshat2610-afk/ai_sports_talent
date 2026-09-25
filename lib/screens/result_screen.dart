import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/ai_coach.dart';
import '../services/session_storage.dart';

class ResultScreen extends StatelessWidget  {
  final Map<String, dynamic> resultData;

  const ResultScreen({
    super.key,
    required this.resultData,
  });

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  String _toStringValue(dynamic value,
      {String fallback = "Unknown"}) {
    if (value == null) return fallback;
    return value.toString();
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  Color _performanceColor(String level) {
    switch (level.toLowerCase()) {
      case "advanced":
        return Colors.green;

      case "intermediate":
        return Colors.orange;

      case "beginner":
        return Colors.red;

      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _exportPdf({
    required BuildContext context,
    required double score,
    required String level,
    required double kneeAngle,
    required double idealAngle,
    required double difference,
    required List<String> mistakes,
    required List<String> suggestions,
    required List<String> strengths,
    required List<String> improvements,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [

            pw.Header(
              level: 0,
              child: pw.Text(
                "Runner Analyzer Report",
                style: const pw.TextStyle(
                  fontSize: 24,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text("Overall Score : ${score.toStringAsFixed(1)}"),
            pw.Text("Performance Level : ${level.toUpperCase()}"),

            pw.SizedBox(height: 15),

            pw.Text(
              "Knee Mechanics",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.Text(
              "Average Knee Angle : ${kneeAngle.toStringAsFixed(1)}°",
            ),

            pw.Text(
              "Ideal Knee Angle : ${idealAngle.toStringAsFixed(1)}°",
            ),

            pw.Text(
              "Difference : ${difference.toStringAsFixed(1)}°",
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              "Strengths",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            ...strengths.map(
              (e) => pw.Bullet(text: e),
            ),

            pw.SizedBox(height: 15),

            pw.Text(
              "Areas to Improve",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            ...improvements.map(
              (e) => pw.Bullet(text: e),
            ),

            pw.SizedBox(height: 15),

            pw.Text(
              "Detected Mistakes",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            ...mistakes.map(
              (e) => pw.Bullet(text: e),
            ),

            pw.SizedBox(height: 15),

            pw.Text(
              "Suggestions",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            ...suggestions.map(
              (e) => pw.Bullet(text: e),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ==========================
    // DATA FROM BACKEND
    // ==========================

    final double kneeAngle =
        _toDouble(resultData["average_knee_angle"]);

    final double idealAngle =
        _toDouble(
          resultData["ideal_knee_angle"],
          fallback: 165,
        );

    final double difference =
        _toDouble(
          resultData["difference_from_ideal"],
          fallback: (idealAngle - kneeAngle).abs(),
        );

    final String performance =
        _toStringValue(
          resultData["performance_level"],
          fallback: "Unknown",
        );

    final double score =
        _toDouble(
          resultData["overall_score"],
          fallback: 0,
        );

    final bool mlUsed =
        resultData["ml_used"] == true;

    final String source =
        _toStringValue(
          resultData["source"],
          fallback: "Unknown",
        );

    final int framesAnalyzed =
        _toInt(
          resultData["frames_analyzed"],
          fallback: 0,
        );

    final double confidence =
        _toDouble(
          resultData["keypoints_confidence"],
          fallback: 0,
        );

    final List<String> mistakes =
        _toStringList(resultData["mistakes"]);

    final List<String> suggestions =
        _toStringList(resultData["suggestions"]);

    final coachAdvice =
        AICoach.generateAdvice(resultData);

    final strengths =
        AICoach.strengths(resultData);

    final improvements =
        AICoach.improvements(resultData);

    final Color badgeColor =
        _performanceColor(performance);

    final bool lowConfidence =
        confidence < 0.35;

    final bool lowFrames =
        framesAnalyzed < 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analysis Report"),

        actions: [

          IconButton(
            icon: const Icon(Icons.share),

            onPressed: () {

              Share.share(
                """
Runner Analyzer Report

Overall Score : ${score.toStringAsFixed(1)}

Performance : ${performance.toUpperCase()}

Average Knee Angle : ${kneeAngle.toStringAsFixed(1)}°

Ideal Knee Angle : ${idealAngle.toStringAsFixed(1)}°

Difference : ${difference.toStringAsFixed(1)}°

Frames : $framesAnalyzed

Confidence : ${confidence.toStringAsFixed(2)}

ML Used : $mlUsed

Source : $source
""",
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.picture_as_pdf),

            onPressed: () {

              _exportPdf(

                context: context,

                score: score,

                level: performance,

                kneeAngle: kneeAngle,

                idealAngle: idealAngle,

                difference: difference,

                mistakes: mistakes,

                suggestions: suggestions,

                strengths: strengths,

                improvements: improvements,
              );
            },
          ),

        ],
      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [
                    // ==========================
          // SCORE CARD
          // ==========================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 10,
                        ),
                        Text(
                          score.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Overall Score",
                          style: TextStyle(fontSize: 18),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: badgeColor),
                          ),
                          child: Text(
                            performance.toUpperCase(),
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text("ML Used: ${mlUsed ? "YES" : "NO"}"),
                        Text("Source: $source"),

                        if (framesAnalyzed != null)
                          Text("Frames: $framesAnalyzed"),

                        if (confidence != null)
                          Text(
                            "Confidence: ${confidence.toStringAsFixed(2)}",
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          // ==========================
// KNEE MECHANICS
// ==========================

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Knee Mechanics",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Average Knee Angle: ${kneeAngle.toStringAsFixed(1)}°",
        ),
        Text(
  "Ideal Knee Angle: ${idealAngle.toStringAsFixed(1)}°",
),
Text(
  "Difference from Ideal: ${difference.toStringAsFixed(1)}°",
),
      ],
    ),
  ),
),

const SizedBox(height: 20),
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Knee Mechanics",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text("Average Knee Angle: ${kneeAngle.toStringAsFixed(1)}°"),
        Text("Ideal Knee Angle: ${idealAngle.toStringAsFixed(1)}°"),
        Text("Difference from Ideal: ${difference.toStringAsFixed(1)}°"),
      ],
    ),
  ),
),

const SizedBox(height: 20),
// ==========================
// STRENGTHS
// ==========================

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Strengths",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...AICoach.strengths(resultData).map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 20),
// ==========================
// IMPROVEMENTS
// ==========================

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Areas to Improve",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...AICoach.improvements(resultData).map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.arrow_circle_up,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 20),
// ==========================
// AI COACH
// ==========================

Card(
  elevation: 4,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Row(
          children: [
            Icon(
              Icons.psychology,
              color: Colors.deepPurple,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              "AI Coach",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          coachAdvice["title"],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          coachAdvice["message"],
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 20),

        const Text(
          "Today's Workout",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...(coachAdvice["workout"] as List<String>).map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "Recovery",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          coachAdvice["recovery"],
          style: const TextStyle(fontSize: 16),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 20),
// ==========================
// SUGGESTIONS
// ==========================

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suggestions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...AICoach.generateRecommendations(resultData).map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 20),
// ==========================
// END BUTTONS
// ==========================

const SizedBox(height: 30),

Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.refresh),
        label: const Text("Analyze Again"),
      ),
    ),
  ],
),

const SizedBox(height: 20),

        ],
      ),
    );
  }
}