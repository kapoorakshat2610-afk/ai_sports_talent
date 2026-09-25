import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import '../utils/session_comparison.dart';
import 'compare_sessions_screen.dart';

class CoachDashboard extends StatefulWidget {
const CoachDashboard({super.key});

@override
State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
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
    isLoading = false;
    sessions = [];
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Unable to load coach dashboard: $e'),
    ),
  );
}


}

double getDouble(Map<String, dynamic> map, String key) {
return double.tryParse(
map[key]?.toString() ?? '',
) ??
0;
}

double scoreOf(SessionModel session) {
return getDouble(
session.metrics,
'overall_score',
);
}

double get averageScore {
if (sessions.isEmpty) return 0;


double total = 0;

for (final session in sessions) {
  total += scoreOf(session);
}

return total / sessions.length;


}

double get bestScore {
if (sessions.isEmpty) return 0;


double best = 0;

for (final session in sessions) {
  final score = scoreOf(session);

  if (score > best) {
    best = score;
  }
}

return best;


}

Set<String> get athletes {
return sessions
.map((session) => session.athlete)
.where((name) => name.trim().isNotEmpty)
.toSet();
}

SessionModel? get bestSession {
if (sessions.isEmpty) return null;


SessionModel best = sessions.first;

for (final session in sessions) {
  if (scoreOf(session) > scoreOf(best)) {
    best = session;
  }
}

return best;


}

Color scoreColor(double score) {
if (score >= 90) return Colors.green;
if (score >= 75) return Colors.orange;
return Colors.red;
}

String performanceLevel(double score) {
if (score >= 90) return 'Excellent';
if (score >= 75) return 'Good';
if (score >= 60) return 'Needs Work';
return 'Needs Attention';
}

double sessionKneeMechanics(SessionModel session) {
final knee = getDouble(
session.metrics,
'average_knee_angle',
);


return SessionComparison.calculateKneeMechanicScore(
  knee,
);


}

double sessionEfficiency(SessionModel session) {
final score = scoreOf(session);


final confidence = getDouble(
  session.metrics,
  'confidence',
);

return SessionComparison.calculateEfficiency(
  score,
  confidence,
);


}

double sessionTechnique(SessionModel session) {
final score = scoreOf(session);


final knee = getDouble(
  session.metrics,
  'average_knee_angle',
);

return SessionComparison.calculateTechnique(
  score,
  knee,
);


}

double sessionWeightedScore(SessionModel session) {
final score = scoreOf(session);


final knee = getDouble(
  session.metrics,
  'average_knee_angle',
);

final confidence = getDouble(
  session.metrics,
  'confidence',
);

final frames = getDouble(
  session.metrics,
  'frames',
);

final kneeMechanics =
    SessionComparison.calculateKneeMechanicScore(knee);

final efficiency =
    SessionComparison.calculateEfficiency(
  score,
  confidence,
);

final consistency =
    SessionComparison.calculateConsistency(
  frames,
  confidence,
);

final technique =
    SessionComparison.calculateTechnique(
  score,
  knee,
);

return SessionComparison.weightedScore(
  overallScore: score,
  kneeMechanics: kneeMechanics,
  technique: technique,
  efficiency: efficiency,
  consistency: consistency,
  confidence: confidence,
);


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
size: 27,
),
),
const SizedBox(height: 10),
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
fontWeight: FontWeight.w600,
fontSize: 13,
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
fontSize: 21,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
subtitle,
style: const TextStyle(
color: Colors.grey,
fontSize: 13,
),
),
],
);
}

Widget buildTopPerformer() {
final session = bestSession;


if (session == null) {
  return const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'No athlete sessions available yet.',
      ),
    ),
  );
}

final score = scoreOf(session);

