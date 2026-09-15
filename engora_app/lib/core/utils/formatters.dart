/// Utility formatters used across the app.
class Formatters {
  Formatters._();

  // ─── Date & Time ──────────────────────────────────────────────────────────

  /// Returns a human-readable relative date string.
  /// e.g. "Today", "Yesterday", "3d ago", "12/05/2026"
  static String relativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    if (diff < 30) return '${(diff / 7).floor()}w ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Formats seconds as MM:SS string.
  static String mmSs(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Formats minutes as a readable string: "5 min", "1h 30m".
  static String minutes(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // ─── Score / Progress ─────────────────────────────────────────────────────

  /// Returns a label for a score: "Excellent", "Good", "Keep Going".
  static String scoreLabel(int score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great job!';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Keep practicing';
  }

  /// Returns emoji for a score.
  static String scoreEmoji(int score) {
    if (score >= 80) return '🏆';
    if (score >= 60) return '👍';
    return '💪';
  }

  // ─── English Level ────────────────────────────────────────────────────────

  /// Returns a full CEFR level description.
  static String levelDescription(String level) {
    const map = {
      'A1': 'Beginner',
      'A2': 'Elementary',
      'B1': 'Intermediate',
      'B2': 'Upper Intermediate',
      'C1': 'Advanced',
      'C2': 'Proficient',
    };
    return map[level] ?? level;
  }

  // ─── Goal Labels ──────────────────────────────────────────────────────────

  /// Returns a display-friendly label for a learning goal key.
  static String goalLabel(String goal) {
    const map = {
      'daily_conversation': 'Daily Conversation',
      'work': 'Work English',
      'job_interview': 'Job Interview',
      'travel': 'Travel',
      'academic': 'Academic',
      'general': 'General English',
    };
    return map[goal] ?? goal;
  }

  // ─── Skill Name ───────────────────────────────────────────────────────────

  /// Capitalises first letter of a skill name.
  static String skillName(String skill) {
    if (skill.isEmpty) return skill;
    return skill[0].toUpperCase() + skill.substring(1).toLowerCase();
  }

  // ─── String Helpers ───────────────────────────────────────────────────────

  /// Truncates text to [maxLength] chars with an ellipsis.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  /// Returns initials from a full name (up to 2 letters).
  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
