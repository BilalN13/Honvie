import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honvie/core/supabase_client.dart';

class InspirationService {
  const InspirationService();

  SupabaseClient get _client => supabase;

  Future<Map<String, dynamic>?> getRandomQuote() async {
    try {
      final data = await _client
          .from('inspiration_quotes')
          .select()
          .eq('is_active', true);

      final list = List<Map<String, dynamic>>.from(data as List);
      if (list.isEmpty) return null;

      final randomIndex = Random().nextInt(list.length);
      return list[randomIndex];
    } catch (error) {
      // ignore: avoid_print
      print('Erreur getRandomQuote: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRandomRitual() async {
    try {
      final data = await _client
          .from('inspiration_rituals')
          .select()
          .eq('is_active', true);

      final list = List<Map<String, dynamic>>.from(data as List);
      if (list.isEmpty) return null;

      final randomIndex = Random().nextInt(list.length);
      return list[randomIndex];
    } catch (error) {
      // ignore: avoid_print
      print('Erreur getRandomRitual: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTips() async {
    try {
      final data = await _client
          .from('inspiration_tips')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (error) {
      // ignore: avoid_print
      print('Erreur getTips: $error');
      return [];
    }
  }
}
