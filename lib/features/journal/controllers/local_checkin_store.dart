import 'package:flutter/foundation.dart';

import '../../checkin/data/checkin_service.dart';
import '../models/checkin_record.dart';

class LocalCheckinStore extends ChangeNotifier {
  LocalCheckinStore._();

  static final LocalCheckinStore instance = LocalCheckinStore._();

  final CheckinService _service = CheckinService.instance;

  CheckinRecord? _draft;
  final List<CheckinRecord> _savedRecords = <CheckinRecord>[];
  Future<void>? _pendingRemoteLoad;
  int _persistedRevision = 0;

  int get persistedRevision => _persistedRevision;

  CheckinRecord? get draftForToday {
    final draft = _draft;
    if (draft == null || !_isSameDay(draft.date, DateTime.now())) {
      return null;
    }
    return draft;
  }

  CheckinRecord? get todayRecord {
    for (final record in _sortedRecords) {
      if (_isSameDay(record.date, DateTime.now())) {
        return record;
      }
    }
    return null;
  }

  CheckinRecord? get latestSavedRecord =>
      _sortedRecords.isEmpty ? null : _sortedRecords.first;

  CheckinRecord? get activeHomeRecord =>
      draftForToday ?? todayRecord ?? latestSavedRecord;

  List<CheckinRecord> get recentChartRecords {
    final now = DateTime.now();
    final recordsByDay = <String, CheckinRecord>{};

    for (final record in _sortedRecords) {
      recordsByDay[CheckinRecord.dateKey(record.date)] = record;
    }

    final draft = draftForToday;
    if (draft != null) {
      recordsByDay[CheckinRecord.dateKey(draft.date)] = draft;
    }

    return List<CheckinRecord>.generate(7, (int index) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      final key = CheckinRecord.dateKey(date);

      return recordsByDay[key] ??
          CheckinRecord(
            date: date,
            currentEmotion: null,
            reasons: const <String>[],
            desiredEmotion: null,
            activity: null,
            completionLevel: 0,
          );
    });
  }

  int get weeklyCompletedCount {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return _savedRecords.where((record) {
      return record.isComplete &&
          !record.date.isBefore(
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          ) &&
          !_isAfterDay(record.date, now);
    }).length;
  }

  int get journalEntryIndex {
    final draft = draftForToday;
    if (draft != null) {
      return draft.nextStepIndex;
    }

    final today = todayRecord;
    if (today != null && today.isComplete) {
      return 4;
    }

    return 0;
  }

  CheckinRecord? get journalSeedRecord => draftForToday ?? todayRecord;

  // Loads the persisted records once and reuses the same in-flight future to
  // avoid duplicate requests from Home and Journal startup paths.
  Future<void> ensureRemoteHydrated() {
    return _pendingRemoteLoad ??= refreshFromRemote();
  }

  Future<void> refreshFromRemote() async {
    try {
      final today = await _service.fetchTodayCheckin();
      final recents = await _service.fetchRecentCheckins(limit: 7);

      final merged = <CheckinRecord>[];
      if (today != null) {
        merged.add(today);
      }
      for (final record in recents) {
        if (today != null && _isSameDay(record.date, today.date)) {
          continue;
        }
        merged.add(record);
      }

      _savedRecords
        ..clear()
        ..addAll(merged);
      _persistedRevision += 1;
      notifyListeners();
    } finally {
      _pendingRemoteLoad = null;
    }
  }

  void resetForAuthChange() {
    _draft = null;
    _savedRecords.clear();
    _pendingRemoteLoad = null;
    _persistedRevision += 1;
    notifyListeners();
  }

  void syncDraft(CheckinRecord record) {
    _draft = record.copyWith(date: DateTime.now());
    notifyListeners();
  }

  void applyValidatedRecord(CheckinRecord record) {
    final normalized = record.copyWith(date: DateTime.now());
    _draft = null;
    _upsertSavedRecord(normalized);
    _persistedRevision += 1;
    notifyListeners();
  }

  void applyPersistedRecord(CheckinRecord record) {
    final normalized = record.copyWith(date: record.date);
    _upsertSavedRecord(normalized);
    _persistedRevision += 1;
    notifyListeners();
  }

  void clearDraft() {
    if (_draft == null) {
      return;
    }

    _draft = null;
    notifyListeners();
  }

  List<CheckinRecord> get _sortedRecords {
    final records = List<CheckinRecord>.from(_savedRecords);
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  void _upsertSavedRecord(CheckinRecord record) {
    final existingIndex = _savedRecords.indexWhere(
      (CheckinRecord saved) => _isSameDay(saved.date, record.date),
    );

    if (existingIndex >= 0) {
      _savedRecords[existingIndex] = record;
    } else {
      _savedRecords.add(record);
    }
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  bool _isAfterDay(DateTime left, DateTime right) {
    final normalizedLeft = DateTime(left.year, left.month, left.day);
    final normalizedRight = DateTime(right.year, right.month, right.day);
    return normalizedLeft.isAfter(normalizedRight);
  }
}
