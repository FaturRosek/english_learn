import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class GrammarLesson {
  final String id;
  final String title;
  final String level;
  final String category;
  final String explanation;
  final List<Map<String, dynamic>> examples;
  bool completed;

  GrammarLesson({
    required this.id,
    required this.title,
    required this.level,
    required this.category,
    required this.explanation,
    required this.examples,
    this.completed = false,
  });

  factory GrammarLesson.fromJson(Map<String, dynamic> json) {
    return GrammarLesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] ?? 'A1',
      category: json['category'] ?? 'general',
      explanation: json['explanation'] ?? '',
      examples: List<Map<String, dynamic>>.from(json['examples'] ?? []),
      completed: json['completed'] ?? false,
    );
  }
}

class GrammarWeakness {
  final String topic;
  final int errorCount;
  final String recommendation;

  GrammarWeakness({
    required this.topic,
    required this.errorCount,
    required this.recommendation,
  });

  factory GrammarWeakness.fromJson(Map<String, dynamic> json) {
    return GrammarWeakness(
      topic: json['topic'] ?? '',
      errorCount: json['errorCount'] ?? 0,
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class GrammarProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<GrammarLesson> _lessons = [];
  List<GrammarWeakness> _weaknesses = [];
  GrammarLesson? _recommendedLesson;
  String? _explanation;
  bool _loading = false;
  bool _explaining = false;
  String? _error;
  String _selectedLevel = 'all';

  List<GrammarLesson> get lessons => _selectedLevel == 'all'
      ? _lessons
      : _lessons.where((l) => l.level == _selectedLevel).toList();
  List<GrammarWeakness> get weaknesses => _weaknesses;
  GrammarLesson? get recommendedLesson => _recommendedLesson;
  String? get explanation => _explanation;
  bool get loading => _loading;
  bool get explaining => _explaining;
  String? get error => _error;
  String get selectedLevel => _selectedLevel;

  Future<void> loadGrammar() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.get(ApiConstants.grammarLessons),
        _api.get(ApiConstants.grammarWeaknesses),
        _api.get(ApiConstants.grammarRecommended),
      ]);

      _lessons = (results[0].data as List)
          .map((l) => GrammarLesson.fromJson(l))
          .toList();
      _weaknesses = (results[1].data as List)
          .map((w) => GrammarWeakness.fromJson(w))
          .toList();

      if (results[2].data != null) {
        _recommendedLesson = GrammarLesson.fromJson(results[2].data);
      }
    } catch (e) {
      _lessons = _defaultLessons();
      _error = null; // Show default content
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> explainTopic(String topic) async {
    _explaining = true;
    _explanation = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.grammarExplain, data: {
        'topic': topic,
      });
      _explanation = response.data['explanation'] as String?;
      _explaining = false;
      notifyListeners();
      return _explanation;
    } catch (e) {
      _explaining = false;
      notifyListeners();
      return null;
    }
  }

  void setLevel(String level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void clearExplanation() {
    _explanation = null;
    notifyListeners();
  }

  List<GrammarLesson> _defaultLessons() {
    return [
      GrammarLesson(
        id: '1',
        title: 'To Be (am, is, are)',
        level: 'A1',
        category: 'verb',
        explanation: 'Use "am" with I, "is" with he/she/it, and "are" with you/we/they.',
        examples: [
          {'sentence': 'I am a student.', 'translation': 'Saya adalah seorang pelajar.'},
          {'sentence': 'She is happy.', 'translation': 'Dia senang.'},
          {'sentence': 'They are my friends.', 'translation': 'Mereka adalah teman saya.'},
        ],
      ),
      GrammarLesson(
        id: '2',
        title: 'Simple Present Tense',
        level: 'A1',
        category: 'tense',
        explanation:
            'Use simple present for habits, facts, and routines. Add -s/-es for third person singular.',
        examples: [
          {'sentence': 'I eat breakfast every day.', 'translation': 'Saya sarapan setiap hari.'},
          {'sentence': 'She works in an office.', 'translation': 'Dia bekerja di kantor.'},
        ],
      ),
      GrammarLesson(
        id: '3',
        title: 'Simple Past Tense',
        level: 'A2',
        category: 'tense',
        explanation:
            'Use simple past for completed actions. Regular verbs add -ed. Irregular verbs change form.',
        examples: [
          {'sentence': 'I went to the store yesterday.', 'translation': 'Saya pergi ke toko kemarin.'},
          {'sentence': 'She cooked dinner last night.', 'translation': 'Dia memasak makan malam tadi malam.'},
        ],
      ),
      GrammarLesson(
        id: '4',
        title: 'Future Tense (will)',
        level: 'A2',
        category: 'tense',
        explanation:
            'Use "will + base verb" for predictions and spontaneous decisions.',
        examples: [
          {'sentence': 'I will call you tomorrow.', 'translation': 'Saya akan meneleponmu besok.'},
          {'sentence': 'It will rain today.', 'translation': 'Hari ini akan hujan.'},
        ],
      ),
      GrammarLesson(
        id: '5',
        title: 'Present Perfect',
        level: 'B1',
        category: 'tense',
        explanation:
            'Use present perfect (have/has + past participle) for experiences or actions connected to the present.',
        examples: [
          {'sentence': 'I have visited Japan twice.', 'translation': 'Saya sudah mengunjungi Jepang dua kali.'},
          {'sentence': 'She has just finished the report.', 'translation': 'Dia baru saja selesai laporan.'},
        ],
      ),
      GrammarLesson(
        id: '6',
        title: 'Conditional Sentences',
        level: 'B1',
        category: 'conditional',
        explanation:
            'If clauses express conditions. Type 1: real possibility. Type 2: hypothetical.',
        examples: [
          {'sentence': 'If it rains, I will stay home.', 'translation': 'Jika hujan, saya akan tinggal di rumah.'},
          {'sentence': 'If I were rich, I would travel the world.', 'translation': 'Kalau saya kaya, saya akan keliling dunia.'},
        ],
      ),
    ];
  }
}
