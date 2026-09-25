import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import '../utils/session_comparison.dart';

class CompareSessionsScreen extends StatefulWidget {
  const CompareSessionsScreen({super.key});

  @override
  State<CompareSessionsScreen> createState() =>
      _CompareSessionsScreenState();
}

class _CompareSessionsScreenState
    extends State<CompareSessionsScreen> {
  final SessionRepository _repository = SessionRepository();

  List<SessionModel> sessions = [];

  SessionModel? sessionA;
  SessionModel? sessionB;

  bool _isLoading = true;
  bool _isExporting = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  // ============================================================
  // LOAD SESSIONS
  // ============================================================

  Future<void> _loadSessions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final loaded = await _repository.getSessions();

      if (!mounted) return;

      setState(() {
        sessions = loaded;

        if (loaded.length >= 2) {
          sessionA = loaded[0];
          sessionB = loaded[1];
        } else if (loaded.length == 1) {
          sessionA = loaded[0];
          sessionB = null;
        } else {
          sessionA = null;
          sessionB = null;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sessions = [];
        sessionA = null;
        sessionB = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load saved sessions.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double getDouble(
    Map<String, dynamic> map,
    String key,
  ) {
    return double.tryParse(
          map[key]?.toString() ?? '',
        ) ??
        0.0;
  }

  double _scoreColorValue(double score) {
    return score.clamp(0.0, 100.0).toDouble();
  }

  Color _scoreColor(
    BuildContext context,
    double score,
  ) {
    if (score >= 80.0) {
      return const Color(0xFF16A34A);
    }

    if (score >= 60.0) {
      return const Color(0xFFF59E0B);
    }

    return Theme.of(context).colorScheme.error;
  }

  String _scoreLabel(double score) {
    if (score >= 80.0) {
      return 'Excellent';
    }

    if (score >= 60.0) {
      return 'Good';
    }

    if (score >= 40.0) {
      return 'Developing';
    }

    return 'Needs Focus';
  }

  String _sessionTitle(
    SessionModel session,
  ) {
    final double score = getDouble(
      session.metrics,
      'overall_score',
    );

    final date = session.date;

    return '${session.athlete} • '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} • '
        'Score ${score.toStringAsFixed(1)}';
  }

  String _shortSessionLabel(
    SessionModel session,
  ) {
    final double score = getDouble(
      session.metrics,
      'overall_score',
    );

    final date = session.date;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} • '
        '${score.toStringAsFixed(1)}';
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required String title,
    String? subtitle,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withAlpha(20),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 21,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: theme
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

  // ============================================================
  // SESSION SELECTORS
  // ============================================================

  Widget _buildSessionSelectors() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme
                        .primary
                        .withAlpha(18),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    color: theme
                        .colorScheme
                        .primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Sessions',
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select two sessions to compare performance',
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // SESSION A
            DropdownButtonFormField<SessionModel>(
              initialValue: sessionA,
              decoration: const InputDecoration(
                labelText: 'Session A',
                prefixIcon:
                    Icon(Icons.looks_one_rounded),
              ),
              items: sessions
                  .map(
                    (session) =>
                        DropdownMenuItem<
                            SessionModel>(
                      value: session,
                      child: Text(
                        _sessionTitle(session),
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  sessionA = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // SESSION B
            DropdownButtonFormField<SessionModel>(
              initialValue: sessionB,
              decoration: const InputDecoration(
                labelText: 'Session B',
                prefixIcon:
                    Icon(Icons.looks_two_rounded),
              ),
              items: sessions
                  .map(
                    (session) =>
                        DropdownMenuItem<
                            SessionModel>(
                      value: session,
                      child: Text(
                        _sessionTitle(session),
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  sessionB = value;
                });
              },
            ),

            if (sessionA != null &&
                sessionB != null &&
                sessionA == sessionB)
              Padding(
                padding:
                    const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme
                        .error
                        .withAlpha(12),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: theme
                          .colorScheme
                          .error
                          .withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: theme
                            .colorScheme
                            .error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select two different sessions.',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .error,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WINNER CARD
  // ============================================================

  Widget _buildWinnerCard(
    String winnerName,
    double winnerScore,
    double differencePercent,
  ) {
    final theme = Theme.of(context);

    final double scoreA = sessionA == null
        ? 0.0
        : getDouble(
            sessionA!.metrics,
            'overall_score',
          );

    final double scoreB = sessionB == null
        ? 0.0
        : getDouble(
            sessionB!.metrics,
            'overall_score',
          );

    final bool isTie =
        (scoreA - scoreB).abs() < 0.01 &&
            sessionA != null &&
            sessionB != null;

    final scoreColor =
        _scoreColor(context, winnerScore);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B)
                    .withAlpha(22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTie
                    ? Icons.balance_rounded
                    : Icons.emoji_events_rounded,
                color: const Color(0xFFF59E0B),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isTie
                  ? 'Performance Match'
                  : 'Higher Weighted Score',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isTie ? 'Tie' : winnerName,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.headlineSmall?.copyWith(
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              winnerScore.toStringAsFixed(1),
              style:
                  theme.textTheme.displaySmall?.copyWith(
                fontWeight:
                    FontWeight.w900,
                color: scoreColor,
              ),
            ),
            Text(
              'Weighted score / 100',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: scoreColor.withAlpha(15),
                borderRadius:
                    BorderRadius.circular(30),
              ),
              child: Text(
                _scoreLabel(winnerScore),
                style: TextStyle(
                  color: scoreColor,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            if (!isTie &&
                differencePercent.abs() > 0.01) ...[
              const SizedBox(height: 12),
              Text(
                '${differencePercent.abs().toStringAsFixed(1)}% difference',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AI SUMMARY
  // ============================================================

  Widget _buildAISummary(
    String summary,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED)
                        .withAlpha(18),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFF7C3AED),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Comparison Summary',
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automated interpretation of both sessions',
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED)
                    .withAlpha(10),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF7C3AED)
                      .withAlpha(28),
                ),
              ),
              child: Text(
                summary,
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RADAR CHART
  // ============================================================

  Widget _buildRadarChart({
    required double scoreA,
    required double scoreB,
    required double kneeMechanicsA,
    required double kneeMechanicsB,
    required double techniqueA,
    required double techniqueB,
    required double efficiencyA,
    required double efficiencyB,
    required double consistencyA,
    required double consistencyB,
    required double confidenceA,
    required double confidenceB,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          18,
          10,
          18,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 330,
              child: RadarChart(
                RadarChartData(
                  radarShape:
                      RadarShape.circle,
                  tickCount: 5,
                  ticksTextStyle: theme
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                  gridBorderData:
                      BorderSide(
                    color: theme
                        .dividerColor
                        .withAlpha(110),
                    width: 1,
                  ),
                  radarBorderData:
                      BorderSide(
                    color: theme
                        .dividerColor
                        .withAlpha(120),
                    width: 1,
                  ),
                  dataSets: [
                    RadarDataSet(
                      borderColor:
                          theme.colorScheme.primary,
                      fillColor: theme
                          .colorScheme
                          .primary
                          .withAlpha(45),
                      entryRadius: 3,
                      borderWidth: 2.5,
                      dataEntries: [
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            scoreA,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            kneeMechanicsA,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            techniqueA,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            efficiencyA,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            consistencyA,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            confidenceA,
                          ).toDouble(),
                        ),
                      ],
                    ),
                    RadarDataSet(
                      borderColor:
                          const Color(0xFFF59E0B),
                      fillColor:
                          const Color(0xFFF59E0B)
                              .withAlpha(42),
                      entryRadius: 3,
                      borderWidth: 2.5,
                      dataEntries: [
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            scoreB,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            kneeMechanicsB,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            techniqueB,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            efficiencyB,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            consistencyB,
                          ).toDouble(),
                        ),
                        RadarEntry(
                          value:
                              _scoreColorValue(
                            confidenceB,
                          ).toDouble(),
                        ),
                      ],
                    ),
                  ],
                  titleTextStyle: theme
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                  getTitle: (
                    int index,
                    double angle,
                  ) {
                    switch (index) {
                      case 0:
                        return const RadarChartTitle(
                          text: 'Overall',
                        );
                      case 1:
                        return const RadarChartTitle(
                          text: 'Knee',
                        );
                      case 2:
                        return const RadarChartTitle(
                          text: 'Technique',
                        );
                      case 3:
                        return const RadarChartTitle(
                          text: 'Efficiency',
                        );
                      case 4:
                        return const RadarChartTitle(
                          text: 'Consistency',
                        );
                      default:
                        return const RadarChartTitle(
                          text: 'Confidence',
                        );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  color:
                      theme.colorScheme.primary,
                  label: sessionA == null
                      ? 'Session A'
                      : _shortSessionLabel(
                          sessionA!,
                        ),
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  color:
                      const Color(0xFFF59E0B),
                  label: sessionB == null
                      ? 'Session B'
                      : _shortSessionLabel(
                          sessionB!,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Flexible(
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow:
                  TextOverflow.ellipsis,
              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPARISON ROW
  // ============================================================

  Widget _buildComparisonRow(
    String title,
    String valueA,
    String valueB, {
    bool percentage = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color:
              theme.dividerColor.withAlpha(90),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),
              decoration:
                  BoxDecoration(
                color: theme
                    .colorScheme
                    .primary
                    .withAlpha(12),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                percentage
                    ? '$valueA%'
                    : valueA,
                textAlign:
                    TextAlign.center,
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                      color: theme
                          .colorScheme
                          .primary,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),
              decoration:
                  BoxDecoration(
                color: const Color(0xFFF59E0B)
                    .withAlpha(12),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                percentage
                    ? '$valueB%'
                    : valueB,
                textAlign:
                    TextAlign.center,
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                      color: const Color(
                        0xFFD97706,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPARISON TABLE
  // ============================================================

  Widget _buildComparisonTable({
    required double scoreA,
    required double scoreB,
    required double kneeA,
    required double kneeB,
    required double confidenceA,
    required double confidenceB,
    required double techniqueA,
    required double techniqueB,
    required double efficiencyA,
    required double efficiencyB,
    required double consistencyA,
    required double consistencyB,
    required double weightedA,
    required double weightedB,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Metric',
                    style: theme
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Session A',
                    textAlign:
                        TextAlign.center,
                    style: theme
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          color: theme
                              .colorScheme
                              .primary,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Session B',
                    textAlign:
                        TextAlign.center,
                    style: theme
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          color:
                              const Color(
                            0xFFD97706,
                          ),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: theme.dividerColor
                  .withAlpha(100),
              height: 1,
            ),
            const SizedBox(height: 12),
            _buildComparisonRow(
              'Overall Score',
              scoreA.toStringAsFixed(1),
              scoreB.toStringAsFixed(1),
            ),
            _buildComparisonRow(
              'Average Knee Angle',
              '${kneeA.toStringAsFixed(1)}°',
              '${kneeB.toStringAsFixed(1)}°',
            ),
            _buildComparisonRow(
              'Confidence',
              confidenceA.toStringAsFixed(1),
              confidenceB.toStringAsFixed(1),
            ),
            _buildComparisonRow(
              'Technique',
              techniqueA.toStringAsFixed(1),
              techniqueB.toStringAsFixed(1),
            ),
            _buildComparisonRow(
              'Efficiency',
              efficiencyA.toStringAsFixed(1),
              efficiencyB.toStringAsFixed(1),
            ),
            _buildComparisonRow(
              'Consistency',
              consistencyA.toStringAsFixed(1),
              consistencyB.toStringAsFixed(1),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration:
                  BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme
                        .colorScheme
                        .primary
                        .withAlpha(14),
                    const Color(0xFFF59E0B)
                        .withAlpha(12),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(13),
                border: Border.all(
                  color: theme
                      .colorScheme
                      .primary
                      .withAlpha(45),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Weighted Score',
                      style: theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w900,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      weightedA.toStringAsFixed(1),
                      textAlign:
                          TextAlign.center,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w900,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      weightedB.toStringAsFixed(1),
                      textAlign:
                          TextAlign.center,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w900,
                            color:
                                const Color(
                              0xFFD97706,
                            ),
                          ),
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

  // ============================================================
  // EXPORT PDF
  // ============================================================

  Future<void> _exportPdf(
    String winnerName,
    double winnerScore,
    String aiSummary,
  ) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = pw.Document();

      final String athleteA =
          sessionA?.athlete ?? 'Session A';

      final String athleteB =
          sessionB?.athlete ?? 'Session B';

      final double scoreA = sessionA == null
          ? 0.0
          : getDouble(
              sessionA!.metrics,
              'overall_score',
            );

      final double scoreB = sessionB == null
          ? 0.0
          : getDouble(
              sessionB!.metrics,
              'overall_score',
            );

      final double kneeA = sessionA == null
          ? 0.0
          : getDouble(
              sessionA!.metrics,
              'average_knee_angle',
            );

      final double kneeB = sessionB == null
          ? 0.0
          : getDouble(
              sessionB!.metrics,
              'average_knee_angle',
            );

      final double confidenceA =
          sessionA == null
              ? 0.0
              : getDouble(
                  sessionA!.metrics,
                  'confidence',
                );

      final double confidenceB =
          sessionB == null
              ? 0.0
              : getDouble(
                  sessionB!.metrics,
                  'confidence',
                );

      final double framesA =
          sessionA == null
              ? 0.0
              : getDouble(
                  sessionA!.metrics,
                  'frames',
                );

      final double framesB =
          sessionB == null
              ? 0.0
              : getDouble(
                  sessionB!.metrics,
                  'frames',
                );

      final double kneeMechanicsA =
          SessionComparison
              .calculateKneeMechanicScore(
        kneeA,
      ).toDouble();

      final double kneeMechanicsB =
          SessionComparison
              .calculateKneeMechanicScore(
        kneeB,
      ).toDouble();

      final double efficiencyA =
          SessionComparison.calculateEfficiency(
        scoreA,
        confidenceA,
      ).toDouble();

      final double efficiencyB =
          SessionComparison.calculateEfficiency(
        scoreB,
        confidenceB,
      ).toDouble();

      final double consistencyA =
          SessionComparison.calculateConsistency(
        framesA,
        confidenceA,
      ).toDouble();

      final double consistencyB =
          SessionComparison.calculateConsistency(
        framesB,
        confidenceB,
      ).toDouble();

      final double techniqueA =
          SessionComparison.calculateTechnique(
        scoreA,
        kneeA,
      ).toDouble();

      final double techniqueB =
          SessionComparison.calculateTechnique(
        scoreB,
        kneeB,
      ).toDouble();

      final double weightedA =
          SessionComparison.weightedScore(
        overallScore: scoreA,
        kneeMechanics: kneeMechanicsA,
        technique: techniqueA,
        efficiency: efficiencyA,
        consistency: consistencyA,
        confidence: confidenceA,
      ).toDouble();

      final double weightedB =
          SessionComparison.weightedScore(
        overallScore: scoreB,
        kneeMechanics: kneeMechanicsB,
        technique: techniqueB,
        efficiency: efficiencyB,
        consistency: consistencyB,
        confidence: confidenceB,
      ).toDouble();

      await Future<void>.delayed(
        Duration.zero,
      );

      final pdfWinnerScore =
          winnerScore.toDouble();

      pdf.addPage(
        pw.MultiPage(
          pageFormat:
              pdf_lib.PdfPageFormat.a4,
          margin:
              const pw.EdgeInsets.all(28),
          build: (context) {
            return [
              pw.Text(
                'Running Session Comparison Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'AI Sports Talent Assessment',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color:
                      pdf_lib.PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding:
                    const pw.EdgeInsets.all(
                  14,
                ),
                decoration:
                    pw.BoxDecoration(
                  border: pw.Border.all(
                    color:
                        pdf_lib.PdfColors.grey300,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Compared Sessions',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(
                      height: 8,
                    ),
                    pw.Text(
                      '$athleteA  •  '
                      'Score ${scoreA.toStringAsFixed(1)}',
                    ),
                    pw.Text(
                      '$athleteB  •  '
                      'Score ${scoreB.toStringAsFixed(1)}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Comparison Result',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                winnerName == 'Tie'
                    ? 'Result: Performance Match / Tie'
                    : 'Higher weighted score: $winnerName',
              ),
              pw.Text(
                'Weighted score: '
                '${pdfWinnerScore.toStringAsFixed(1)} / 100',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Metric Comparison',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border:
                    pw.TableBorder.all(
                  color:
                      pdf_lib.PdfColors.grey300,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(
                    2.4,
                  ),
                  1: const pw.FlexColumnWidth(
                    1.3,
                  ),
                  2: const pw.FlexColumnWidth(
                    1.3,
                  ),
                },
                children: [
                  _pdfTableRow(
                    'Metric',
                    'Session A',
                    'Session B',
                    header: true,
                  ),
                  _pdfTableRow(
                    'Overall Score',
                    scoreA.toStringAsFixed(1),
                    scoreB.toStringAsFixed(1),
                  ),
                  _pdfTableRow(
                    'Knee Angle',
                    '${kneeA.toStringAsFixed(1)}°',
                    '${kneeB.toStringAsFixed(1)}°',
                  ),
                  _pdfTableRow(
                    'Confidence',
                    confidenceA.toStringAsFixed(1),
                    confidenceB.toStringAsFixed(1),
                  ),
                  _pdfTableRow(
                    'Technique',
                    techniqueA.toStringAsFixed(1),
                    techniqueB.toStringAsFixed(1),
                  ),
                  _pdfTableRow(
                    'Efficiency',
                    efficiencyA.toStringAsFixed(1),
                    efficiencyB.toStringAsFixed(1),
                  ),
                  _pdfTableRow(
                    'Consistency',
                    consistencyA.toStringAsFixed(1),
                    consistencyB.toStringAsFixed(1),
                  ),
                  _pdfTableRow(
                    'Weighted Score',
                    weightedA.toStringAsFixed(1),
                    weightedB.toStringAsFixed(1),
                    header: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'AI Summary',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                aiSummary,
                style:
                    const pw.TextStyle(
                  fontSize: 11,
                ),
              ),
              pw.SizedBox(height: 28),
              pw.Divider(
                color:
                    pdf_lib.PdfColors.grey300,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated by AI Sports Talent',
                style:
                    const pw.TextStyle(
                  fontSize: 9,
                  color:
                      pdf_lib.PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async {
          return pdf.save();
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF report generated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Unable to export PDF: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isExporting = false;
      });
    }
  }

  pw.TableRow _pdfTableRow(
    String metric,
    String valueA,
    String valueB, {
    bool header = false,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding:
              const pw.EdgeInsets.all(8),
          child: pw.Text(
            metric,
            style: pw.TextStyle(
              fontWeight: header
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding:
              const pw.EdgeInsets.all(8),
          child: pw.Text(
            valueA,
            textAlign:
                pw.TextAlign.center,
            style: pw.TextStyle(
              fontWeight: header
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding:
              const pw.EdgeInsets.all(8),
          child: pw.Text(
            valueB,
            textAlign:
                pw.TextAlign.center,
            style: pw.TextStyle(
              fontWeight: header
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARE REPORT
  // ============================================================

  Future<void> _shareReport(
    String winnerName,
    double winnerScore,
    String aiSummary,
  ) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    final String report = '''
Running Session Comparison
==========================

${winnerName == 'Tie' ? 'Result: Performance Match / Tie' : 'Higher Weighted Score: $winnerName'}

Weighted Score:
${winnerScore.toDouble().toStringAsFixed(1)} / 100

AI Summary:
$aiSummary

Generated by AI Sports Talent
''';

    try {
      final result =
          await SharePlus.instance.share(
        ShareParams(
          text: report,
          title:
              'Running Session Comparison',
          subject:
              'Running Session Comparison Report',
        ),
      );

      if (!mounted) return;

      if (result.status ==
          ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Share dialog closed.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Unable to share report: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSharing = false;
      });
    }
  }

  // ============================================================
  // EXPORT / SHARE BUTTONS
  // ============================================================

  Widget _buildExportButtons(
    String winnerName,
    double winnerScore,
    String aiSummary,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isExporting
                    ? null
                    : () {
                        _exportPdf(
                          winnerName,
                          winnerScore.toDouble(),
                          aiSummary,
                        );
                      },
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .picture_as_pdf_rounded,
                      ),
                label: Text(
                  _isExporting
                      ? 'Creating PDF...'
                      : 'Export PDF',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isSharing
                    ? null
                    : () {
                        _shareReport(
                          winnerName,
                          winnerScore.toDouble(),
                          aiSummary,
                        );
                      },
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.share_rounded,
                      ),
                label: Text(
                  _isSharing
                      ? 'Opening...'
                      : 'Share Report',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Export a printable PDF or share the comparison report with another app.',
          textAlign: TextAlign.center,
          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                  ),
        ),
      ],
    );
  }

  // ============================================================
  // NO SESSIONS
  // ============================================================

  Widget _buildNoSessionsState() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 65),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: theme
                  .colorScheme
                  .primary
                  .withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.compare_arrows_rounded,
              size: 42,
              color:
                  theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Sessions Available',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run a running analysis to create sessions that can be compared here.',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadSessions,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
                const Text('Refresh Sessions'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOT ENOUGH SESSIONS
  // ============================================================

  Widget _buildNotEnoughSessionsState() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 65),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B)
                  .withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
              size: 42,
              color:
                  Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Not Enough Sessions',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You currently have ${sessions.length} saved session. Run another analysis to compare two sessions.',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadSessions,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
                const Text('Refresh Sessions'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPARISON CONTENT
  // ============================================================

  Widget _buildComparisonContent() {
    if (sessionA == null ||
        sessionB == null ||
        sessionA == sessionB) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select two different sessions to compare.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final a = sessionA!.metrics;
    final b = sessionB!.metrics;

    // ==========================================================
    // BASE METRICS
    // ==========================================================

    final double scoreA =
        getDouble(a, 'overall_score');

    final double scoreB =
        getDouble(b, 'overall_score');

    final double kneeA =
        getDouble(a, 'average_knee_angle');

    final double kneeB =
        getDouble(b, 'average_knee_angle');

    final double confidenceA =
        getDouble(a, 'confidence');

    final double confidenceB =
        getDouble(b, 'confidence');

    final double framesA =
        getDouble(a, 'frames');

    final double framesB =
        getDouble(b, 'frames');

    // ==========================================================
    // DERIVED METRICS
    // ==========================================================

    final double kneeMechanicsA =
        SessionComparison
            .calculateKneeMechanicScore(
      kneeA,
    ).toDouble();

    final double kneeMechanicsB =
        SessionComparison
            .calculateKneeMechanicScore(
      kneeB,
    ).toDouble();

    final double efficiencyA =
        SessionComparison.calculateEfficiency(
      scoreA,
      confidenceA,
    ).toDouble();

    final double efficiencyB =
        SessionComparison.calculateEfficiency(
      scoreB,
      confidenceB,
    ).toDouble();

    final double consistencyA =
        SessionComparison.calculateConsistency(
      framesA,
      confidenceA,
    ).toDouble();

    final double consistencyB =
        SessionComparison.calculateConsistency(
      framesB,
      confidenceB,
    ).toDouble();

    final double techniqueA =
        SessionComparison.calculateTechnique(
      scoreA,
      kneeA,
    ).toDouble();

    final double techniqueB =
        SessionComparison.calculateTechnique(
      scoreB,
      kneeB,
    ).toDouble();

    final double weightedA =
        SessionComparison.weightedScore(
      overallScore: scoreA,
      kneeMechanics: kneeMechanicsA,
      technique: techniqueA,
      efficiency: efficiencyA,
      consistency: consistencyA,
      confidence: confidenceA,
    ).toDouble();

    final double weightedB =
        SessionComparison.weightedScore(
      overallScore: scoreB,
      kneeMechanics: kneeMechanicsB,
      technique: techniqueB,
      efficiency: efficiencyB,
      consistency: consistencyB,
      confidence: confidenceB,
    ).toDouble();

    // ==========================================================
    // WINNER
    // ==========================================================

    final bool isTie =
        (weightedA - weightedB).abs() < 0.01;

    final bool aIsBetter =
        SessionComparison.isSessionABetter(
      weightedA,
      weightedB,
    );

    final String winnerName = isTie
        ? 'Tie'
        : aIsBetter
            ? sessionA!.athlete
            : sessionB!.athlete;

    final double winnerScore = isTie
        ? weightedA
        : aIsBetter
            ? weightedA
            : weightedB;

    // ==========================================================
    // DIFFERENCE
    // ==========================================================

    final double differencePercent =
        weightedA == 0.0
            ? 0.0
            : ((weightedB - weightedA) /
                    weightedA) *
                100.0;

    // ==========================================================
    // AI SUMMARY
    // ==========================================================

    final String aiSummary =
        SessionComparison.generateSummary(
      scoreA: scoreA,
      scoreB: scoreB,
      kneeA: kneeA,
      kneeB: kneeB,
      confidenceA: confidenceA,
      confidenceB: confidenceB,
    );

    // ==========================================================
    // FINAL CONTENT
    // ==========================================================

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // WINNER
        _buildWinnerCard(
          winnerName,
          winnerScore.toDouble(),
          differencePercent.toDouble(),
        ),

        const SizedBox(height: 20),

        // AI SUMMARY
        _buildAISummary(
          aiSummary,
        ),

        const SizedBox(height: 24),

        // RADAR SECTION
        _sectionTitle(
          title: 'Performance Profile',
          subtitle:
              'Compare the key performance dimensions',
          icon: Icons.radar_rounded,
        ),

        _buildRadarChart(
          scoreA: scoreA.toDouble(),
          scoreB: scoreB.toDouble(),
          kneeMechanicsA:
              kneeMechanicsA.toDouble(),
          kneeMechanicsB:
              kneeMechanicsB.toDouble(),
          techniqueA:
              techniqueA.toDouble(),
          techniqueB:
              techniqueB.toDouble(),
          efficiencyA:
              efficiencyA.toDouble(),
          efficiencyB:
              efficiencyB.toDouble(),
          consistencyA:
              consistencyA.toDouble(),
          consistencyB:
              consistencyB.toDouble(),
          confidenceA:
              confidenceA.toDouble(),
          confidenceB:
              confidenceB.toDouble(),
        ),

        const SizedBox(height: 24),

        // COMPARISON TABLE
        _sectionTitle(
          title:
              'Performance Comparison',
          subtitle:
              'Metric-by-metric breakdown',
          icon:
              Icons.table_chart_rounded,
        ),

        _buildComparisonTable(
          scoreA: scoreA.toDouble(),
          scoreB: scoreB.toDouble(),
          kneeA: kneeA.toDouble(),
          kneeB: kneeB.toDouble(),
          confidenceA:
              confidenceA.toDouble(),
          confidenceB:
              confidenceB.toDouble(),
          techniqueA:
              techniqueA.toDouble(),
          techniqueB:
              techniqueB.toDouble(),
          efficiencyA:
              efficiencyA.toDouble(),
          efficiencyB:
              efficiencyB.toDouble(),
          consistencyA:
              consistencyA.toDouble(),
          consistencyB:
              consistencyB.toDouble(),
          weightedA:
              weightedA.toDouble(),
          weightedB:
              weightedB.toDouble(),
        ),

        const SizedBox(height: 24),

        // REPORT SECTION
        _sectionTitle(
          title: 'Session Reports',
          subtitle:
              'Export or share the comparison',
          icon:
              Icons.ios_share_rounded,
        ),

        _buildExportButtons(
          winnerName,
          winnerScore.toDouble(),
          aiSummary,
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Compare Sessions'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                _isLoading
                    ? null
                    : _loadSessions,
            tooltip:
                'Refresh sessions',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : sessions.isEmpty
              ? _buildNoSessionsState()
              : sessions.length < 2
                  ? _buildNotEnoughSessionsState()
                  : RefreshIndicator(
                      onRefresh:
                          _loadSessions,
                      child:
                          ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          28,
                        ),
                        children: [
                          _buildSessionSelectors(),
                          const SizedBox(
                            height: 20,
                          ),
                          _buildComparisonContent(),
                        ],
                      ),
                    ),
    );
  }
}