return Card(
  elevation: 5,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.amber.shade100,
          child: const Icon(
            Icons.emoji_events,
            color: Colors.orange,
            size: 38,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Performer',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.athlete,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Score ${score.toStringAsFixed(1)} • '
                '${performanceLevel(score)}',
                style: TextStyle(
                  color: scoreColor(score),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);


}

Widget buildAthleteCard(String athlete) {
final athleteSessions = sessions
.where(
(session) => session.athlete == athlete,
)
.toList();


if (athleteSessions.isEmpty) {
  return const SizedBox();
}

final latest = athleteSessions.first;
final latestScore = scoreOf(latest);

double best = 0;

for (final session in athleteSessions) {
  final score = scoreOf(session);

  if (score > best) {
    best = score;
  }
}

double improvement = 0;

if (athleteSessions.length >= 2) {
  final previous = scoreOf(
    athleteSessions[1],
  );

  if (previous != 0) {
    improvement =
        ((latestScore - previous) / previous) * 100;
  }
}

final weighted = sessionWeightedScore(latest);
final kneeMechanics = sessionKneeMechanics(latest);
final technique = sessionTechnique(latest);
final efficiency = sessionEfficiency(latest);

return Card(
  elevation: 3,
  margin: const EdgeInsets.only(bottom: 10),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: ExpansionTile(
    leading: CircleAvatar(
      backgroundColor:
          scoreColor(latestScore).withOpacity(0.12),
      child: Icon(
        Icons.person,
        color: scoreColor(latestScore),
      ),
    ),
    title: Text(
      athlete,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(
      '${athleteSessions.length} sessions • '
      '${performanceLevel(latestScore)}',
    ),
    trailing: Text(
      latestScore.toStringAsFixed(1),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: scoreColor(latestScore),
      ),
    ),
    childrenPadding: const EdgeInsets.fromLTRB(
      16,
      0,
      16,
      16,
    ),
    children: [
      const Divider(),
      const SizedBox(height: 8),

      Row(
        children: [
          Expanded(
            child: _smallMetric(
              'Best',
              best.toStringAsFixed(1),
              Icons.emoji_events,
            ),
          ),
          Expanded(
            child: _smallMetric(
              'Latest',
              latestScore.toStringAsFixed(1),
              Icons.analytics,
            ),
          ),
          Expanded(
            child: _smallMetric(
              'Change',
              '${improvement.toStringAsFixed(1)}%',
              improvement >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
            ),
          ),
        ],
      ),

      const SizedBox(height: 18),

      _progressMetric(
        'Technique',
        technique,
        Icons.directions_run,
      ),

      _progressMetric(
        'Knee Mechanics',
        kneeMechanics,
        Icons.accessibility_new,
      ),

      _progressMetric(
        'Efficiency',
        efficiency,
        Icons.speed,
      ),

      _progressMetric(
        'Weighted Score',
        weighted,
        Icons.star,
      ),

      const SizedBox(height: 8),

      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          latestScore >= 90
              ? 'Coach recommendation: Maintain current form and focus on consistency.'
              : latestScore >= 75
                  ? 'Coach recommendation: Good performance. Focus on technique and consistency.'
                  : 'Coach recommendation: Prioritize technique, knee mechanics, and running consistency.',
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
      ),
    ],
  ),
);


}

Widget _smallMetric(
String title,
String value,
IconData icon,
) {
return Column(
children: [
Icon(
icon,
size: 19,
color: Colors.blueGrey,
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 2),
Text(
title,
style: const TextStyle(
fontSize: 11,
color: Colors.grey,
),
),
],
);
}

Widget _progressMetric(
String title,
double value,
IconData icon,
) {
final safeValue = value.clamp(0, 100).toDouble();


return Padding(
  padding: const EdgeInsets.only(top: 10),
  child: Column(
    children: [
      Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            safeValue.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      LinearProgressIndicator(
        value: safeValue / 100,
        minHeight: 7,
        borderRadius: BorderRadius.circular(10),
      ),
    ],
  ),
);


}

Widget buildRecentActivity() {
if (sessions.isEmpty) {
return const Card(
child: Padding(
padding: EdgeInsets.all(20),
child: Text(
'No recent activity.',
),
),
);
}


final count = sessions.length > 5
    ? 5
    : sessions.length;

return Column(
  children: List.generate(
    count,
    (index) {
      final session = sessions[index];
      final score = scoreOf(session);

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
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
            '${session.date.day}/'
            '${session.date.month}/'
            '${session.date.year}',
          ),
          trailing: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scoreColor(score),
                ),
              ),
              Text(
                performanceLevel(score),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
);


}

