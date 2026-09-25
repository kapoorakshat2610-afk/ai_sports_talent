
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import '../utils/session_comparison.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SessionRepository _repository = SessionRepository();

  List<SessionModel> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    try {
      final data = await _repository.getSessions();

      if (!mounted) return;

      setState(() {
        sessions = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sessions = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to load dashboard: $e"),
        ),
      );
    }
  }

  double getDouble(
    Map<String, dynamic> map,
    String key,
  ) {
    return double.tryParse(
          map[key]?.toString() ?? "",
        ) ??
        0;
  }

  double get bestScore {
    if (sessions.isEmpty) return 0;

    double best = 0;

    for (final session in sessions) {
      final score = getDouble(
        session.metrics,
        "overall_score",
      );

      if (score > best) {
        best = score;
      }
    }

    return best;
  }

  double get averageScore {
    if (sessions.isEmpty) return 0;

    double total = 0;

    for (final session in sessions) {
      total += getDouble(
        session.metrics,
        "overall_score",
      );
    }

    return total / sessions.length;
  }

  double get latestScore {
    if (sessions.isEmpty) return 0;

    return getDouble(
      sessions.first.metrics,
      "overall_score",
    );
  }

  double get latestKneeAngle {
    if (sessions.isEmpty) return 0;

    return getDouble(
      sessions.first.metrics,
      "average_knee_angle",
    );
  }

  double get latestConfidence {
    if (sessions.isEmpty) return 0;

    return getDouble(
      sessions.first.metrics,
      "confidence",
    );
  }

  String get athleteName {
    if (sessions.isEmpty) return "Athlete";

    return sessions.first.athlete;
  }

  double get improvementPercent {
    if (sessions.length < 2) return 0;

    final latest = getDouble(
      sessions[0].metrics,
      "overall_score",
    );

    final previous = getDouble(
      sessions[1].metrics,
      "overall_score",
    );

    if (previous == 0) return 0;

    return ((latest - previous) / previous) * 100;
  }

  double get latestKneeMechanics {
    if (sessions.isEmpty) return 0;

    return SessionComparison.calculateKneeMechanicScore(
      latestKneeAngle,
    );
  }

  double get latestEfficiency {
    if (sessions.isEmpty) return 0;

    return SessionComparison.calculateEfficiency(
      latestScore,
      latestConfidence,
    );
  }

  double get latestConsistency {
    if (sessions.isEmpty) return 0;

    final frames = getDouble(
      sessions.first.metrics,
      "frames",
    );

    return SessionComparison.calculateConsistency(
      frames,
      latestConfidence,
    );
  }

  double get latestTechnique {
    if (sessions.isEmpty) return 0;

    return SessionComparison.calculateTechnique(
      latestScore,
      latestKneeAngle,
    );
  }

  double get latestWeightedScore {
    if (sessions.isEmpty) return 0;

    return SessionComparison.weightedScore(
      overallScore: latestScore,
      kneeMechanics: latestKneeMechanics,
      technique: latestTechnique,
      efficiency: latestEfficiency,
      consistency: latestConsistency,
      confidence: latestConfidence,
    );
  }

  Color scoreColor(double score) {
    if (score >= 90) {
      return Colors.green;
    }

    if (score >= 75) {
      return Colors.orange;
    }

    return Colors.red;
  }
  String _scoreLabel(double score) {
  if (score >= 90) {
    return 'Excellent';
  }

  if (score >= 75) {
    return 'Good';
  }

  if (score >= 60) {
    return 'Needs Work';
  }

  return 'Needs Attention';
}

  String performanceMessage() {
    if (sessions.isEmpty) {
      return "Complete your first analysis to unlock athlete insights.";
    }

    if (latestScore >= 90) {
      return "Excellent performance. Your running mechanics are looking strong.";
    }

    if (latestScore >= 75) {
      return "Good performance. Continue working on consistency and technique.";
    }

    return "There is room for improvement. Focus on form and controlled movement.";
  }

  Widget statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget metricTile({
    required String title,
    required double value,
    required String suffix,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                "${value.toStringAsFixed(1)}$suffix",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPerformanceChart() {
    if (sessions.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No performance data available.",
          ),
        ),
      );
    }

    final points = List.generate(
      sessions.length,
      (index) {
        final score = getDouble(
          sessions[index].metrics,
          "overall_score",
        );

        return FlSpot(
          index.toDouble(),
          score,
        );
      },
    );

    double maxY = 100;

    for (final point in points) {
      if (point.y > maxY) {
        maxY = point.y + 10;
      }
    }

    return SizedBox(
      height: 230,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "${value.toInt() + 1}",
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              barWidth: 4,
              color: Colors.blue,
              dotData: const FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildKneeChart() {
    if (sessions.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No knee-angle data available.",
          ),
        ),
      );
    }

    final points = List.generate(
      sessions.length,
      (index) {
        final angle = getDouble(
          sessions[index].metrics,
          "average_knee_angle",
        );

        return FlSpot(
          index.toDouble(),
          angle,
        );
      },
    );

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 120,
          maxY: 190,
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "${value.toInt() + 1}",
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              barWidth: 4,
              color: Colors.deepPurple,
              dotData: const FlDotData(
                show: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _exportAthleteReport() async {
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No session data available for the report.'),
        ),
      );
      return;
    }

    try {
      final latest = sessions.first;
      final currentScore = latestScore;
      final kneeAngle = latestKneeAngle;
      final confidence = latestConfidence;
      final kneeMechanics = latestKneeMechanics;
      final efficiency = latestEfficiency;
      final consistency = latestConsistency;
      final technique = latestTechnique;
      final weightedScore = latestWeightedScore;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pdf_lib.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => [
            pw.Text(
              'Athlete Performance Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'AI Sports Talent',
              style: const pw.TextStyle(
                fontSize: 11,
                color: pdf_lib.PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 22),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: pdf_lib.PdfColors.grey300,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Athlete',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(athleteName),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Session Date: ${latest.date.day.toString().padLeft(2, '0')}/'
                    '${latest.date.month.toString().padLeft(2, '0')}/'
                    '${latest.date.year}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Performance Summary',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(
                color: pdf_lib.PdfColors.grey300,
              ),
              children: [
                _pdfRow('Overall Score', currentScore.toStringAsFixed(1)),
                _pdfRow('Performance Level', _scoreLabel(currentScore)),
                _pdfRow('Knee Angle', '${kneeAngle.toStringAsFixed(1)}°'),
                _pdfRow('Confidence', confidence.toStringAsFixed(2)),
                _pdfRow('Knee Mechanics', kneeMechanics.toStringAsFixed(1)),
                _pdfRow('Technique', technique.toStringAsFixed(1)),
                _pdfRow('Efficiency', efficiency.toStringAsFixed(1)),
                _pdfRow('Consistency', consistency.toStringAsFixed(1)),
                _pdfRow('Weighted Score', weightedScore.toStringAsFixed(1)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Performance Insight',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(performanceMessage()),
            if (sessions.length >= 2) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Change from previous session: ${improvementPercent.toStringAsFixed(1)}%',
              ),
            ],
            pw.SizedBox(height: 28),
            pw.Divider(
              color: pdf_lib.PdfColors.grey300,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated by AI Sports Talent',
              style: const pw.TextStyle(
                fontSize: 9,
                color: pdf_lib.PdfColors.grey600,
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Athlete PDF report generated.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to generate athlete report: $e'),
        ),
      );
    }
  }

  pw.TableRow _pdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  String _athleteReportText() {
    final currentScore = latestScore;

    return '''Athlete Performance Report

Athlete: $athleteName
Latest Session: ${sessions.first.date.day.toString().padLeft(2, '0')}/${sessions.first.date.month.toString().padLeft(2, '0')}/${sessions.first.date.year}

Overall Score: ${currentScore.toStringAsFixed(1)}
Performance Level: ${_scoreLabel(currentScore)}
Knee Angle: ${latestKneeAngle.toStringAsFixed(1)}°
Confidence: ${latestConfidence.toStringAsFixed(2)}
Knee Mechanics: ${latestKneeMechanics.toStringAsFixed(1)}
Technique: ${latestTechnique.toStringAsFixed(1)}
Efficiency: ${latestEfficiency.toStringAsFixed(1)}
Consistency: ${latestConsistency.toStringAsFixed(1)}
Weighted Score: ${latestWeightedScore.toStringAsFixed(1)}

Performance Insight:
${performanceMessage()}
''';
  }

  Future<void> _shareAthleteReport() async {
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No session data available to share.'),
        ),
      );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _athleteReportText(),
          title: 'Athlete Performance Report',
          subject: 'AI Sports Talent Athlete Report',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share athlete report: $e'),
        ),
      );
    }
  }

  Widget _buildAthleteReportActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Save or share your latest performance report.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportAthleteReport,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Export PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareAthleteReport,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecentSessions() {
    if (sessions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "No sessions available yet.",
          ),
        ),
      );
    }

    final count = sessions.length > 5
        ? 5
        : sessions.length;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        final session = sessions[index];

        final score = getDouble(
          session.metrics,
          "overall_score",
        );

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(
            bottom: 8,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  scoreColor(score).withOpacity(0.12),
              child: Icon(
                Icons.directions_run,
                color: scoreColor(score),
              ),
            ),
            title: Text(
              session.athlete,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${session.date.day.toString().padLeft(2, '0')}/"
              "${session.date.month.toString().padLeft(2, '0')}/"
              "${session.date.year}",
            ),
            trailing: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: scoreColor(score),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Athlete Dashboard",
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadSessions,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSessions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // ATHLETE HEADER
              // --------------------------------------------------

              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor:
                            Colors.blue.shade100,
                        child: const Icon(
                          Icons.person,
                          size: 42,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              athleteName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              "Latest Rating "
                              "${latestScore.toStringAsFixed(1)}",
                              style: TextStyle(
                                fontSize: 17,
                                color:
                                    scoreColor(
                                      latestScore,
                                    ),
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${sessions.length} saved sessions",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // QUICK STATISTICS
              // --------------------------------------------------

              GridView.count(
                physics:
                    const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  statCard(
                    icon: Icons.emoji_events,
                    title: "Best Score",
                    value:
                        bestScore.toStringAsFixed(1),
                    color: Colors.orange,
                  ),
                  statCard(
                    icon: Icons.analytics,
                    title: "Average Score",
                    value:
                        averageScore.toStringAsFixed(1),
                    color: Colors.green,
                  ),
                  statCard(
                    icon: Icons.history,
                    title: "Sessions",
                    value:
                        sessions.length.toString(),
                    color: Colors.blue,
                  ),
                  statCard(
                    icon: Icons.trending_up,
                    title: "Improvement",
                    value:
                        "${improvementPercent.toStringAsFixed(1)}%",
                    color:
                        improvementPercent >= 0
                            ? Colors.green
                            : Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // CURRENT PERFORMANCE
              // --------------------------------------------------

              sectionTitle(
                "Current Performance",
                "Key metrics from your latest analysis",
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  metricTile(
                    title: "Knee Mechanics",
                    value: latestKneeMechanics,
                    suffix: "%",
                    icon: Icons.accessibility_new,
                    color: Colors.deepPurple,
                  ),
                  metricTile(
                    title: "Efficiency",
                    value: latestEfficiency,
                    suffix: "%",
                    icon: Icons.speed,
                    color: Colors.blue,
                  ),
                ],
              ),

              Row(
                children: [
                  metricTile(
                    title: "Consistency",
                    value: latestConsistency,
                    suffix: "%",
                    icon: Icons.repeat,
                    color: Colors.teal,
                  ),
                  metricTile(
                    title: "Technique",
                    value: latestTechnique,
                    suffix: "%",
                    icon: Icons.directions_run,
                    color: Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.amber,
                        size: 35,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Weighted Performance Score",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              latestWeightedScore
                                  .toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    scoreColor(
                                      latestWeightedScore,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // PERSONAL BEST
              // --------------------------------------------------

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.orange,
                        size: 40,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Personal Best",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Best Score: "
                              "${bestScore.toStringAsFixed(1)}",
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // AI COACH SUMMARY
              // --------------------------------------------------

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Colors.deepPurple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "AI Coach Summary",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        performanceMessage(),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      if (sessions.length >= 2) ...[
                        const SizedBox(height: 10),
                        Text(
                          improvementPercent >= 0
                              ? "Latest score improved by "
                                "${improvementPercent.toStringAsFixed(1)}% "
                                "compared with the previous session."
                              : "Latest score changed by "
                                "${improvementPercent.toStringAsFixed(1)}% "
                                "compared with the previous session.",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // PERFORMANCE TREND
              // --------------------------------------------------

              sectionTitle(
                "Performance Trend",
                "Overall score across saved sessions",
              ),

              const SizedBox(height: 12),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    10,
                    20,
                    20,
                    10,
                  ),
                  child: buildPerformanceChart(),
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // KNEE ANGLE ANALYTICS
              // --------------------------------------------------

              sectionTitle(
                "Knee Angle Trend",
                "Average knee angle across sessions",
              ),

              const SizedBox(height: 12),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    10,
                    20,
                    20,
                    10,
                  ),
                  child: buildKneeChart(),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: 3,
                child: ListTile(
                  leading: const Icon(
                    Icons.accessibility_new,
                    color: Colors.deepPurple,
                  ),
                  title: const Text(
                    "Latest Knee Angle",
                  ),
                  subtitle: const Text(
                    "Target reference: approximately 165°",
                  ),
                  trailing: Text(
                    "${latestKneeAngle.toStringAsFixed(1)}°",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // RECENT SESSIONS
              // --------------------------------------------------

              sectionTitle(
                "Recent Sessions",
                "Your latest recorded analyses",
              ),

              const SizedBox(height: 10),

              buildRecentSessions(),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // REPORT ACTIONS
              // --------------------------------------------------

              sectionTitle(
                "Performance Reports",
                "Export or share your latest athlete report",
              ),

              const SizedBox(height: 10),

              _buildAthleteReportActions(),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // REFRESH BUTTON
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loadSessions,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    "Refresh Dashboard",
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

