import 'package:supabase_flutter/supabase_flutter.dart';

import '../../journal/models/checkin_record.dart';
import '../../recommendation/personalization_service.dart';
import '../models/history_item.dart';

class HistoryService {
  HistoryService._();

  static final HistoryService instance = HistoryService._();

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

  Future<List<HistoryItem>> fetchCheckinHistory({int limit = 30}) async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      return const <HistoryItem>[];
    }

    final response = await client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('checkin_date', ascending: false)
        .limit(limit);

    final records = (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CheckinRecord.fromSupabase)
        .toList();

    final personalizationProfile = _personalizationService.buildProfile(
      records: records,
    );

    return records.map((CheckinRecord record) {
      return HistoryItem.fromCheckinRecord(
        record,
        personalizationProfile: personalizationProfile,
      );
    }).toList();
  }
}
