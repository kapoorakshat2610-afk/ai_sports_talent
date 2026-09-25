import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  bool loading = true;
  String error = '';

  List<Map<String, dynamic>> sessions = [];

  int? sessionOneIndex;
  int? sessionTwoIndex;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final history = prefs.getStringList('history') ?? [];

      final loadedSessions = <Map<String, dynamic>>[];

      for (int i = history.length - 1; i >= 0; i--) {
        final decoded = jsonDecode(history[i]);

        final data = Map<String, dynamic>.from(
          decoded['data'] ?? {},
        );

        loadedSessions.add({
          'sessionNumber': history.length - i,
          'score': _toDouble(data['overall_score']),
          'kneeAngle': _toDouble(
            data['average_knee_angle'],
          ),
          'confidence': _toDouble(
            data['confidence'],
          ),
          'frames': _toDouble(
            data['frames'],
          ),
        });
      }

      if (!mounted) return;

      setState(() {
        sessions = loadedSessions;

        if (sessions.length >= 2) {
          sessionOneIndex = 0;
          sessionTwoIndex = 1;
        } else {
          sessionOneIndex = null;
          sessionTwoIndex = null;
        }

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Unable to load sessions: $e';
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  double _score(int index) {
    return (_toDouble(sessions[index]['score']));
  }

  double _kneeAngle(int index) {
    return (_toDouble(sessions[index]['kneeAngle']));
  }

  double _confidence(int index) {
    return (_toDouble(sessions[index]['confidence']));
  }

  double _frames(int index) {
    return (_toDouble(sessions[index]['frames']));
  }

  double _difference(double first, double second) {
    return second - first;
  }

  String _differenceText(
    double first,
    double second,
  ) {
    final difference = _difference(first, second);

    if (difference > 0) {
      return '+${difference.toStringAsFixed(1)}';
    }

    return difference.toStringAsFixed(1);
  }

  Color _scoreColor(double score) {
    if (score >= 90) {
      return Colors.green;
    }

    if (score >= 75) {
      return Colors.orange;
    }

    return Colors.red;
  }

  String _performanceLevel(double score) {
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

  Widget _sessionSelector({
    required String title,
    required int? selectedIndex,
    required ValueChanged<int?> onChanged,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: selectedIndex,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.fitness_center,
                ),
              ),
              hint: const Text(
                'Select a session',
              ),
              items: List.generate(
                sessions.length,
                (index) {
                  final score = _score(index);

                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      'Session ${index + 1}  •  '
                      'Score ${score.toStringAsFixed(1)}',
                    ),
                  );
                },
              ),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonCard({
    required String title,
    required IconData icon,
    required double firstValue,
    required double secondValue,
    required String unit,
  }) {
    final difference = secondValue - firstValue;

    Color differenceColor;

    if (difference > 0) {
      differenceColor = Colors.green;
    } else if (difference < 0) {
      differenceColor = Colors.red;
    } else {
      differenceColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Session 1',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${firstValue.toStringAsFixed(1)}$unit',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.grey,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Session 2',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${secondValue.toStringAsFixed(1)}$unit',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              'Change: ${_differenceText(firstValue, secondValue)}$unit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: differenceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreSummary() {
    if (sessionOneIndex == null ||
        sessionTwoIndex == null) {
      return const SizedBox();
    }

    final firstScore = _score(sessionOneIndex!);
    final secondScore = _score(sessionTwoIndex!);

    final difference = secondScore - firstScore;

    final bool improved = difference >= 0;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: Colors.blue,
                ),
                SizedBox(width: 10),
                Text(
                  'Comparison Result',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Session 1',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        firstScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(firstScore),
                        ),
                      ),
                      Text(
                        _performanceLevel(firstScore),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 30,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Session 2',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        secondScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(secondScore),
                        ),
                      ),
                      Text(
                        _performanceLevel(secondScore),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: improved
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                improved
                    ? 'Performance improved by '
                        '${difference.toStringAsFixed(1)} points.'
                    : 'Performance decreased by '
                        '${difference.abs().toStringAsFixed(1)} points.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: improved
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              'Not enough sessions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You need at least two saved sessions '
              'to compare performance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: loadSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Sessions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionWarning() {
    final bool sameSession =
        sessionOneIndex != null &&
        sessionTwoIndex != null &&
        sessionOneIndex == sessionTwoIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          sameSession
              ? 'Please select two different sessions.'
              : 'Select both sessions to see the comparison.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compare Sessions'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 15),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: loadSessions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (sessions.length < 2) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compare Sessions'),
        ),
        body: _emptyState(),
      );
    }

    final bool canCompare =
        sessionOneIndex != null &&
        sessionTwoIndex != null &&
        sessionOneIndex != sessionTwoIndex;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Compare Sessions'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadSessions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSessions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.compare_arrows,
                            color: Colors.blue,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Session Comparison',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select two sessions to compare '
                        'athlete performance.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sessionSelector(
                title: 'First Session',
                selectedIndex: sessionOneIndex,
                onChanged: (value) {
                  setState(() {
                    sessionOneIndex = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _sessionSelector(
                title: 'Second Session',
                selectedIndex: sessionTwoIndex,
                onChanged: (value) {
                  setState(() {
                    sessionTwoIndex = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (canCompare) ...[
                _scoreSummary(),
                const SizedBox(height: 20),
                _comparisonCard(
                  title: 'Overall Score',
                  icon: Icons.analytics,
                  firstValue: _score(sessionOneIndex!),
                  secondValue: _score(sessionTwoIndex!),
                  unit: '',
                ),
                const SizedBox(height: 12),
                _comparisonCard(
                  title: 'Knee Angle',
                  icon: Icons.accessibility_new,
                  firstValue: _kneeAngle(sessionOneIndex!),
                  secondValue: _kneeAngle(sessionTwoIndex!),
                  unit: '°',
                ),
                const SizedBox(height: 12),
                _comparisonCard(
                  title: 'Confidence',
                  icon: Icons.verified,
                  firstValue: _confidence(sessionOneIndex!),
                  secondValue: _confidence(sessionTwoIndex!),
                  unit: '',
                ),
                const SizedBox(height: 12),
                _comparisonCard(
                  title: 'Frames Analyzed',
                  icon: Icons.video_camera_back,
                  firstValue: _frames(sessionOneIndex!),
                  secondValue: _frames(sessionTwoIndex!),
                  unit: '',
                ),
              ] else ...[
                _selectionWarning(),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}