import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honvie/core/supabase_client.dart';

/// Service utilitaire pour récupérer les données du profil HonVie.
class ProfileService {
  const ProfileService();

  SupabaseClient get _client => supabase;

  /// Retourne le nombre de jours consécutifs avec une humeur enregistrée.
  Future<int> getConsecutiveDays() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final response = await _client
          .from('moods')
          .select('date')
          .eq('user_id', user.id)
          .order('date', ascending: false);
      final data = List<Map<String, dynamic>>.from(response as List);

      final uniqueDates = <DateTime>[];
      for (final row in data) {
        final dateValue = row['date'];
        if (dateValue == null) continue;
        final parsed = DateTime.tryParse(dateValue.toString());
        if (parsed == null) continue;
        final normalized = DateTime(parsed.year, parsed.month, parsed.day);
        if (uniqueDates.isEmpty || uniqueDates.last != normalized) {
          uniqueDates.add(normalized);
        }
      }

      if (uniqueDates.isEmpty) return 0;

      var streak = 0;
      var expectedDate = DateTime.now();
      expectedDate = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);

      for (final moodDate in uniqueDates) {
        if (moodDate.isAtSameMomentAs(expectedDate)) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else if (moodDate.isBefore(expectedDate)) {
          // Rupture de la série.
          break;
        } else {
          // moodDate est après expectedDate (doublons sur la même journée), on ignore simplement.
          continue;
        }
      }

      return streak;
    } catch (_) {
      return 0;
    }
  }

  /// Nombre total de défis complétés par l'utilisateur.
  Future<int> getCompletedChallengesCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final response = await _client
          .from('user_challenges')
          .select('id')
          .eq('user_id', user.id);

      final data = List<Map<String, dynamic>>.from(response as List);
      return data.length;
    } catch (_) {
      return 0;
    }
  }

  /// Récupère les humeurs des [days] derniers jours (par défaut 7).
  Future<List<Map<String, dynamic>>> getRecentMoods({int days = 7}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final today = DateTime.now();
    final start = today.subtract(Duration(days: days - 1));
    final startString = DateTime(start.year, start.month, start.day).toIso8601String().split('T').first;

    try {
      final response = await _client
          .from('moods')
          .select('date, mood_type')
          .eq('user_id', user.id)
          .gte('date', startString)
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      return [];
    }
  }
}
