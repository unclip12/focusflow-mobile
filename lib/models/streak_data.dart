// =============================================================
// StreakData — persisted streak state with credit points
// =============================================================

class StreakData {
  int currentStreak;
  int longestStreak;
  int creditBalance;
  String lastStreakDate; // YYYY-MM-DD — last date streak was validated
  List<String> creditUsedDates; // dates where credits saved the streak

  StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.creditBalance = 0,
    this.lastStreakDate = '',
    this.creditUsedDates = const [],
  });

  factory StreakData.fromJson(Map<String, dynamic> j) => StreakData(
        currentStreak: j['currentStreak'] as int? ?? 0,
        longestStreak: j['longestStreak'] as int? ?? 0,
        creditBalance: j['creditBalance'] as int? ?? 0,
        lastStreakDate: j['lastStreakDate'] as String? ?? '',
        creditUsedDates: j['creditUsedDates'] != null
            ? List<String>.from(j['creditUsedDates'] as List)
            : [],
      );

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'creditBalance': creditBalance,
        'lastStreakDate': lastStreakDate,
        'creditUsedDates': creditUsedDates,
      };

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    int? creditBalance,
    String? lastStreakDate,
    List<String>? creditUsedDates,
  }) =>
      StreakData(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        creditBalance: creditBalance ?? this.creditBalance,
        lastStreakDate: lastStreakDate ?? this.lastStreakDate,
        creditUsedDates: creditUsedDates ?? this.creditUsedDates,
      );
}
