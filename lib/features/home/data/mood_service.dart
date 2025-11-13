import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honvie/core/supabase_client.dart';

/// Service léger pour persister l'humeur quotidienne de l'utilisateur.
class MoodService {
  const MoodService();

  SupabaseClient get _client => supabase;

  /// Enregistre ou met à jour l'humeur du jour pour l'utilisateur courant.
  Future<void> saveMoodForToday(String moodType) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    try {
      await _client.from('moods').upsert(
        {
          'user_id': user.id,
          'date': DateTime.now().toIso8601String().split('T').first,
          'mood_type': moodType,
        },
        onConflict: 'user_id,date',
      );
    } on PostgrestException catch (error) {
      throw Exception('Impossible d\'enregistrer l\'humeur: ${error.message}');
    } catch (error) {
      throw Exception('Erreur inattendue lors de l\'enregistrement de l\'humeur: $error');
    }
  }

  /// Retourne l'humeur du jour ou null si aucune n'a été enregistrée.
  Future<String?> getMoodForToday() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    try {
      final response = await _client
          .from('moods')
          .select('mood_type')
          .eq('user_id', user.id)
          .eq('date', dateOnly.toIso8601String())
          .maybeSingle();

      return response?['mood_type'] as String?;
    } on PostgrestException catch (error) {
      throw Exception('Impossible de récupérer l\'humeur: ${error.message}');
    } catch (error) {
      throw Exception('Erreur inattendue lors de la récupération de l\'humeur: $error');
    }
  }
}
