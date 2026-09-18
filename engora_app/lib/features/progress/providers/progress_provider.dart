import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/learning_profile_model.dart';

class PracticeHistoryItem {
  final String id;
  final String type;
  final String topic;
  final int durationMinutes;
  final int score;
  final DateTime completedAt;

  PracticeHistoryItem({
    required this.id,
    required this.type,
    required this.topic,
    required this.durationMinutes,
    required this.score,
    required this.completedAt,
  });

  factory PracticeHistoryItem.fromJson(Map<String, dynamic> json) {
    return PracticeHistoryItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'speaking',
      topic: json['topic'] ?? json['situation'] ?? 'Practice',
      durationMinutes: json['durationMinutes'] ?? 0,
      score: json['feedback']?['overallScore'] ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ProgressProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  ProfileStats? _stats;
  List<PracticeHistoryItem> _history = [];
  bool _loading = false;
  String? _error;

  ProfileStats? get stats => _stats;
  List<PracticeHistoryItem> get history => _history;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProgress() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.get(ApiConstants.profileStats),
        _api.get(ApiConstants.practiceHistory),
      ]);

      _stats = ProfileStats.fromJson(results[0].data);
      _history = (results[1].data as List)
          .map((h) => PracticeHistoryItem.fromJson(h))
          .toList();
    } catch (e) {
      _error = 'Failed to load progress';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadProgress();
}
