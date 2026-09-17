import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class ListeningExercise {
  final String id;
  final String title;
  final String level;
  final String topic;
  final String audioUrl;
  final String transcript;
  final int durationSeconds;
  final List<ListeningQuestion> questions;

  ListeningExercise({
    required this.id,
    required this.title,
    required this.level,
    required this.topic,
    required this.audioUrl,
    required this.transcript,
    required this.durationSeconds,
    required this.questions,
  });

  factory ListeningExercise.fromJson(Map<String, dynamic> json) {
    return ListeningExercise(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] ?? 'A2',
      topic: json['topic'] ?? 'General',
      audioUrl: json['audioUrl'] ?? '',
      transcript: json['transcript'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 60,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => ListeningQuestion.fromJson(q))
          .toList(),
    );
  }
}

class ListeningQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;

  ListeningQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory ListeningQuestion.fromJson(Map<String, dynamic> json) {
    return ListeningQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
    );
  }
}

class ListeningResult {
  final int correctCount;
  final int totalQuestions;
  final int score;
  final Map<String, String> answers; // questionId → selected option
  final List<String> newVocabulary;
  final String feedback;

  ListeningResult({
    required this.correctCount,
    required this.totalQuestions,
    required this.score,
    required this.answers,
    required this.newVocabulary,
    required this.feedback,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

enum ListeningState { idle, playing, paused, answering, submitting, result }

class ListeningProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ListeningExercise> _exercises = [];
  ListeningExercise? _currentExercise;
  ListeningState _state = ListeningState.idle;
  Map<String, String> _userAnswers = {}; // questionId → selected option
  ListeningResult? _result;
  bool _showTranscript = false;
  bool _loading = false;
  String? _error;
  String _selectedLevel = 'all';

  // Getters
  List<ListeningExercise> get exercises => _selectedLevel == 'all'
      ? _exercises
      : _exercises.where((e) => e.level == _selectedLevel).toList();
  ListeningExercise? get currentExercise => _currentExercise;
  ListeningState get state => _state;
  Map<String, String> get userAnswers => _userAnswers;
  ListeningResult? get result => _result;
  bool get showTranscript => _showTranscript;
  bool get loading => _loading;
  String? get error => _error;
  String get selectedLevel => _selectedLevel;

  bool isAnswered(String questionId) => _userAnswers.containsKey(questionId);
  bool allAnswered() =>
      _currentExercise != null &&
      _userAnswers.length >= _currentExercise!.questions.length;

  Future<void> loadExercises() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.listeningExercises);
      _exercises = (response.data as List)
          .map((e) => ListeningExercise.fromJson(e))
          .toList();
    } catch (_) {
      // Show default exercises when backend is unavailable
      _exercises = _defaultExercises();
      _error = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void startExercise(ListeningExercise exercise) {
    _currentExercise = exercise;
    _state = ListeningState.playing;
    _userAnswers = {};
    _result = null;
    _showTranscript = false;
    notifyListeners();
  }

  void setAnswer(String questionId, String answer) {
    _userAnswers[questionId] = answer;
    notifyListeners();
  }

  void toggleTranscript() {
    _showTranscript = !_showTranscript;
    notifyListeners();
  }

  void proceedToQuestions() {
    _state = ListeningState.answering;
    notifyListeners();
  }

  Future<void> submitAnswers() async {
    if (_currentExercise == null) return;

    _state = ListeningState.submitting;
    notifyListeners();

    try {
      final path = ApiConstants.withId(
          ApiConstants.listeningSubmit, _currentExercise!.id);
      final response = await _api.post(path, data: {
        'answers': _userAnswers,
      });

      _result = ListeningResult(
        correctCount: response.data['correctCount'] ?? 0,
        totalQuestions: response.data['totalQuestions'] ?? 0,
        score: response.data['score'] ?? 0,
        answers: Map<String, String>.from(response.data['answers'] ?? {}),
        newVocabulary:
            List<String>.from(response.data['newVocabulary'] ?? []),
        feedback: response.data['feedback'] ?? '',
      );
    } catch (_) {
      // Calculate locally if API unavailable
      _result = _calculateLocal();
    } finally {
      _state = ListeningState.result;
      notifyListeners();
    }
  }

  ListeningResult _calculateLocal() {
    int correct = 0;
    for (final q in _currentExercise!.questions) {
      if (_userAnswers[q.id] == q.correctAnswer) correct++;
    }
    final total = _currentExercise!.questions.length;
    final score = total > 0 ? (correct / total * 100).round() : 0;
    return ListeningResult(
      correctCount: correct,
      totalQuestions: total,
      score: score,
      answers: _userAnswers,
      newVocabulary: const [],
      feedback: score >= 80
          ? 'Excellent listening! You understood most of the audio.'
          : score >= 60
              ? 'Good job! Try listening again to catch what you missed.'
              : 'Keep practicing. Try listening multiple times before answering.',
    );
  }

  void setLevel(String level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void reset() {
    _currentExercise = null;
    _state = ListeningState.idle;
    _userAnswers = {};
    _result = null;
    _showTranscript = false;
    notifyListeners();
  }

  // ─── Default exercises for offline / demo ────────────────────────────────

  List<ListeningExercise> _defaultExercises() {
    return [
      ListeningExercise(
        id: 'ex_1',
        title: 'A Day at the Office',
        level: 'A2',
        topic: 'Workplace',
        audioUrl: '',
        durationSeconds: 75,
        transcript:
            'Sarah: Good morning, John. Did you finish the report?\n'
            'John: Not yet. I\'ll have it done by noon.\n'
            'Sarah: Great. The client meeting is at 2 PM.\n'
            'John: I know. I\'ll bring the latest numbers.\n'
            'Sarah: Perfect. See you in the conference room.',
        questions: [
          ListeningQuestion(
            id: 'q1',
            question: 'What did Sarah ask John about?',
            options: [
              'A. The client meeting',
              'B. The report',
              'C. The conference room',
              'D. The latest numbers',
            ],
            correctAnswer: 'B. The report',
          ),
          ListeningQuestion(
            id: 'q2',
            question: 'When is the client meeting?',
            options: [
              'A. 9 AM',
              'B. Noon',
              'C. 2 PM',
              'D. 3 PM',
            ],
            correctAnswer: 'C. 2 PM',
          ),
          ListeningQuestion(
            id: 'q3',
            question: 'What will John bring to the meeting?',
            options: [
              'A. The report',
              'B. Coffee',
              'C. The latest numbers',
              'D. A presentation',
            ],
            correctAnswer: 'C. The latest numbers',
          ),
        ],
      ),
      ListeningExercise(
        id: 'ex_2',
        title: 'At the Restaurant',
        level: 'A1',
        topic: 'Daily Life',
        audioUrl: '',
        durationSeconds: 60,
        transcript:
            'Waiter: Good evening! Are you ready to order?\n'
            'Customer: Yes, I\'d like the grilled chicken, please.\n'
            'Waiter: Excellent choice. What would you like to drink?\n'
            'Customer: Just water, thank you.\n'
            'Waiter: Of course. I\'ll be right back.',
        questions: [
          ListeningQuestion(
            id: 'q1',
            question: 'What did the customer order?',
            options: [
              'A. Grilled fish',
              'B. Grilled chicken',
              'C. A salad',
              'D. Pasta',
            ],
            correctAnswer: 'B. Grilled chicken',
          ),
          ListeningQuestion(
            id: 'q2',
            question: 'What did the customer want to drink?',
            options: [
              'A. Coffee',
              'B. Juice',
              'C. Water',
              'D. Soda',
            ],
            correctAnswer: 'C. Water',
          ),
        ],
      ),
      ListeningExercise(
        id: 'ex_3',
        title: 'Job Interview',
        level: 'B1',
        topic: 'Career',
        audioUrl: '',
        durationSeconds: 90,
        transcript:
            'Interviewer: Tell me about yourself.\n'
            'Candidate: I\'ve been working in marketing for three years. '
            'I specialize in digital campaigns and social media strategy.\n'
            'Interviewer: Why do you want to join our company?\n'
            'Candidate: I admire your innovative approach to branding. '
            'I believe my skills would contribute well to your team.\n'
            'Interviewer: What is your greatest strength?\n'
            'Candidate: I\'m highly organized and I work well under pressure.',
        questions: [
          ListeningQuestion(
            id: 'q1',
            question: 'How long has the candidate been working in marketing?',
            options: [
              'A. One year',
              'B. Two years',
              'C. Three years',
              'D. Five years',
            ],
            correctAnswer: 'C. Three years',
          ),
          ListeningQuestion(
            id: 'q2',
            question: 'What does the candidate specialize in?',
            options: [
              'A. Product development',
              'B. Digital campaigns and social media',
              'C. Finance and accounting',
              'D. Customer service',
            ],
            correctAnswer: 'B. Digital campaigns and social media',
          ),
          ListeningQuestion(
            id: 'q3',
            question: 'What is the candidate\'s greatest strength?',
            options: [
              'A. Creative thinking',
              'B. Technical skills',
              'C. Being organized and working under pressure',
              'D. Public speaking',
            ],
            correctAnswer: 'C. Being organized and working under pressure',
          ),
        ],
      ),
      ListeningExercise(
        id: 'ex_4',
        title: 'Travel Conversation',
        level: 'A2',
        topic: 'Travel',
        audioUrl: '',
        durationSeconds: 70,
        transcript:
            'Tourist: Excuse me, how do I get to the train station?\n'
            'Local: Take the number 5 bus. It stops right in front.\n'
            'Tourist: How long does it take?\n'
            'Local: About 15 minutes. The bus comes every 10 minutes.\n'
            'Tourist: Thank you so much!\n'
            'Local: You\'re welcome. Have a safe trip!',
        questions: [
          ListeningQuestion(
            id: 'q1',
            question: 'Where does the tourist want to go?',
            options: [
              'A. The airport',
              'B. The hotel',
              'C. The train station',
              'D. The bus terminal',
            ],
            correctAnswer: 'C. The train station',
          ),
          ListeningQuestion(
            id: 'q2',
            question: 'Which bus should the tourist take?',
            options: [
              'A. Number 3',
              'B. Number 5',
              'C. Number 7',
              'D. Number 10',
            ],
            correctAnswer: 'B. Number 5',
          ),
          ListeningQuestion(
            id: 'q3',
            question: 'How often does the bus come?',
            options: [
              'A. Every 5 minutes',
              'B. Every 10 minutes',
              'C. Every 15 minutes',
              'D. Every 20 minutes',
            ],
            correctAnswer: 'B. Every 10 minutes',
          ),
        ],
      ),
    ];
  }
}
