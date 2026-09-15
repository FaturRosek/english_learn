class ApiConstants {
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
  static const String baseUrl = 'http://localhost:3000/api/v1'; // Windows / iOS / Web

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // Profile
  static const String onboarding = '/profile/onboarding';
  static const String profileStats = '/profile/stats';
  static const String todaysPractice = '/profile/todays-practice';
  static const String learningPath = '/profile/learning-path';

  // Practice (Speaking)
  static const String practiceStart = '/practice/sessions/start';
  static const String practiceMessage = '/practice/sessions/{id}/message';
  static const String practiceEnd = '/practice/sessions/{id}/end';
  static const String practiceHistory = '/practice/sessions';
  static const String aiTutor = '/practice/ai-tutor';

  // Writing
  static const String writingSubmit = '/writing/submit';
  static const String writingHistory = '/writing/history';
  static const String writingPrompts = '/writing/prompts';

  // Vocabulary
  static const String vocabularyAdd = '/vocabulary/add';
  static const String vocabularyList = '/vocabulary';
  static const String vocabularyReview = '/vocabulary/review';
  static const String vocabularyMarkMastered = '/vocabulary/{id}/mastered';

  // Grammar
  static const String grammarLessons = '/grammar/lessons';
  static const String grammarWeaknesses = '/grammar/weaknesses';
  static const String grammarExplain = '/grammar/explain';
  static const String grammarRecommended = '/grammar/recommended';
  static const String grammarMarkComplete = '/grammar/lessons/{id}/complete';

  // Listening
  static const String listeningExercises = '/listening/exercises';
  static const String listeningSubmit = '/listening/exercises/{id}/submit';
  static const String listeningHistory = '/listening/history';

  /// Replace {id} placeholder in path.
  static String withId(String path, String id) => path.replaceFirst('{id}', id);
}
