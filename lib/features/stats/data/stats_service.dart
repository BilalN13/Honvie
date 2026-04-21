import 'package:supabase_flutter/supabase_flutter.dart';

import '../../journal/models/checkin_record.dart';
import '../../recommendation/personalization_service.dart';
import '../models/stats_summary.dart';

class StatsService {
  StatsService._();

  static final StatsService instance = StatsService._();

  static const String _tableName = 'mood_checkins';
  final PersonalizationService _personalizationService =
      PersonalizationService.instance;

  SupabaseClient? get _clientOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _ensureUserId(SupabaseClient? client) async {
    if (client == null) {
      return null;
    }

    final currentUser = client.auth.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      return currentUser.id;
    }

    return null;
  }

  Future<StatsSummary> fetchStatsSummary() async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      return StatsSummary.empty;
    }

    final response = await client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('checkin_date', ascending: false);

    final records = (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CheckinRecord.fromSupabase)
        .toList();

    if (records.isEmpty) {
      return StatsSummary.empty;
    }

    final personalizationProfile = _personalizationService.buildProfile(
      records: records,
    );
    final mostFrequentPlaceType = _topPlaceType(
      personalizationProfile.placeTypeScores,
    );
    final mostFrequentCurrentEmotion = _mostFrequent<String>(
      records.map((CheckinRecord record) => record.currentEmotion),
    );
    final mostFrequentDesiredEmotion = _mostFrequent<String>(
      records.map((CheckinRecord record) => record.desiredEmotion),
    );
    final mostFrequentActivity = _mostFrequent<String>(
      records.map((CheckinRecord record) => record.activity),
    );

    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final weeklyCount = records.where((CheckinRecord record) {
      final day = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      return !day.isBefore(startOfWeek) && !day.isAfter(now);
    }).length;

    final totalCompletion = records.fold<int>(0, (
      int sum,
      CheckinRecord record,
    ) {
      return sum + record.completionLevel;
    });

    return StatsSummary(
      totalCheckins: records.length,
      weeklyCheckins: weeklyCount,
      mostFrequentCurrentEmotion: mostFrequentCurrentEmotion,
      mostFrequentDesiredEmotion: mostFrequentDesiredEmotion,
      mostFrequentActivity: mostFrequentActivity,
      mostFrequentPlaceType: mostFrequentPlaceType,
      averageCompletionLevel: totalCompletion / records.length,
      streak: _currentStreak(records),
      last7DaysAvg: _averageForLastDays(records, days: 7),
      trend: _trend(records),
      insights: _buildInsights(
        records: records,
        profile: personalizationProfile,
        mostFrequentDesiredEmotion: mostFrequentDesiredEmotion,
        mostFrequentActivity: mostFrequentActivity,
        mostFrequentPlaceType: mostFrequentPlaceType,
      ),
    );
  }

  T? _mostFrequent<T>(Iterable<T?> values) {
    final counts = <T, int>{};

    for (final value in values) {
      if (value == null) {
        continue;
      }
      counts.update(value, (int current) => current + 1, ifAbsent: () => 1);
    }

    if (counts.isEmpty) {
      return null;
    }

    final ordered = counts.entries.toList()
      ..sort((MapEntry<T, int> left, MapEntry<T, int> right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) {
          return byCount;
        }
        return left.key.toString().compareTo(right.key.toString());
      });

    return ordered.first.key;
  }

  int _currentStreak(List<CheckinRecord> records) {
    final uniqueDays =
        records
            .map((CheckinRecord record) {
              return DateTime(
                record.date.year,
                record.date.month,
                record.date.day,
              );
            })
            .toSet()
            .toList()
          ..sort((DateTime left, DateTime right) => right.compareTo(left));

    if (uniqueDays.isEmpty) {
      return 0;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (uniqueDays.first != normalizedToday) {
      return 0;
    }

    var streak = 1;
    var cursor = normalizedToday;

    for (var index = 1; index < uniqueDays.length; index++) {
      final expectedPrevious = cursor.subtract(const Duration(days: 1));
      if (uniqueDays[index] != expectedPrevious) {
        break;
      }

      streak += 1;
      cursor = expectedPrevious;
    }

    return streak;
  }

  double _averageForLastDays(List<CheckinRecord> records, {required int days}) {
    final completionByDay = <String, int>{};

    for (final record in records) {
      completionByDay[CheckinRecord.dateKey(record.date)] =
          record.completionLevel;
    }

    final today = DateTime.now();
    var total = 0;

    for (var index = 0; index < days; index++) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: index));
      total += completionByDay[CheckinRecord.dateKey(day)] ?? 0;
    }

    return total / days;
  }

  String _trend(List<CheckinRecord> records) {
    final recentAvg = _averageForRange(records, startOffset: 0, endOffset: 6);
    final previousAvg = _averageForRange(
      records,
      startOffset: 7,
      endOffset: 13,
    );

    final delta = recentAvg - previousAvg;
    if (delta >= 0.2) {
      return 'up';
    }
    if (delta <= -0.2) {
      return 'down';
    }
    return 'stable';
  }

  double _averageForRange(
    List<CheckinRecord> records, {
    required int startOffset,
    required int endOffset,
  }) {
    final completionByDay = <String, int>{};

    for (final record in records) {
      completionByDay[CheckinRecord.dateKey(record.date)] =
          record.completionLevel;
    }

    final today = DateTime.now();
    var total = 0;
    final days = endOffset - startOffset + 1;

    for (var index = startOffset; index <= endOffset; index++) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: index));
      total += completionByDay[CheckinRecord.dateKey(day)] ?? 0;
    }

    return total / days;
  }

  String? _topPlaceType(Map<String, int> placeTypeScores) {
    if (placeTypeScores.isEmpty) {
      return null;
    }

    final ordered = placeTypeScores.entries.toList()
      ..sort((MapEntry<String, int> left, MapEntry<String, int> right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) {
          return byCount;
        }
        return left.key.compareTo(right.key);
      });

    if (ordered.first.value < 3) {
      return null;
    }

    return ordered.first.key;
  }

  List<String> _buildInsights({
    required List<CheckinRecord> records,
    required PersonalizationProfile profile,
    required String? mostFrequentDesiredEmotion,
    required String? mostFrequentActivity,
    required String? mostFrequentPlaceType,
  }) {
    final insights = <String>[];

    final placeInsight = _placeTypeInsight(mostFrequentPlaceType);
    if (placeInsight != null) {
      insights.add(placeInsight);
    }

    final desiredEmotionInsight = _desiredEmotionInsight(
      mostFrequentDesiredEmotion,
    );
    if (desiredEmotionInsight != null) {
      insights.add(desiredEmotionInsight);
    }

    final activityInsight = _activityInsight(mostFrequentActivity);
    if (activityInsight != null) {
      insights.add(activityInsight);
    }

    if (insights.length < 3) {
      final continuityInsight = _continuityInsight(
        records: records,
        profile: profile,
      );
      if (continuityInsight != null) {
        insights.add(continuityInsight);
      }
    }

    return insights.take(3).toList();
  }

  String? _placeTypeInsight(String? placeType) {
    switch (placeType) {
      case 'cafe calme':
      case 'parc':
      case 'nature':
      case 'bord de mer':
      case 'librairie':
        return 'Les lieux calmes semblent souvent t aider.';
      case 'musee':
      case 'atelier':
      case 'expo':
        return 'Les lieux creatifs semblent souvent nourrir ton elan.';
      case 'cafe':
      case 'bar':
      case 'evenement':
        return 'Les lieux de lien et d ouverture reviennent souvent.';
      case 'cinema':
        return 'Les lieux qui t offrent une vraie pause reviennent souvent.';
      default:
        return null;
    }
  }

  String? _desiredEmotionInsight(String? desiredEmotion) {
    switch (desiredEmotion) {
      case 'motive':
        return 'Tu recherches souvent plus d energie.';
      case 'pose':
        return 'Tu recherches souvent plus de calme.';
      case 'social':
        return 'Tu cherches souvent plus de lien.';
      case 'creatif':
        return 'Tu veux souvent retrouver un elan plus creatif.';
      case 'curieux':
        return 'Tu cherches souvent a remettre du mouvement et de la decouverte.';
      case 'introspectif':
        return 'Tu recherches souvent un espace plus interieur.';
      default:
        return null;
    }
  }

  String? _activityInsight(String? activity) {
    switch (activity) {
      case 'marcher':
      case 'cafe calme':
      case 'respiration':
      case 'pause gourmande':
        return 'Tu choisis souvent des activites simples et accessibles.';
      case 'lecture':
      case 'ecrire':
        return 'Tu reviens souvent vers des activites calmes et personnelles.';
      case 'musee':
      case 'cinema':
        return 'Tu choisis souvent des sorties qui changent ton ambiance.';
      case 'bord de mer':
        return 'Tu te tournes souvent vers des endroits qui donnent de l espace.';
      default:
        return null;
    }
  }

  String? _continuityInsight({
    required List<CheckinRecord> records,
    required PersonalizationProfile profile,
  }) {
    if (records.length >= 10 && profile.sampleSize >= 6) {
      return 'Tes reperes deviennent plus clairs au fil des check-ins.';
    }

    if (records.length >= 4) {
      return 'Tu commences a voir ce qui te fait du bien plus regulierement.';
    }

    return null;
  }
}
