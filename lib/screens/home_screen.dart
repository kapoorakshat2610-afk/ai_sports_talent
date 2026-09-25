import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import 'result_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
   final AuthService _authService = AuthService();
  // Existing AI analysis backend.
  static const String _analysisBaseUrl =
      "https://runner-analyzer-api-1.onrender.com";

  final SessionRepository _repository = SessionRepository();

  File? _videoFile;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;

  String _athleteName = "";
  final TextEditingController _nameController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // PICK VIDEO
  // ------------------------------------------------------------

  Future<void> _pickVideo() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (res == null || res.files.isEmpty) return;

    final path = res.files.single.path;

    if (path == null) return;

    setState(() {
      _videoFile = File(path);
      _result = null;
    });
  }

  // ------------------------------------------------------------
  // TEST EXISTING ANALYSIS SERVER
  // ------------------------------------------------------------

  Future<void> _pingServer() async {
    try {
      final response = await http.get(
        Uri.parse("$_analysisBaseUrl/"),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Analysis server: ${response.statusCode}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Server error: $e",
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // OLD LOCAL HISTORY FALLBACK
  // ------------------------------------------------------------

  Future<void> _saveResultLocally(
    Map<String, dynamic> data,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final entry = jsonEncode({
      "time": DateTime.now().toIso8601String(),
      "athlete": _athleteName,
      "data": data,
    });

    final history =
        prefs.getStringList("history") ?? [];

    history.insert(0, entry);

    await prefs.setStringList(
      "history",
      history,
    );
  }

  // ------------------------------------------------------------
  // CONVERT ANALYSIS RESULT TO SESSION
  // ------------------------------------------------------------

  SessionModel _createSessionModel(
    Map<String, dynamic> data,
  ) {
    final framesValue =
        data["frames"] ??
        data["frames_analyzed"] ??
        0;

    final confidenceValue =
        data["confidence"] ??
        data["keypoints_confidence"] ??
        0;

    return SessionModel(
      sessionId:
          DateTime.now().millisecondsSinceEpoch.toString(),
      athlete: _athleteName,
      date: DateTime.now(),
      metrics: {
        ...data,

        "overall_score":
            data["overall_score"] ?? 0.0,

        "average_knee_angle":
            data["average_knee_angle"] ?? 0.0,

        "confidence":
            confidenceValue,

        "frames":
            framesValue,

        "performance_level":
            data["performance_level"] ??
                "unknown",
      },
    );
  }

  // ------------------------------------------------------------
  // SAVE SESSION TO BACKEND
  // ------------------------------------------------------------

  Future<void> _saveSessionToBackend(
    Map<String, dynamic> data,
  ) async {
    final session =
        _createSessionModel(data);

    try {
      await _repository.saveSession(
        session,
      );
    } catch (e) {
      debugPrint(
        "Backend session save failed: $e",
      );

      // Keep local fallback alive.
      await _saveResultLocally(data);
    }
  }

  // ------------------------------------------------------------
  // REAL ANALYSIS
  // ------------------------------------------------------------

  Future<void> _analyzeVideo() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a video first.",
          ),
        ),
      );
      return;
    }

    if (_athleteName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter athlete name",
          ),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final uri = Uri.parse(
        "$_analysisBaseUrl/analyze_video",
      );

      final request =
    http.MultipartRequest(
  "POST",
  uri,
);

final authHeaders =
    await _authService.authHeaders();

request.headers.addAll(authHeaders);

request.files.add(
  await http.MultipartFile.fromPath(
    "file",
    _videoFile!.path,
  ),
);

      final streamed =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamed,
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Analysis server ${response.statusCode}: "
          "${response.body}",
        );
      }

      final decoded =
          jsonDecode(response.body);

      final result =
          decoded is Map<String, dynamic>
              ? Map<String, dynamic>.from(
                  decoded,
                )
              : <String, dynamic>{
                  "raw": decoded,
                };

      // Normalize important fields.
      result["overall_score"] ??= 0;
      result["performance_level"] ??=
          "Unknown";

      result["average_knee_angle"] ??= 0;
      result["ideal_knee_angle"] ??= 165;
      result["difference_from_ideal"] ??= 0;

      result["confidence"] ??=
          result["keypoints_confidence"] ??
              0;

      result["frames"] ??=
          result["frames_analyzed"] ??
              0;

      result["ml_used"] ??= false;
      result["source"] ??= "Unknown";

      result["mistakes"] ??= [];
      result["strengths"] ??= [];
      result["improvements"] ??= [];
      result["suggestions"] ??= [];

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });

      // --------------------------------------------------------
      // SAVE LOCALLY
      // --------------------------------------------------------

      await _saveResultLocally(result);

      if (!mounted) return;

      // --------------------------------------------------------
      // OPEN RESULT SCREEN
      // --------------------------------------------------------

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            resultData: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // DEMO MODE
  // ------------------------------------------------------------

  Future<void> _runDemo() async {
    if (_athleteName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter athlete name",
          ),
        ),
      );
      return;
    }

    final demo = <String, dynamic>{
      "overall_score": 92.0,
      "average_knee_angle": 164.2,
      "difference_from_ideal": 0.8,
      "ideal_knee_angle": 165,
      "performance_level": "advanced",

      "confidence": 0.85,
      "keypoints_confidence": 0.85,

      "frames": 20,
      "frames_analyzed": 20,

      "mistakes": [
        "No major mistakes detected.",
      ],

      "strengths": [
        "Good running mechanics.",
        "Strong overall form.",
      ],

      "improvements": [
        "Maintain consistency.",
      ],

      "suggestions": [
        "Maintain this running form and consistency.",
        "Keep stride smooth and controlled.",
      ],

      "ml_used": true,
      "source": "demo_mode",
    };

    setState(() {
      _result = demo;
    });

    // Save locally.
    await _saveResultLocally(
      demo,
    );

    // Save to backend.
    await _saveSessionToBackend(
      demo,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          resultData: demo,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fileName = _videoFile == null
        ? "No video selected"
        : _videoFile!.path
            .split(Platform.pathSeparator)
            .last;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Runner Analyzer",
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(16),
            child: ListView(
              children: [
                // ------------------------------------------------
                // ATHLETE
                // ------------------------------------------------

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Athlete",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextField(
                          controller:
                              _nameController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Athlete Name",
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _athleteName =
                                value.trim();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ------------------------------------------------
                // VIDEO
                // ------------------------------------------------

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Step 1: Select Video",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(fileName),
                        const SizedBox(
                          height: 12,
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              _isAnalyzing
                                  ? null
                                  : _pickVideo,
                          icon: const Icon(
                            Icons.video_file,
                          ),
                          label: const Text(
                            "Choose Video",
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _isAnalyzing
                                  ? null
                                  : _pingServer,
                          icon: const Icon(
                            Icons.wifi_tethering,
                          ),
                          label: const Text(
                            "Test Server Connection",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ------------------------------------------------
                // ANALYZE
                // ------------------------------------------------

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Step 2: Analyze",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              (_videoFile ==
                                          null ||
                                      _isAnalyzing)
                                  ? null
                                  : _analyzeVideo,
                          icon: const Icon(
                            Icons.analytics,
                          ),
                          label: const Text(
                            "Analyze Video",
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _isAnalyzing
                                  ? null
                                  : _runDemo,
                          icon: const Icon(
                            Icons.science,
                          ),
                          label: const Text(
                            "Run Demo Analysis",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // LOADING OVERLAY
          // ------------------------------------------------------

          if (_isAnalyzing)
            Container(
              color: Colors.black
                  .withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Analyzing your performance...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      "AI is evaluating motion patterns",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}