Widget buildCoachInsight() {
if (sessions.isEmpty) {
return const Card(
child: Padding(
padding: EdgeInsets.all(18),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.psychology,
color: Colors.deepPurple,
size: 32,
),
SizedBox(width: 12),
Expanded(
child: Text(
'Run an athlete analysis to generate coaching insights.',
style: TextStyle(
fontSize: 15,
height: 1.5,
),
),
),
],
),
),
);
}


String message;

if (bestScore >= 90 && averageScore >= 80) {
  message =
      'The team is performing at a strong level. '
      'Focus on maintaining consistency and identifying '
      'small technique improvements that can produce further gains.';
} else if (averageScore >= 75) {
  message =
      'Overall team performance is good. '
      'Give additional coaching attention to athletes '
      'performing below the team average.';
} else {
  message =
      'The team has significant room for improvement. '
      'Prioritize running mechanics, knee positioning, '
      'technique, and consistency in upcoming sessions.';
}

return Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  ),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.psychology,
          color: Colors.deepPurple,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  ),
);


}

Future<void> _exportCoachReport() async {
  if (sessions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No team data available for the report.'),
      ),
    );
    return;
  }

  try {
    final best = bestSession;
    final pdf = pw.Document();

    final athleteRows = athletes.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text(
            'Coach Team Performance Report',
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
          pw.Text(
            'Team Overview',
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
              _coachPdfRow('Athletes', athletes.length.toString()),
              _coachPdfRow('Sessions', sessions.length.toString()),
              _coachPdfRow('Average Score', averageScore.toStringAsFixed(1)),
              _coachPdfRow('Best Score', bestScore.toStringAsFixed(1)),
              if (best != null)
                _coachPdfRow('Top Performer', best.athlete),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Athlete Performance',
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
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1.1),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(1.1),
            },
            children: [
              _coachPerformanceRow(
                'Athlete',
                'Sessions',
                'Best',
                'Latest',
                header: true,
              ),
              ...athleteRows.map((athlete) {
                final athleteSessions = sessions
                    .where((session) => session.athlete == athlete)
                    .toList();

                double athleteBest = 0;
                for (final session in athleteSessions) {
                  final score = scoreOf(session);
                  if (score > athleteBest) {
                    athleteBest = score;
                  }
                }

                final latest = athleteSessions.isEmpty
                    ? 0
                    : scoreOf(athleteSessions.first);

                return _coachPerformanceRow(
                  athlete,
                  athleteSessions.length.toString(),
                  athleteBest.toStringAsFixed(1),
                  latest.toStringAsFixed(1),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Coach Insight',
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(_coachInsightText()),
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
        content: Text('Coach team PDF report generated.'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to generate coach report: $e'),
      ),
    );
  }
}

pw.TableRow _coachPdfRow(
  String label,
  String value,
) {
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

pw.TableRow _coachPerformanceRow(
  String athlete,
  String count,
  String best,
  String latest,
  {bool header = false,}
) {
  final style = pw.TextStyle(
    fontWeight:
        header ? pw.FontWeight.bold : pw.FontWeight.normal,
  );

  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(athlete, style: style),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          count,
          textAlign: pw.TextAlign.center,
          style: style,
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          best,
          textAlign: pw.TextAlign.center,
          style: style,
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          latest,
          textAlign: pw.TextAlign.center,
          style: style,
        ),
      ),
    ],
  );
}

String _coachInsightText() {
  if (sessions.isEmpty) {
    return 'Run athlete analyses to generate coaching insights.';
  }

  if (bestScore >= 90 && averageScore >= 80) {
    return 'The team is performing at a strong level. Focus on maintaining consistency and identifying small technique improvements that can produce further gains.';
  }

  if (averageScore >= 75) {
    return 'Overall team performance is good. Give additional coaching attention to athletes performing below the team average.';
  }

  return 'The team has room for improvement. Prioritize running mechanics, knee positioning, technique, and consistency in upcoming sessions.';
}

