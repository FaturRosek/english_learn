import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

enum SpeakingState { idle, listening, processing, speaking }

class ChatMessage {
  final String role; // 'user' or 'ai'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class SpeakingProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String? _sessionId;
  SpeakingState _state = SpeakingState.idle;
  List<ChatMessage> _messages = [];
  Map<String, dynamic>? _feedback;
  bool _loading = false;
  String? _error;
  String? _situation;
  int _startTime = 0;

  String? get sessionId => _sessionId;
  SpeakingState get state => _state;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Map<String, dynamic>? get feedback => _feedback;
  bool get loading => _loading;
  String? get error => _error;
  String? get situation => _situation;
  bool get hasSession => _sessionId != null;
  bool get hasUserMessage => _messages.any((m) => m.role == 'user');

  Future<bool> startSession({String? situation}) async {
    final chosenSituation = situation ?? 'Daily Conversation';

    _error = null;
    _feedback = null;
    _messages = [];
    _state = SpeakingState.idle;
    _loading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.practiceStart, data: {
        'type': 'speaking_conversation',
        'situation': chosenSituation,
      });

      final sessionId = response.data?['id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('Session id missing from response');
      }

      _sessionId = sessionId;
      _situation = chosenSituation;
      _startTime = DateTime.now().millisecondsSinceEpoch;

      try {
        final greetingRes = await _api.post(
          ApiConstants.practiceMessage.replaceFirst('{id}', _sessionId!),
          data: {'message': 'Hello! Let\'s start our conversation.'},
        );
        final greeting = greetingRes.data?['message']?.toString().trim();
        _messages.add(
          greeting == null || greeting.isEmpty
              ? _fallbackGreeting()
              : ChatMessage(
                  role: 'ai',
                  content: greeting,
                  timestamp: DateTime.now(),
                ),
        );
      } catch (_) {
        _messages.add(_fallbackGreeting());
      }

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _sessionId = null;
      _situation = null;
      _startTime = 0;
      _messages = [];
      _error =
          'Failed to start session. Check your connection and try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (_sessionId == null || trimmed.isEmpty) return false;

    _error = null;
    _messages.add(ChatMessage(
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    ));
    _state = SpeakingState.processing;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiConstants.practiceMessage.replaceFirst('{id}', _sessionId!),
        data: {'message': trimmed},
      );

      final reply = response.data?['message']?.toString().trim();
      if (reply == null || reply.isEmpty) {
        throw Exception('Empty AI response');
      }

      _messages.add(ChatMessage(
        role: 'ai',
        content: reply,
        timestamp: DateTime.now(),
      ));
      _state = SpeakingState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send message. Please try again.';
      _state = SpeakingState.idle;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> endSession() async {
    if (_sessionId == null) return null;

    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final duration =
          ((DateTime.now().millisecondsSinceEpoch - _startTime) / 60000)
              .ceil()
              .clamp(1, 120);

      final response = await _api.post(
        ApiConstants.practiceEnd.replaceFirst('{id}', _sessionId!),
        data: {'durationMinutes': duration},
      );

      final data = response.data?['feedback'];
      _feedback = data is Map ? Map<String, dynamic>.from(data) : null;
      _loading = false;
      notifyListeners();
      return _feedback;
    } catch (e) {
      _error = 'Failed to get feedback. Please try again.';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _sessionId = null;
    _situation = null;
    _state = SpeakingState.idle;
    _messages = [];
    _feedback = null;
    _error = null;
    _loading = false;
    _startTime = 0;
    notifyListeners();
  }

  ChatMessage _fallbackGreeting() {
    return ChatMessage(
      role: 'ai',
      content:
          'Hi there! Great to have you practicing with me. Tell me a bit about yourself and what you would like to talk about today.',
      timestamp: DateTime.now(),
    );
  }
}
