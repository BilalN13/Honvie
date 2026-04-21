class StatsSummary {
  const StatsSummary({
    required this.totalCheckins,
    required this.weeklyCheckins,
    required this.mostFrequentCurrentEmotion,
    required this.mostFrequentDesiredEmotion,
    required this.mostFrequentActivity,
    required this.mostFrequentPlaceType,
    required this.averageCompletionLevel,
    required this.streak,
    required this.last7DaysAvg,
    required this.trend,
    required this.insights,
  });

  final int totalCheckins;
  final int weeklyCheckins;
  final String? mostFrequentCurrentEmotion;
  final String? mostFrequentDesiredEmotion;
  final String? mostFrequentActivity;
  final String? mostFrequentPlaceType;
  final double averageCompletionLevel;
  final int streak;
  final double last7DaysAvg;
  final String trend;
  final List<String> insights;

  static const StatsSummary empty = StatsSummary(
    totalCheckins: 0,
    weeklyCheckins: 0,
    mostFrequentCurrentEmotion: null,
    mostFrequentDesiredEmotion: null,
    mostFrequentActivity: null,
    mostFrequentPlaceType: null,
    averageCompletionLevel: 0,
    streak: 0,
    last7DaysAvg: 0,
    trend: 'stable',
    insights: <String>[],
  );
}
