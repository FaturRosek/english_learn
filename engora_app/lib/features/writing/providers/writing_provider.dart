import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

enum WritingMode { free, guided }

class WritingPrompt {
  final String id;
  final String title;
  final String description;
  final List<String>? guidePoints;
  final String level;

  WritingPrompt({
    required this.id,
    required this.title,
    required this.description,
    this.guidePoints,
    required this.level,
  });

  factory WritingPrompt.fromJson(Map<String, dynamic> json) {
    return WritingPrompt(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      guidePoints: json['guidePoints'] != null
          ? List<String>.from(json['guidePoints'])
          : null,
      level: json['level'] ?? 'A2',
    );
  }
}

class WritingFeedback {
  final int overallScore;
  final int grammarScore;
  final int vocabularyScore;
  final int clarityScore;
  final int spellingScore;
  final String correctedText;
  final List<Map<String, dynamic>> corrections;
  final List<String> newVocabulary;
  final List<String> strengths;
  final List<String> improvements;
  final String summary;

  WritingFeedback({
    required this.overallScore,
    required this.grammarScore,
    required this.vocabularyScore,
    required this.clarityScore,
    required this.spellingScore,
    required this.correctedText,
    required this.corrections,
    required this.newVocabulary,
    required this.strengths,
    required this.improvements,
    required this.summary,
  });

  factory WritingFeedback.fromJson(Map<String, dynamic> json) {
    return WritingFeedback(
      overallScore: json['overallScore'] ?? 0,
      grammarScore: json['grammarScore'] ?? 0,
      vocabularyScore: json['vocabularyScore'] ?? 0,
      clarityScore: json['clarityScore'] ?? 0,
      spellingScore: json['spellingScore'] ?? 0,
      correctedText: json['correctedText'] ?? '',
      corrections: List<Map<String, dynamic>>.from(json['corrections'] ?? []),
      newVocabulary: List<String>.from(json['newVocabulary'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      summary: json['summary'] ?? '',
    );
  }
}

class WritingHistory {
  final String id;
  final String text;
  final String prompt;
  final WritingFeedback? feedback;
  final DateTime createdAt;

  WritingHistory({
    required this.id,
    required this.text,
    required this.prompt,
    this.feedback,
    required this.createdAt,
  });

  factory WritingHistory.fromJson(Map<String, dynamic> json) {
    return WritingHistory(
      id: json['id'] ?? '',
      text: json['content'] ?? '',
      prompt: json['prompt'] ?? '',
      feedback: json['feedback'] != null
          ? WritingFeedback.fromJson(json['feedback'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class WritingProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<WritingPrompt> _prompts = [];
  List<WritingHistory> _history = [];
  WritingFeedback? _currentFeedback;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<WritingPrompt> get prompts => _prompts;
  List<WritingHistory> get history => _history;
  WritingFeedback? get currentFeedback => _currentFeedback;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  Future<void> loadPrompts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.writingPrompts);
      _prompts = (response.data as List)
          .map((p) => WritingPrompt.fromJson(p))
          .toList();
    } catch (e) {
      _prompts = _defaultPrompts();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    try {
      final response = await _api.get(ApiConstants.writingHistory);
      _history = (response.data as List)
          .map((h) => WritingHistory.fromJson(h))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<WritingFeedback?> submitWriting({
    required String text,
    required String promptText,
    String? promptId,
  }) async {
    if (text.trim().length < 10) {
      _error = 'Please write at least a few sentences';
      notifyListeners();
      return null;
    }

    _submitting = true;
    _currentFeedback = null;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.writingSubmit, data: {
        'content': text,
        'prompt': promptText,
        if (promptId != null) 'promptId': promptId,
      });

      _currentFeedback = WritingFeedback.fromJson(response.data['feedback']);
      _submitting = false;
      notifyListeners();
      return _currentFeedback;
    } catch (e) {
      _error = 'Failed to analyze writing';
      _submitting = false;
      notifyListeners();
      return null;
    }
  }

  void clearFeedback() {
    _currentFeedback = null;
    _error = null;
    notifyListeners();
  }

  List<WritingPrompt> _defaultPrompts() {
    return [
      WritingPrompt(
        id: '1',
        title: 'Introduce Yourself',
        description: 'Write a short introduction about yourself.',
        guidePoints: [
          'Your name and where you are from',
          'Your occupation or studies',
          'Your hobbies and interests',
          'Your goals for learning English',
        ],
        level: 'A1',
      ),
      WritingPrompt(
        id: '2',
        title: 'My Weekend',
        description: 'Write about what you did last weekend.',
        guidePoints: [
          'Where you went or what you did at home',
          'Who you were with',
          'What you enjoyed the most',
          'How you felt about it',
        ],
        level: 'A2',
      ),
      WritingPrompt(
        id: '3',
        title: 'My Dream Job',
        description: 'Describe your dream job and why you want it.',
        guidePoints: [
          'What the job is',
          'What skills are required',
          'Why you are interested in it',
          'What steps you are taking to achieve it',
        ],
        level: 'B1',
      ),
      WritingPrompt(
        id: '4',
        title: 'A Challenge I Overcame',
        description: 'Write about a difficult situation you faced and how you dealt with it.',
        level: 'B1',
      ),
      WritingPrompt(
        id: '5',
        title: 'Technology in Daily Life',
        description: 'How has technology changed your daily life? Discuss the positives and negatives.',
        level: 'B2',
      ),
    ];
  }
}
