import 'package:supabase_flutter/supabase_flutter.dart';

import '../../journal/models/checkin_record.dart';

class CheckinService {
  CheckinService._();

  static final CheckinService instance = CheckinService._();

  static const String _tableName = 'mood_checkins';

  SupabaseClient? get _clientOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      // Tests can build the widget tree without running main(), so Supabase
      // may legitimately be unavailable in that context.
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

  Future<void> upsertTodayCheckin(CheckinRecord record) async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      throw StateError('Supabase authentication unavailable.');
    }

    final now = DateTime.now();

    await client
        .from(_tableName)
        .upsert(
          record.toSupabaseUpsert(userId: userId, now: now),
          onConflict: 'user_id,checkin_date',
        );
  }

  Future<CheckinRecord> updateTodayJournalContext({
    required String selectedPlaceName,
    CheckinPlaceStatus? selectedPlaceStatus,
    String? writtenNote,
  }) async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      throw StateError('Supabase authentication unavailable.');
    }

    final existingRecord = await fetchTodayCheckin();
    if (existingRecord == null) {
      throw StateError('No validated check-in found for today.');
    }

    final now = DateTime.now();
    final normalizedPlaceName = selectedPlaceName.trim();
    final normalizedNote = writtenNote?.trim();

    final updatedRecord = existingRecord.copyWith(
      userId: userId,
      createdAt: existingRecord.createdAt ?? now,
      updatedAt: now,
      selectedPlaceName: normalizedPlaceName.isEmpty
          ? existingRecord.selectedPlaceName
          : normalizedPlaceName,
      selectedPlaceStatus:
          selectedPlaceStatus ?? existingRecord.selectedPlaceStatus,
      writtenNote: normalizedNote == null || normalizedNote.isEmpty
          ? existingRecord.writtenNote
          : normalizedNote,
    );

    await client
        .from(_tableName)
        .upsert(
          updatedRecord.toSupabaseUpsert(userId: userId, now: now),
          onConflict: 'user_id,checkin_date',
        );

    return updatedRecord;
  }

  Future<CheckinRecord?> fetchTodayCheckin() async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      return null;
    }

    final response = await client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('checkin_date', CheckinRecord.dateKey(DateTime.now()))
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return CheckinRecord.fromSupabase(response);
  }

  Future<List<CheckinRecord>> fetchRecentCheckins({int limit = 7}) async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      return const <CheckinRecord>[];
    }

    final response = await client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('checkin_date', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CheckinRecord.fromSupabase)
        .toList();
  }
}
