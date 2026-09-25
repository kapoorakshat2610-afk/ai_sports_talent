
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import '../services/auth_service.dart';
import 'athlete_dashboard.dart';
import 'compare_sessions_screen.dart';
import 'performance_analytics_screen.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SessionRepository _repository = SessionRepository();
  final AuthService _authService = AuthService();

  List<SessionModel> sessions = [];

  String selectedAthlete = 'All';
  List<String> athleteList = ['All'];

  bool isLoading = true;
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFFEF4444);

      case 'intermediate':
        return const Color(0xFFF59E0B);

      case 'advanced':
        return const Color(0xFF16A34A);

      default:
        return Colors.grey;
    }
  }

  int _calcScore(Map<String, dynamic> data) {
    final storedScore = _toDouble(data['overall_score']);

    if (storedScore > 0) {
      return storedScore.round().clamp(0, 100);
    }

    const double ideal = 165;
    final knee = _toDouble(data['average_knee_angle']);

    if (knee == 0) {
      return 0;
    }

    final difference = (ideal - knee).abs();

    double score = 100 - (difference * 2);

    if (score < 0) {
      score = 0;
    }

    if (score > 100) {
      score = 100;
    }

    return score.round();
  }

  List<SessionModel> get filteredHistory {
    if (selectedAthlete == 'All') {
      return sessions;
    }

    return sessions.where((session) {
      return session.athlete == selectedAthlete;
    }).toList();
  }

  Future<void> _loadSessions() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final loaded = await _repository.getSessions();

      if (!mounted) return;

      _updateSessionState(loaded);

      setState(() {
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        sessions = [];
        athleteList = ['All'];
        selectedAthlete = 'All';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load session history.'),
        ),
      );
    }
  }

  void _updateSessionState(List<SessionModel> loaded) {
    final names = loaded
        .map((session) => session.athlete.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    names.sort();

    if (!names.contains('All')) {
      names.insert(0, 'All');
    }

    sessions = loaded;
    athleteList = names;

    if (!athleteList.contains(selectedAthlete)) {
      selectedAthlete = 'All';
    }
  }

  Future<void> _syncFromBackend() async {
    if (isSyncing) return;

    setState(() {
      isSyncing = true;
    });

    try {
      final synced = await _repository.syncFromBackend();

      if (!mounted) return;

      setState(() {
        _updateSessionState(synced);
        isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced ${synced.length} session(s) from backend.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sync sessions from backend.'),
        ),
      );
    }
  }

  Future<void> _migrateLocalHistory() async {
    if (isSyncing) return;

    setState(() {
      isSyncing = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading local history...'),
          duration: Duration(seconds: 2),
        ),
      );

      final migrated =
          await _repository.migrateLocalSessionsToBackend();

      final updated = await _repository.getSessions();

      if (!mounted) return;

      setState(() {
        _updateSessionState(updated);
        isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            migrated > 0
                ? 'Uploaded $migrated local session(s) successfully.'
                : 'No new local sessions found.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to upload local history.'),
        ),
      );
    }
  }

  Future<void> _clearHistory() async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Local History?'),
          content: const Text(
            'This removes the local cached history from this device. '
            'Backend sessions are not deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteAll();

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('history');
      await prefs.remove('runner_analysis_sessions');

      if (!mounted) return;

      setState(() {
        sessions = [];
        athleteList = ['All'];
        selectedAthlete = 'All';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local history cleared.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to clear local history.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'You will be logged out from this device. '
            'Your analysis history will remain saved in your account.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showActionsMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              6,
              16,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.cloud_sync_rounded,
                  ),
                  title: const Text('Sync from Backend'),
                  subtitle: const Text(
                    'Refresh sessions from your account',
                  ),
                  enabled: !isSyncing,
                  onTap: () {
                    Navigator.pop(sheetContext, 'sync');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.cloud_upload_rounded,
                  ),
                  title: const Text('Upload Local History'),
                  subtitle: const Text(
                    'Move older device sessions to the backend',
                  ),
                  enabled: !isSyncing,
                  onTap: () {
                    Navigator.pop(sheetContext, 'upload');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.analytics_outlined,
                  ),
                  title: const Text('Performance Analytics'),
                  subtitle: const Text(
                    'View overall performance trends',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'analytics');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.compare_arrows_rounded,
                  ),
                  title: const Text('Compare Sessions'),
                  subtitle: const Text(
                    'Compare two saved sessions',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'compare');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Clear Local Cache',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Backend sessions will not be deleted',
                  ),
                  enabled: !isSyncing,
                  onTap: () {
                    Navigator.pop(sheetContext, 'clear');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                  ),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(sheetContext, 'logout');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'sync':
        await _syncFromBackend();
        break;

      case 'upload':
        await _migrateLocalHistory();
        break;

      case 'analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PerformanceAnalyticsScreen(),
          ),
        );
        break;

      case 'compare':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const CompareSessionsScreen(),
          ),
        );
        break;

      case 'clear':
        await _clearHistory();
        break;

      case 'logout':
        await _logout();
        break;
    }
  }

  Widget _buildHeaderSummary() {
    final theme = Theme.of(context);

    final visibleSessions = filteredHistory;

    double totalScore = 0;

    for (final session in visibleSessions) {
      totalScore += _calcScore(session.metrics);
    }

    final average = visibleSessions.isEmpty
        ? 0.0
        : totalScore / visibleSessions.length;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedAthlete == 'All'
                        ? 'All Sessions'
                        : selectedAthlete,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${visibleSessions.length} recorded session'
                    '${visibleSessions.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Avg score',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteFilter() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose an athlete to focus on specific sessions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: selectedAthlete,
              decoration: const InputDecoration(
                labelText: 'Athlete',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                ),
              ),
              items: athleteList
                  .map(
                    (name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    ),
                  )
                  .toList(),
              
            onChanged: (value) {
    if (value == null) return;

    setState(() {
      selectedAthlete = value;
    });

    if (value != 'All') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AthleteDashboard(
            athlete: value,
          ),
        ),
      );
    }
  },
),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph() {
    final dataList = [...filteredHistory];

    if (dataList.length < 2) {
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  size: 28,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Performance Trend',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add at least 2 sessions to see the performance graph.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
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

    dataList.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    final spots = dataList.asMap().entries.map(
      (entry) {
        final score = _calcScore(entry.value.metrics);

        return FlSpot(
          entry.key.toDouble(),
          score.toDouble(),
        );
      },
    ).toList();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          18,
          18,
          16,
        ),
        child: SizedBox(
          height: 245,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (dataList.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withAlpha(85),
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
                    reservedSize: 35,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
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
                          index >= dataList.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.only(top: 7),
                        child: Text(
                          'S${index + 1}',
                          style: theme
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight:
                                    FontWeight.w700,
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
                  getTooltipItems: (spots) {
                    return spots.map(
                      (spot) {
                        return LineTooltipItem(
                          'Session ${spot.x.toInt() + 1}\n'
                          '${spot.y.toStringAsFixed(0)} score',
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
                  curveSmoothness: 0.18,
                  barWidth: 3.5,
                  color: primary,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter:
                        (spot, percent, bar, index) {
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
                    color: primary.withAlpha(22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(SessionModel session) {
    final theme = Theme.of(context);

    final data = session.metrics;

    final score = _calcScore(data);

    final knee =
        data['average_knee_angle']?.toString() ?? 'N/A';

    final level =
        (data['performance_level'] ?? 'unknown').toString();

    final normalizedLevel = level.isEmpty
        ? 'Unknown'
        : '${level[0].toUpperCase()}'
            '${level.substring(1).toLowerCase()}';

    final badgeColor = _levelColor(level);

    final date = session.date;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                resultData: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.athlete,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.accessibility_new_rounded,
                          size: 15,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Knee: $knee°',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${date.day.toString().padLeft(2, '0')}/'
                          '${date.month.toString().padLeft(2, '0')}/'
                          '${date.year}',
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(18),
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color: badgeColor.withAlpha(90),
                      ),
                    ),
                    child: Text(
                      normalizedLevel,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _syncFromBackend,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 55),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 43,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No History Yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No saved sessions are currently available. '
            'Sync from the backend or upload older sessions '
            'stored on this device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      isSyncing ? null : _syncFromBackend,
                  icon: const Icon(
                    Icons.cloud_sync_rounded,
                  ),
                  label: const Text('Sync'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSyncing
                      ? null
                      : _migrateLocalHistory,
                  icon: const Icon(
                    Icons.cloud_upload_rounded,
                  ),
                  label: const Text('Upload'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = filteredHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _syncFromBackend,
              tooltip: 'Sync sessions',
              icon: const Icon(
                Icons.sync_rounded,
              ),
            ),
          IconButton(
            onPressed: _showActionsMenu,
            tooltip: 'More options',
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sessions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _syncFromBackend,
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
                      _buildHeaderSummary(),
                      const SizedBox(height: 14),
                      _buildAthleteFilter(),
                      const SizedBox(height: 22),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        child: Text(
                          'Performance Trend',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildGraph(),
                      const SizedBox(height: 22),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Saved Sessions',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                              ),
                            ),
                            Text(
                              '${listToShow.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.w800,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (listToShow.isEmpty)
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding:
                                const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 38,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No sessions for this athlete',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Choose another athlete from the filter above.',
                                  textAlign:
                                      TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        )
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...listToShow.map(
                          _buildSessionCard,
                        ),
                    ],
                  ),
                ),
    );
  }
}