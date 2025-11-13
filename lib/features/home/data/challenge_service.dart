import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honvie/core/supabase_client.dart';

/// Service pour interagir avec les défis quotidiens stockés dans Supabase.
class ChallengeService {
  const ChallengeService();

  SupabaseClient get _client => supabase;

  String get _today => DateTime.now().toIso8601String().split('T').first;

  /// Récupère le défi du jour ou null si aucun n'a été défini.
  Future<Map<String, dynamic>?> getTodayChallenge() async {
    try {
      final result = await _client
          .from('daily_challenges')
          .select()
          .eq('challenge_date', _today)
          .maybeSingle();
      return result;
    } on PostgrestException catch (error) {
      throw Exception('Impossible de charger le défi du jour: ${error.message}');
    } catch (error) {
      throw Exception('Erreur inattendue lors du chargement: $error');
    }
  }

  /// Crée ou met à jour le défi du jour manuellement.
  Future<void> setTodayChallenge(Map<String, dynamic> challenge) async {
    final payload = {
      ...challenge,
      'challenge_date': _today,
    };

    try {
      await _client.from('daily_challenges').upsert(
            payload,
            onConflict: 'challenge_date',
          );
    } on PostgrestException catch (error) {
      throw Exception('Impossible d\'enregistrer le défi du jour: ${error.message}');
    } catch (error) {
      throw Exception('Erreur inattendue lors de l\'enregistrement: $error');
    }
  }

  /// Indique si l'utilisateur courant a déjà validé le défi du jour.
  Future<bool> hasUserCompletedToday() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    final challenge = await getTodayChallenge();
    if (challenge == null) return false;

    final challengeId = challenge['id'];
    if (challengeId == null) return false;

    try {
      final result = await _client
          .from('user_challenges')
          .select('id')
          .eq('user_id', user.id)
          .eq('challenge_id', challengeId)
          .maybeSingle();
      return result != null;
    } on PostgrestException catch (error) {
      throw Exception('Impossible de vérifier l\'état du défi: ${error.message}');
    } catch (error) {
      throw Exception('Erreur inattendue lors de la vérification du défi: $error');
    }
  }

  /// Marque le défi du jour comme complété pour l'utilisateur courant.
  Future<void> completeChallenge() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    final challenge = await getTodayChallenge();
    if (challenge == null || challenge['id'] == null) {
      throw Exception('Aucun défi du jour disponible.');
    }

    try {
      await _client.from('user_challenges').insert({
        'user_id': user.id,
        'challenge_id': challenge['id'],
        'completed_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (error) {
      throw Exception('Impossible de valider le défi: ${error.message}');
    } catch (error) {
      throw Exception('Erreur inattendue lors de la validation du défi: $error');
    }
  }
}
