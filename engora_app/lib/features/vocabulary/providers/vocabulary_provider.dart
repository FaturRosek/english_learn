import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class VocabularyItem {
  final String id;
  final String word;
  final String partOfSpeech;
  final String definition;
  final String indonesianMeaning;
  final List<String> examples;
  final String source; // 'manual', 'speaking', 'writing', 'listening'
  int reviewCount;
  bool mastered;

  VocabularyItem({
    required this.id,
    required this.word,
    required this.partOfSpeech,
    required this.definition,
    required this.indonesianMeaning,
    required this.examples,
    required this.source,
    this.reviewCount = 0,
    this.mastered = false,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] ?? '',
      word: json['word'] ?? '',
      partOfSpeech: json['partOfSpeech'] ?? 'noun',
      definition: json['definition'] ?? '',
      indonesianMeaning: json['indonesianMeaning'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
      source: json['source'] ?? 'manual',
      reviewCount: json['reviewCount'] ?? 0,
      mastered: json['mastered'] ?? false,
    );
  }
}

class VocabularyQuiz {
  final String word;
  final String correctAnswer;
  final List<String> options;
  final String type; // 'meaning', 'fill_blank', 'sentence'

  VocabularyQuiz({
    required this.word,
    required this.correctAnswer,
    required this.options,
    required this.type,
  });
}

class VocabularyProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<VocabularyItem> _words = [];
  List<VocabularyItem> _reviewWords = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  String _filterSource = 'all';

  List<VocabularyItem> get words => _filterWords();
  List<VocabularyItem> get reviewWords => _reviewWords;
  bool get loading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterSource => _filterSource;

  int get totalWords => _words.length;
  int get masteredWords => _words.where((w) => w.mastered).length;

  List<VocabularyItem> _filterWords() {
    var filtered = _words;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((w) =>
              w.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              w.indonesianMeaning.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filterSource != 'all') {
      filtered = filtered.where((w) => w.source == _filterSource).toList();
    }
    return filtered;
  }

  Future<void> loadVocabulary() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.get(ApiConstants.vocabularyList),
        _api.get(ApiConstants.vocabularyReview),
      ]);

      _words = (results[0].data as List)
          .map((v) => VocabularyItem.fromJson(v))
          .toList();
      _reviewWords = (results[1].data as List)
          .map((v) => VocabularyItem.fromJson(v))
          .toList();
    } catch (e) {
      _error = 'Failed to load vocabulary';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<VocabularyItem?> addWord(String word) async {
    try {
      final response = await _api.post(ApiConstants.vocabularyAdd, data: {'word': word});
      final item = VocabularyItem.fromJson(response.data);
      _words.insert(0, item);
      notifyListeners();
      return item;
    } catch (_) {
      return null;
    }
  }

  Future<bool> markMastered(String vocabId) async {
    try {
      await _api.post(ApiConstants.withId(ApiConstants.vocabularyMarkMastered, vocabId));
      final idx = _words.indexWhere((w) => w.id == vocabId);
      if (idx != -1) {
        _words[idx].mastered = true;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String source) {
    _filterSource = source;
    notifyListeners();
  }

  List<VocabularyQuiz> generateQuiz(List<VocabularyItem> words) {
    final quizWords = words.take(10).toList();
    return quizWords.map((w) {
      final otherWords = _words.where((x) => x.id != w.id).toList()
        ..shuffle();
      final wrongOptions = otherWords
          .take(3)
          .map((x) => x.indonesianMeaning)
          .toList();
      final options = [w.indonesianMeaning, ...wrongOptions]..shuffle();
      return VocabularyQuiz(
        word: w.word,
        correctAnswer: w.indonesianMeaning,
        options: options,
        type: 'meaning',
      );
    }).toList();
  }
}
