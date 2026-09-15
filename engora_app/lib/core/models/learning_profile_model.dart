class SkillStats {
  final int speaking;
  final int writing;
  final int listening;
  final int vocabulary;
  final int grammar;

  SkillStats({
    required this.speaking,
    required this.writing,
    required this.listening,
    required this.vocabulary,
    required this.grammar,
  });

  factory SkillStats.fromJson(Map<String, dynamic> json) {
    return SkillStats(
      speaking: (json['speaking'] ?? 0).toInt(),
      writing: (json['writing'] ?? 0).toInt(),
      listening: (json['listening'] ?? 0).toInt(),
      vocabulary: (json['vocabulary'] ?? 0).toInt(),
      grammar: (json['grammar'] ?? 0).toInt(),
    );
  }
}

class ProfileStats {
  final String level;
  final String goal;
  final int streak;
  final int longestStreak;
  final int totalSessions;
  final int totalMinutes;
  final SkillStats skills;
  final List<String> weaknesses;
  final List<String> strengths;
  final String? aiSummary;

  ProfileStats({
    required this.level,
    required this.goal,
    required this.streak,
    required this.longestStreak,
    required this.totalSessions,
    required this.totalMinutes,
    required this.skills,
    required this.weaknesses,
    required this.strengths,
    this.aiSummary,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      level: json['level'] ?? 'A1',
      goal: json['goal'] ?? 'general',
      streak: json['streak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      totalMinutes: json['totalMinutes'] ?? 0,
      skills: SkillStats.fromJson(json['skills'] ?? {}),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
      aiSummary: json['aiSummary'],
    );
  }
}

class TodaysPractice {
  final String focus;
  final String topic;
  final List<SkillPlan> skills;

  TodaysPractice({
    required this.focus,
    required this.topic,
    required this.skills,
  });

  factory TodaysPractice.fromJson(Map<String, dynamic> json) {
    return TodaysPractice(
      focus: json['focus'] ?? '',
      topic: json['topic'] ?? '',
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((s) => SkillPlan.fromJson(s))
          .toList(),
    );
  }
}

class SkillPlan {
  final String skill;
  final int minutes;
  final String reason;

  SkillPlan({
    required this.skill,
    required this.minutes,
    required this.reason,
  });

  factory SkillPlan.fromJson(Map<String, dynamic> json) {
    return SkillPlan(
      skill: json['skill'],
      minutes: json['minutes'],
      reason: json['reason'],
    );
  }
}
