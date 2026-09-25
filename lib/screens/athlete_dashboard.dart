import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';

class AthleteDashboard extends StatefulWidget {
  final String athlete;

  const AthleteDashboard({
    super.key,
    required this.athlete,
  });

  @override
  State<AthleteDashboard> createState() => _AthleteDashboardState();
}

class _AthleteDashboardState extends State<AthleteDashboard> {
  final SessionRepository _repository = SessionRepository();

  List<SessionModel> sessions = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final loaded = await _repository.getSessions();

      if (!mounted) return;

      final athleteSessions = loaded
          .where(
            (session) =>
                session.athlete.trim().toLowerCase() ==
                widget.athlete.trim().toLowerCase(),
          )
          .toList();

      athleteSessions.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      setState(() {
        sessions = athleteSessions;
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
          content: Text(
            'Unable to load ${widget.athlete} sessions.',
          ),
        ),
      );
    }
  }

  double _scoreOf(SessionModel session) {
    return double.tryParse(
          session.metrics['overall_score']?.toString() ?? '',
        ) ??
        0;
  }

  Color _scoreColor(double score) {
    if (score >= 85) {
      return const Color(0xFF16A34A);
    }

    if (score >= 70) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFFEF4444);
  }

  String _performanceLevel(double score) {
    if (score >= 85) {
      return 'Advanced';
    }

    if (score >= 70) {
      return 'Intermediate';
    }

    return 'Beginner';
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'LOW':
        return const Color(0xFF16A34A);

      case 'MEDIUM':
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFFEF4444);
    }
  }

  Widget _buildScoreRing({
    required double score,
    required double size,
  }) {
    final scoreColor = _scoreColor(score);
    final progress = (score / 100).clamp(0, 1).toDouble();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 9,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                scoreColor,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size > 100 ? 30 : 24,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
              Text(
                'Score',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendGraph(
    BuildContext context,
    List<double> scores,
  ) {
    if (scores.length < 2) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 38,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(height: 10),
              const Text(
                'Not enough data yet',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete at least two sessions to see your performance trend.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sessions are newest first.
    // Reverse them so the chart is chronological.
    final chronologicalScores =
        scores.reversed.toList();

    final spots = chronologicalScores
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            entry.value,
          ),
        )
        .toList();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          18,
          18,
          14,
        ),
        child: SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme
                        .colorScheme
                        .outlineVariant
                        .withAlpha(90),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: false,
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
                    reservedSize: 34,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:
                        chronologicalScores.length <= 8,
                    interval: 1,
                    getTitlesWidget:
                        (value, meta) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 8,
                        ),
                        child: Text(
                          'S${value.toInt() + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData:
                    LineTouchTooltipData(
                  getTooltipItems:
                      (touchedSpots) {
                    return touchedSpots.map(
                      (spot) {
                        return LineTooltipItem(
                          'Session ${spot.x.toInt() + 1}\n'
                          'Score: ${spot.y.toStringAsFixed(1)}',
                          TextStyle(
                            color: theme
                                .colorScheme
                                .onPrimary,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        );
                      },
                    ).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  barWidth: 3.5,
                  color: primary,
                  belowBarData: BarAreaData(
                    show: true,
                    color: primary.withAlpha(28),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter:
                        (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: primary,
                        strokeWidth: 2,
                        strokeColor:
                            theme.colorScheme.surface,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadSessions,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSessions,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.analytics_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 22),
            const Text(
              'No sessions yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No saved sessions were found for ${widget.athlete}. '
              'Complete a running analysis to start building the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: loadSessions,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Refresh Sessions',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Athlete Dashboard',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    final scores =
        sessions.map(_scoreOf).toList();

    final totalSessions = scores.length;

    final averageScore =
        scores.reduce((a, b) => a + b) /
            scores.length;

    final bestScore =
        scores.reduce(
      (a, b) => a > b ? a : b,
    );

    final latestScore = scores.first;

    double improvement = 0;

    if (scores.length >= 2) {
      improvement =
          scores.first - scores.last;
    }

    double talentPotential =
        averageScore + (improvement * 0.5);

    talentPotential =
        talentPotential.clamp(0, 100).toDouble();

    String category;

    if (talentPotential >= 85) {
      category = 'State Level Potential';
    } else if (talentPotential >= 70) {
      category = 'District Level Potential';
    } else if (talentPotential >= 50) {
      category = 'School Level Potential';
    } else {
      category = 'Beginner Athlete';
    }

    final strengths = <String>[];
    final improvements = <String>[];
    final recommendations = <String>[];

    if (averageScore >= 70) {
      strengths.add(
        'Good overall running performance',
      );
    } else {
      improvements.add(
        'Improve overall running mechanics',
      );
    }

    if (bestScore >= 80) {
      strengths.add(
        'Strong peak performance',
      );
    } else {
      improvements.add(
        'Work on reaching a higher peak score',
      );
    }

    if (improvement > 0) {
      strengths.add(
        'Positive performance trend',
      );
    } else {
      improvements.add(
        'Maintain a consistent improvement trend',
      );
    }

    if (totalSessions >= 5) {
      strengths.add(
        'Consistent training activity',
      );
    } else {
      improvements.add(
        'Complete more recorded training sessions',
      );
    }

    if (averageScore < 50) {
      recommendations.add(
        'Focus on basic running mechanics and controlled movement.',
      );
    }

    if (bestScore < 70) {
      recommendations.add(
        'Gradually increase sprint and acceleration training intensity.',
      );
    }

    if (improvement <= 0) {
      recommendations.add(
        'Follow a structured weekly training plan and track progress.',
      );
    }

    if (totalSessions < 5) {
      recommendations.add(
        'Record more running sessions to build a reliable performance history.',
      );
    }

    if (talentPotential >= 70) {
      recommendations.add(
        'Begin advanced agility, acceleration and technique drills.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Maintain your current training routine and continue monitoring consistency.',
      );
    }

    String priority;

    if (talentPotential < 50) {
      priority = 'HIGH';
    } else if (talentPotential < 75) {
      priority = 'MEDIUM';
    } else {
      priority = 'LOW';
    }

    final primaryScoreColor =
        _scoreColor(latestScore);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Athlete Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.athlete,
              style: TextStyle(
                fontSize: 12,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadSessions,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSessions,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          children: [
            // --------------------------------------------------
            // HERO / LATEST PERFORMANCE
            // --------------------------------------------------

            Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme
                          .surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    _buildScoreRing(
                      score: latestScore,
                      size: 120,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latest Performance',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _performanceLevel(
                              latestScore,
                            ),
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight:
                                  FontWeight.w800,
                              color:
                                  primaryScoreColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your most recent recorded running performance.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  primaryScoreColor
                                      .withAlpha(24),
                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),
                              border: Border.all(
                                color:
                                    primaryScoreColor
                                        .withAlpha(70),
                              ),
                            ),
                            child: Text(
                              'Current Score • ${latestScore.toStringAsFixed(1)}',
                              style: TextStyle(
                                color:
                                    primaryScoreColor,
                                fontWeight:
                                    FontWeight.w700,
                                fontSize: 12,
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

            const SizedBox(height: 22),

            // --------------------------------------------------
            // OVERVIEW
            // --------------------------------------------------

            _buildSectionHeader(
              context,
              'Performance Overview',
              'Your key performance indicators',
            ),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.22,
              children: [
                _buildMetricCard(
                  context: context,
                  title: 'Sessions',
                  value:
                      totalSessions.toString(),
                  icon: Icons.fitness_center_rounded,
                  color: theme
                      .colorScheme
                      .primary,
                  subtitle:
                      'Recorded analyses',
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Average Score',
                  value:
                      averageScore
                          .toStringAsFixed(1),
                  icon: Icons.analytics_rounded,
                  color:
                      const Color(0xFF4F46E5),
                  subtitle:
                      'Across all sessions',
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Best Score',
                  value:
                      bestScore
                          .toStringAsFixed(1),
                  icon:
                      Icons.emoji_events_rounded,
                  color:
                      const Color(0xFFD97706),
                  subtitle:
                      'Highest recorded',
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Latest Score',
                  value:
                      latestScore
                          .toStringAsFixed(1),
                  icon: Icons.speed_rounded,
                  color:
                      primaryScoreColor,
                  subtitle:
                      'Most recent session',
                ),
              ],
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // IMPROVEMENT
            // --------------------------------------------------

            _buildSectionHeader(
              context,
              'Performance Change',
              'Difference between your latest and earliest recorded score',
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            (improvement >= 0
                                    ? const Color(
                                        0xFF16A34A,
                                      )
                                    : const Color(
                                        0xFFEF4444,
                                      ))
                                .withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        improvement >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: improvement >= 0
                            ? const Color(
                                0xFF16A34A,
                              )
                            : const Color(
                                0xFFEF4444,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            improvement >= 0
                                ? 'Performance Improved'
                                : 'Performance Declined',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            improvement >= 0
                                ? 'Your latest score is higher than your earliest recorded score.'
                                : 'Your latest score is lower than your earliest recorded score.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w800,
                        color: improvement >= 0
                            ? const Color(
                                0xFF16A34A,
                              )
                            : const Color(
                                0xFFEF4444,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // TALENT POTENTIAL
            // --------------------------------------------------

            _buildSectionHeader(
              context,
              'Talent Potential',
              'A combined indicator based on performance history and trend',
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildScoreRing(
                      score: talentPotential,
                      size: 145,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      category,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${talentPotential.toStringAsFixed(0)} / 100 potential score',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // STRENGTHS
            // --------------------------------------------------

            _buildSectionHeader(
              context,
              'Strengths',
              'Areas where your current performance is trending positively',
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: strengths.isEmpty
                    ? const Padding(
                        padding:
                            EdgeInsets.all(10),
                        child: Text(
                          'No major strengths identified yet.',
                        ),
                      )
                    : Column(
                        children: strengths
                            .map(
                              (item) =>
                                  _buildBulletItem(
                                context: context,
                                text: item,
                                icon:
                                    Icons.check_rounded,
                                color:
                                    const Color(
                                  0xFF16A34A,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // IMPROVEMENT AREAS
            // --------------------------------------------------

            _buildSectionHeader(
              context,
              'Needs Improvement',
              'Areas to focus on in upcoming training sessions',
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: improvements.isEmpty
                    ? const Padding(
                        padding:
                            EdgeInsets.all(10),
                        child: Text(
                          'No immediate improvement areas identified.',
                        ),
                      )
                    : Column(
                        children: improvements
                            .map(
                              (item) =>
                                  _buildBulletItem(
                                context: context,
                                text: item,
                                icon: Icons
                                    .warning_amber_rounded,
                                color:
                                    const Color(
                                  0xFFF59E0B,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // AI COACH
            // --------------------------------------------------

            _buildSectionHeader(
              context,
              'AI Coach Recommendations',
              'Personalized suggestions based on your recorded performance',
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme
                                .colorScheme
                                .primary
                                .withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Training Focus',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _priorityColor(
                              priority,
                            ).withAlpha(24),
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                            border: Border.all(
                              color:
                                  _priorityColor(
                                priority,
                              ).withAlpha(65),
                            ),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color:
                                  _priorityColor(
                                priority,
                              ),
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color:
                          theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 4),
                    ...recommendations.map(
                      (item) => _buildBulletItem(
                        context: context,
                        text: item,
                        icon:
                            Icons.auto_awesome_rounded,
                        color:
                            theme
                                .colorScheme
                                .primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // PERFORMANCE TREND
            // --------------------------------------------------

            _buildSectionHeader(
              context,
              'Performance Trend',
              'Session-by-session movement in your overall score',
            ),

            const SizedBox(height: 12),

            _buildTrendGraph(
              context,
              scores,
            ),

            const SizedBox(height: 10),

            Text(
              'Tip: Keep recording sessions consistently to build a more reliable performance history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}