import 'package:flutter/material.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() =>
      _LeaderboardScreenState();
}

class _LeaderboardScreenState
    extends State<LeaderboardScreen> {
  final SessionRepository _repository =
      SessionRepository();

  List<Map<String, dynamic>> rankings = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLeaderboard();
  }

  double _toDouble(dynamic value) {
    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  Future<void> loadLeaderboard() async {
    setState(() {
      isLoading = true;
    });

    try {
      final sessions =
          await _repository.getSessions();

      final Map<String, List<double>>
          athleteScores = {};

      for (final SessionModel session in sessions) {
        final athlete =
            session.athlete.trim().isEmpty
                ? 'Unknown'
                : session.athlete.trim();

        final score = _toDouble(
          session.metrics['overall_score'],
        );

        athleteScores
            .putIfAbsent(
              athlete,
              () => [],
            )
            .add(score);
      }

      final List<Map<String, dynamic>>
          result = [];

      athleteScores.forEach(
        (athlete, scores) {
          if (scores.isEmpty) return;

          double total = 0;
          double best = scores.first;

          for (final score in scores) {
            total += score;

            if (score > best) {
              best = score;
            }
          }

          final average =
              total / scores.length;

          result.add({
            'athlete': athlete,
            'avg': average,
            'best': best,
            'sessions': scores.length,
          });
        },
      );

      result.sort(
        (a, b) {
          final bestCompare =
              (b['best'] as double)
                  .compareTo(
                    a['best'] as double,
                  );

          if (bestCompare != 0) {
            return bestCompare;
          }

          return (b['avg'] as double)
              .compareTo(
                a['avg'] as double,
              );
        },
      );

      if (!mounted) return;

      setState(() {
        rankings = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        rankings = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load leaderboard: $e',
          ),
        ),
      );
    }
  }

  Widget _buildMedal(int index) {
    if (index == 0) {
      return const Text(
        '🥇',
        style: TextStyle(
          fontSize: 24,
        ),
      );
    }

    if (index == 1) {
      return const Text(
        '🥈',
        style: TextStyle(
          fontSize: 24,
        ),
      );
    }

    if (index == 2) {
      return const Text(
        '🥉',
        style: TextStyle(
          fontSize: 24,
        ),
      );
    }

    return CircleAvatar(
      radius: 16,
      child: Text(
        '${index + 1}',
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🏆 Athlete Leaderboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
            onPressed:
                isLoading ? null : loadLeaderboard,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : rankings.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadLeaderboard,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 220,
                      ),
                      Center(
                        child: Text(
                          'No athlete data available',
                          style:
                              TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadLeaderboard,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        rankings.length,
                    itemBuilder:
                        (context, index) {
                      final athlete =
                          rankings[index];

                      final best =
                          athlete['best']
                              as double;

                      final average =
                          athlete['avg']
                              as double;

                      final count =
                          athlete['sessions']
                              as int;

                      return Card(
                        elevation: 4,
                        margin:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            8,
                          ),
                          child: ListTile(
                            leading:
                                _buildMedal(
                              index,
                            ),
                            title: Text(
                              athlete['athlete']
                                  as String,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'Sessions: $count',
                                ),
                                Text(
                                  'Best Score: '
                                  '${best.toStringAsFixed(1)}',
                                ),
                              ],
                            ),
                            trailing:
                                Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                const Text(
                                  'AVG',
                                  style:
                                      TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                Text(
                                  average
                                      .toStringAsFixed(
                                    1,
                                  ),
                                  style:
                                      TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        _scoreColor(
                                      average,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}