String _coachReportText() {
  final best = bestSession;

  final athleteRows = athletes.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  final buffer = StringBuffer()
    ..writeln('Coach Team Performance Report')
    ..writeln()
    ..writeln('Athletes: ${athletes.length}')
    ..writeln('Sessions: ${sessions.length}')
    ..writeln('Average Score: ${averageScore.toStringAsFixed(1)}')
    ..writeln('Best Score: ${bestScore.toStringAsFixed(1)}');

  if (best != null) {
    buffer.writeln('Top Performer: ${best.athlete}');
  }

  buffer.writeln();
  buffer.writeln('Athlete Performance:');

  for (final athlete in athleteRows) {
    final athleteSessions = sessions
        .where((session) => session.athlete == athlete)
        .toList();

    double athleteBest = 0;
    for (final session in athleteSessions) {
      final score = scoreOf(session);
      if (score > athleteBest) {
        athleteBest = score;
      }
    }

    final latest = athleteSessions.isEmpty
        ? 0
        : scoreOf(athleteSessions.first);

    buffer.writeln(
      '$athlete — ${athleteSessions.length} sessions, '
      'best ${athleteBest.toStringAsFixed(1)}, '
      'latest ${latest.toStringAsFixed(1)}',
    );
  }

  buffer
    ..writeln()
    ..writeln('Coach Insight:')
    ..writeln(_coachInsightText())
    ..writeln()
    ..writeln('Generated by AI Sports Talent');

  return buffer.toString();
}

Future<void> _shareCoachReport() async {
  if (sessions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No team data available to share.'),
      ),
    );
    return;
  }

  try {
    await SharePlus.instance.share(
      ShareParams(
        text: _coachReportText(),
        title: 'Coach Team Performance Report',
        subject: 'AI Sports Talent Coach Report',
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to share coach report: $e'),
      ),
    );
  }
}

Widget _buildCoachReportActions() {
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
            'Team Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Export or share the current team performance report.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportCoachReport,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Export PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _shareCoachReport,
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
      'Coach Dashboard',
    ),
    centerTitle: true,
    actions: [
      IconButton(
        onPressed: loadSessions,
        icon: const Icon(
          Icons.refresh,
        ),
        tooltip: 'Refresh',
      ),
    ],
  ),
  body: RefreshIndicator(
    onRefresh: loadSessions,
    child: SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
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
                    radius: 34,
                    backgroundColor:
                        Colors.blue.shade100,
                    child: const Icon(
                      Icons.sports,
                      size: 38,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Coach Performance Center',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${athletes.length} athletes • '
                          '${sessions.length} sessions',
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

          const SizedBox(height: 22),

          sectionTitle(
            'Team Overview',
            'High-level performance statistics',
          ),

          const SizedBox(height: 12),

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
                icon: Icons.groups,
                title: 'Athletes',
                value:
                    athletes.length.toString(),
                color: Colors.blue,
              ),
              statCard(
                icon: Icons.analytics,
                title: 'Sessions',
                value:
                    sessions.length.toString(),
                color: Colors.deepPurple,
              ),
              statCard(
                icon: Icons.bar_chart,
                title: 'Average Score',
                value:
                    averageScore.toStringAsFixed(1),
                color: Colors.green,
              ),
              statCard(
                icon: Icons.emoji_events,
                title: 'Best Score',
                value:
                    bestScore.toStringAsFixed(1),
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          sectionTitle(
            'Top Performer',
            'Highest recorded overall score',
          ),

          const SizedBox(height: 10),

          buildTopPerformer(),

          const SizedBox(height: 24),

          sectionTitle(
            'Athlete Performance',
            'Tap an athlete to view detailed metrics',
          ),

          const SizedBox(height: 10),

          if (athletes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No athletes found.',
                ),
              ),
            )
          else
            ...athletes.map(
              buildAthleteCard,
            ),

          const SizedBox(height: 24),

          sectionTitle(
            'Coach Insight',
            'Automated performance interpretation',
          ),

          const SizedBox(height: 10),

          buildCoachInsight(),

          const SizedBox(height: 24),

          sectionTitle(
            'Recent Activity',
            'Latest athlete analyses',
          ),

          const SizedBox(height: 10),

          buildRecentActivity(),

          const SizedBox(height: 24),

          sectionTitle(
            'Team Reports',
            'Export or share the current coach report',
          ),

          const SizedBox(height: 10),

          _buildCoachReportActions(),

          const SizedBox(height: 24),

          sectionTitle(
            'Coach Tools',
            'Use existing analysis tools',
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
             onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CompareSessionsScreen(),
        ),
      );
    },
              icon: const Icon(
                Icons.compare_arrows,
              ),
              label: const Text(
                'Compare Sessions',
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loadSessions,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Refresh Coach Data',
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
