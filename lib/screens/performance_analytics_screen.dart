import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import '../services/performance_ai.dart';

class PerformanceAnalyticsScreen extends StatefulWidget {
  const PerformanceAnalyticsScreen({super.key});

  @override
  State<PerformanceAnalyticsScreen> createState() =>
      _PerformanceAnalyticsScreenState();
}

class _PerformanceAnalyticsScreenState
    extends State<PerformanceAnalyticsScreen> {
  final SessionRepository _repository = SessionRepository();

  List<SessionModel> sessions = [];

  double averageScore = 0;
  double bestScore = 0;
  DateTime? bestSessionDate;

  String bestAthlete = '';
  double averageKneeAngle = 0;

  int totalSessions = 0;
  int beginnerCount = 0;
  int intermediateCount = 0;
  int advancedCount = 0;

  bool _isLoading = true;

  static const Color _beginnerColor = Color(0xFFEF4444);
  static const Color _intermediateColor = Color(0xFFF59E0B);
  static const Color _advancedColor = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final loaded = await _repository.getSessions();

      if (loaded.isEmpty) {
        if (!mounted) return;

        setState(() {
          sessions = [];
          totalSessions = 0;
          averageScore = 0;
          bestScore = 0;
          bestSessionDate = null;
          bestAthlete = '';
          averageKneeAngle = 0;
          beginnerCount = 0;
          intermediateCount = 0;
          advancedCount = 0;
          _isLoading = false;
        });

        return;
      }

      double totalScore = 0;
      double totalKnee = 0;
      double best = 0;

      String currentBestAthlete = '';
      DateTime? currentBestSessionDate;

      int beginner = 0;
      int intermediate = 0;
      int advanced = 0;

      for (final session in loaded) {
        final data = session.metrics;

        final score =
            double.tryParse(data['overall_score'].toString()) ?? 0;

        final knee =
            double.tryParse(data['average_knee_angle'].toString()) ?? 0;

        totalScore += score;
        totalKnee += knee;

        if (score > best) {
          best = score;
          currentBestSessionDate = session.date;
          currentBestAthlete = session.athlete;
        }

        final level =
            data['performance_level']?.toString().toLowerCase() ?? '';

        switch (level) {
          case 'beginner':
            beginner++;
            break;

          case 'intermediate':
            intermediate++;
            break;

          case 'advanced':
            advanced++;
            break;
        }
      }

      if (!mounted) return;

      setState(() {
        sessions = loaded;
        totalSessions = loaded.length;
        averageScore = totalScore / loaded.length;
        averageKneeAngle = totalKnee / loaded.length;
        bestScore = best;
        bestSessionDate = currentBestSessionDate;
        bestAthlete = currentBestAthlete;
        beginnerCount = beginner;
        intermediateCount = intermediate;
        advancedCount = advanced;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        sessions = [];
        totalSessions = 0;
        averageScore = 0;
        bestScore = 0;
        bestSessionDate = null;
        bestAthlete = '';
        averageKneeAngle = 0;
        beginnerCount = 0;
        intermediateCount = 0;
        advancedCount = 0;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load performance analytics.'),
        ),
      );
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) {
      return const Color(0xFF16A34A);
    }

    if (score >= 60) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFFEF4444);
  }

  String _scoreLabel(double score) {
    if (score >= 80) {
      return 'Excellent';
    }

    if (score >= 60) {
      return 'Good';
    }

    if (score >= 40) {
      return 'Developing';
    }

    return 'Needs Focus';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '—';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _sectionTitle({
    required String title,
    String? subtitle,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 21,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withAlpha(22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(averageScore);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: CircularProgressIndicator(
                      value: averageScore.clamp(0, 100) / 100,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        averageScore.toStringAsFixed(1),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Performance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _scoreLabel(averageScore),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    totalSessions == 1
                        ? 'Based on your only recorded session.'
                        : 'Based on $totalSessions recorded sessions.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
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

  Widget _buildTrendChart() {
    if (sessions.length < 2) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'More sessions needed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Run at least 2 sessions to view your performance trend.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

    final chronologicalSessions = [...sessions];

    chronologicalSessions.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    final spots = <FlSpot>[];

    for (int i = 0; i < chronologicalSessions.length; i++) {
      final score = double.tryParse(
            chronologicalSessions[i].metrics['overall_score'].toString(),
          ) ??
          0;

      spots.add(
        FlSpot(
          i.toDouble(),
          score.clamp(0, 100),
        ),
      );
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 18, 16),
        child: SizedBox(
          height: 275,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (chronologicalSessions.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withAlpha(90),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: false,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 ||
                          index >= chronologicalSessions.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'S${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        'Session ${spot.x.toInt() + 1}\n'
                        '${spot.y.toStringAsFixed(1)} score',
                        TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.18,
                  barWidth: 3.5,
                  color: primary,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4.5,
                        color: primary,
                        strokeWidth: 2,
                        strokeColor:
                            theme.colorScheme.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primary.withAlpha(25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalBestCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFF59E0B),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Best',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Highest recorded performance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withAlpha(35),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    bestScore.toStringAsFixed(1),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '/ 100',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(
              icon: Icons.person_outline_rounded,
              label: 'Athlete',
              value: bestAthlete.isEmpty ? '—' : bestAthlete,
            ),
            const SizedBox(height: 11),
            _infoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(bestSessionDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceDistribution() {
    final theme = Theme.of(context);

    final total =
        beginnerCount + intermediateCount + advancedCount;

    if (total == 0) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No performance-level data available yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[
      if (beginnerCount > 0)
        PieChartSectionData(
          value: beginnerCount.toDouble(),
          title: '$beginnerCount',
          color: _beginnerColor,
          radius: 58,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      if (intermediateCount > 0)
        PieChartSectionData(
          value: intermediateCount.toDouble(),
          title: '$intermediateCount',
          color: _intermediateColor,
          radius: 58,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      if (advancedCount > 0)
        PieChartSectionData(
          value: advancedCount.toDouble(),
          title: '$advancedCount',
          color: _advancedColor,
          radius: 58,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Sessions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendRow(
              color: _beginnerColor,
              label: 'Beginner',
              count: beginnerCount,
            ),
            const SizedBox(height: 9),
            _buildLegendRow(
              color: _intermediateColor,
              label: 'Intermediate',
              count: intermediateCount,
            ),
            const SizedBox(height: 9),
            _buildLegendRow(
              color: _advancedColor,
              label: 'Advanced',
              count: advancedCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required int count,
  }) {
    final theme = Theme.of(context);

    final total =
        beginnerCount + intermediateCount + advancedCount;

    final percentage = total == 0 ? 0 : (count / total) * 100;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsights() {
    final theme = Theme.of(context);

    final insights = PerformanceAI.generateInsights(
      averageScore: averageScore,
      bestScore: bestScore,
      averageKneeAngle: averageKneeAngle,
      totalSessions: totalSessions,
    );

    if (insights.isEmpty) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'AI insights will appear after performance data is available.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF7C3AED).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFF7C3AED),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insights',
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Performance observations from your data',
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(
              insights.length,
              (index) {
                final insight = insights[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == insights.length - 1 ? 0 : 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.dividerColor.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED)
                                .withAlpha(18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Color(0xFF7C3AED),
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            insight,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 55),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Analytics Yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a running analysis session to populate performance analytics.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Analytics'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAnalytics,
            tooltip: 'Refresh analytics',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : totalSessions == 0
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      28,
                    ),
                    children: [
                      _buildOverviewHeader(),
                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.18,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            icon: Icons.emoji_events_rounded,
                            title: 'Best Score',
                            value: bestScore.toStringAsFixed(1),
                            color: const Color(0xFFF59E0B),
                            subtitle:
                                'Highest performance recorded',
                          ),
                          _buildStatCard(
                            icon: Icons.trending_up_rounded,
                            title: 'Average Score',
                            value: averageScore.toStringAsFixed(1),
                            color: const Color(0xFF16A34A),
                            subtitle:
                                'Across all sessions',
                          ),
                          _buildStatCard(
                            icon: Icons.accessibility_new_rounded,
                            title: 'Knee Angle',
                            value:
                                '${averageKneeAngle.toStringAsFixed(1)}°',
                            color: theme.colorScheme.primary,
                            subtitle:
                                'Average knee angle',
                          ),
                          _buildStatCard(
                            icon: Icons.history_rounded,
                            title: 'Sessions',
                            value: '$totalSessions',
                            color: const Color(0xFF7C3AED),
                            subtitle:
                                'Total analyzed sessions',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _sectionTitle(
                        title: 'Performance Trend',
                        subtitle:
                            'Track how scores change across sessions',
                        icon: Icons.show_chart_rounded,
                      ),
                      _buildTrendChart(),

                      const SizedBox(height: 24),

                      _sectionTitle(
                        title: 'Personal Best',
                        subtitle:
                            'Your highest individual performance',
                        icon: Icons.workspace_premium_rounded,
                      ),
                      _buildPersonalBestCard(),

                      const SizedBox(height: 24),

                      _sectionTitle(
                        title: 'Performance Distribution',
                        subtitle:
                            'Breakdown of analyzed performance levels',
                        icon: Icons.donut_large_rounded,
                      ),
                      _buildPerformanceDistribution(),

                      const SizedBox(height: 24),

                      _sectionTitle(
                        title: 'AI Insights',
                        subtitle:
                            'Data-driven observations from your sessions',
                        icon: Icons.psychology_rounded,
                      ),
                      _buildAIInsights(),
                    ],
                  ),
                ),
    );
  }
}