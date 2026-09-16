import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class TutorMessage {
  final String role; // 'user' or 'ai'
  final String content;
  final DateTime timestamp;

  TutorMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class AiTutorProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<TutorMessage> _messages = [];
  bool _loading = false;
  String? _error;

  List<TutorMessage> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => _messages.isEmpty;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(TutorMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    ));
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Build conversation history for context
      final history = _messages
          .map((m) => {
                'role': m.role == 'user' ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await _api.post(
        ApiConstants.aiTutor,
        data: {'messages': history},
      );

      _messages.add(TutorMessage(
        role: 'ai',
        content: response.data['response'] as String,
        timestamp: DateTime.now(),
      ));
      _loading = false;
    } catch (e) {
      _error = 'Failed to get response';
      _loading = false;
    }
    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  // Quick suggestion topics
  static const List<Map<String, String>> suggestions = [
    {'text': 'Explain Past Tense', 'icon': '📖'},
    {'text': 'What\'s the difference between "say" and "tell"?', 'icon': '🤔'},
    {'text': 'Let\'s talk about work', 'icon': '💼'},
    {'text': 'Practice job interview', 'icon': '🎯'},
    {'text': 'Correct my sentence', 'icon': '✏️'},
    {'text': 'Teach me 5 new words', 'icon': '📝'},
  ];
}
