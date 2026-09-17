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
  bool get hasSession => _sessionId != null;

  Future<void> startSession({String? situation}) async {
    _situation = situation;
    _error = null;
    _messages = [];
    _feedback = null;
    _state = SpeakingState.idle;

    try {
      final response = await _api.post(ApiConstants.practiceStart, data: {
        'type': 'speaking_conversation',
        'situation': situation ?? 'Daily Conversation',
      });
      _sessionId = response.data['id'];
      _startTime = DateTime.now().millisecondsSinceEpoch;

      // Initial AI greeting
      final greetingRes = await _api.post(
        ApiConstants.practiceMessage.replaceFirst('{id}', _sessionId!),
        data: {'message': 'Hello! Let\'s start our conversation.'},
      );
      _messages.add(ChatMessage(
        role: 'ai',
        content: greetingRes.data['message'],
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start session';
      notifyListeners();
    }
  }

  Future<void> sendTextMessage(String text) async {
    if (_sessionId == null || text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    ));
    _state = SpeakingState.processing;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiConstants.practiceMessage.replaceFirst('{id}', _sessionId!),
        data: {'message': text},
      );

      _messages.add(ChatMessage(
        role: 'ai',
        content: response.data['message'],
        timestamp: DateTime.now(),
      ));
      _state = SpeakingState.idle;
    } catch (e) {
      _error = 'Failed to send message';
      _state = SpeakingState.idle;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> endSession() async {
    if (_sessionId == null) return null;
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
      _feedback = response.data['feedback'];
      _loading = false;
      notifyListeners();
      return _feedback;
    } catch (e) {
      _error = 'Failed to get feedback';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _sessionId = null;
    _state = SpeakingState.idle;
    _messages = [];
    _feedback = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
