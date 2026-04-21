import '../checkin/data/checkin_service.dart';
import '../home/models/home_models.dart';
import '../journal/models/checkin_record.dart';

class PersonalizationProfile {
  const PersonalizationProfile({
    required this.sampleSize,
    this.desiredEmotionScores = const <String, int>{},
    this.activityScores = const <String, int>{},
    this.placeTypeScores = const <String, int>{},
  });

  static const PersonalizationProfile empty = PersonalizationProfile(
    sampleSize: 0,
  );

  final int sampleSize;
  final Map<String, int> desiredEmotionScores;
  final Map<String, int> activityScores;
  final Map<String, int> placeTypeScores;

  bool get hasSignals {
    return desiredEmotionScores.isNotEmpty ||
        activityScores.isNotEmpty ||
        placeTypeScores.isNotEmpty;
  }
}

class PersonalizationMatch {
  const PersonalizationMatch({required this.bonus, this.reason});

  static const PersonalizationMatch none = PersonalizationMatch(bonus: 0);

  final int bonus;
  final String? reason;
}

class PersonalizationService {
  PersonalizationService._();

  static final PersonalizationService instance = PersonalizationService._();

  static const int _historyLimit = 30;
  static const int _minimumDesiredEmotionScore = 4;
  static const int _minimumActivityScore = 4;
  static const int _minimumPlaceTypeScore = 6;

  final CheckinService _checkinService = CheckinService.instance;

  PersonalizationProfile _currentProfile = PersonalizationProfile.empty;
  bool _hasLoadedProfile = false;
  Future<PersonalizationProfile>? _pendingLoad;

  PersonalizationProfile get currentProfile => _currentProfile;

  Future<PersonalizationProfile> fetchProfile({bool forceRefresh = false}) {
    if (!forceRefresh && _hasLoadedProfile) {
      return Future<PersonalizationProfile>.value(_currentProfile);
    }

    return _pendingLoad ??= _loadProfile();
  }

  Future<PersonalizationProfile> _loadProfile() async {
    try {
      final records = await _checkinService.fetchRecentCheckins(
        limit: _historyLimit,
      );
      final profile = buildProfile(records: records);
      _currentProfile = profile;
      _hasLoadedProfile = true;
      return profile;
    } finally {
      _pendingLoad = null;
    }
  }

  bool hasRecurringPreference({
    required PersonalizationProfile profile,
    String? desiredEmotion,
    String? activity,
  }) {
    if (!profile.hasSignals) {
      return false;
    }

    final desiredEmotionScore = desiredEmotion == null
        ? 0
        : (profile.desiredEmotionScores[desiredEmotion] ?? 0);
    final activityScore = activity == null
        ? 0
        : (profile.activityScores[activity] ?? 0);

    return desiredEmotionScore >= _minimumDesiredEmotionScore ||
        activityScore >= _minimumActivityScore;
  }

  PersonalizationProfile buildProfile({required List<CheckinRecord> records}) {
    final completedRecords = records.where((CheckinRecord record) {
      return record.isComplete;
    }).toList();

    if (completedRecords.isEmpty) {
      return PersonalizationProfile.empty;
    }

    final desiredEmotionScores = <String, int>{};
    final activityScores = <String, int>{};
    final placeTypeScores = <String, int>{};

    for (var index = 0; index < completedRecords.length; index++) {
      final record = completedRecords[index];
      final weight = _historyWeight(index);

      final desiredEmotion = record.desiredEmotion;
      if (desiredEmotion != null && desiredEmotion.isNotEmpty) {
        desiredEmotionScores.update(
          desiredEmotion,
          (int current) => current + weight,
          ifAbsent: () => weight,
        );
      }

      final activity = record.activity;
      if (activity != null && activity.isNotEmpty) {
        activityScores.update(
          activity,
          (int current) => current + weight,
          ifAbsent: () => weight,
        );
      }

      final inferredTypes = <String>{
        ..._desiredEmotionTypes(desiredEmotion),
        ..._activityTypes(activity),
      };

      for (final type in inferredTypes) {
        placeTypeScores.update(
          type,
          (int current) => current + weight,
          ifAbsent: () => weight,
        );
      }
    }

    return PersonalizationProfile(
      sampleSize: completedRecords.length,
      desiredEmotionScores: desiredEmotionScores,
      activityScores: activityScores,
      placeTypeScores: placeTypeScores,
    );
  }

  PersonalizationMatch matchPlace({
    required NearbyPlace place,
    required PersonalizationProfile profile,
  }) {
    if (!profile.hasSignals) {
      return PersonalizationMatch.none;
    }

    final desiredEmotionScore = _bestScoreFor(
      keys: place.moodTags,
      scores: profile.desiredEmotionScores,
      minimumScore: _minimumDesiredEmotionScore,
    );
    final activityScore = _bestActivityScoreForPlace(
      place: place,
      activityScores: profile.activityScores,
    );
    final placeTypeScore = _bestScoreFor(
      keys: place.types,
      scores: profile.placeTypeScores,
      minimumScore: _minimumPlaceTypeScore,
    );

    var bonus = 0;
    if (desiredEmotionScore > 0) {
      bonus += 1;
    }
    if (activityScore > 0 || placeTypeScore > 0) {
      bonus += 1;
    }

    if (bonus == 0) {
      return PersonalizationMatch.none;
    }

    final reason = _buildReason(
      desiredEmotionScore: desiredEmotionScore,
      activityScore: activityScore,
      placeTypeScore: placeTypeScore,
    );

    return PersonalizationMatch(bonus: bonus > 2 ? 2 : bonus, reason: reason);
  }

  int _bestActivityScoreForPlace({
    required NearbyPlace place,
    required Map<String, int> activityScores,
  }) {
    var bestScore = 0;

    for (final entry in activityScores.entries) {
      if (entry.value < _minimumActivityScore) {
        continue;
      }

      if (_matchesAny(place.types, _activityTypes(entry.key))) {
        if (entry.value > bestScore) {
          bestScore = entry.value;
        }
      }
    }

    return bestScore;
  }

  int _bestScoreFor({
    required Iterable<String> keys,
    required Map<String, int> scores,
    required int minimumScore,
  }) {
    var bestScore = 0;

    for (final key in keys) {
      final score = scores[key] ?? 0;
      if (score >= minimumScore && score > bestScore) {
        bestScore = score;
      }
    }

    return bestScore;
  }

  String _buildReason({
    required int desiredEmotionScore,
    required int activityScore,
    required int placeTypeScore,
  }) {
    if (desiredEmotionScore > 0 && placeTypeScore > 0) {
      return 'Tu sembles souvent apprecier ce type d endroit';
    }

    if (placeTypeScore > 0) {
      return 'Ce genre de lieu revient souvent dans tes choix';
    }

    if (activityScore > 0) {
      return 'Bonne option selon tes habitudes recentes';
    }

    return 'Tu sembles souvent apprecier ce type d endroit';
  }

  bool _matchesAny(List<String> placeTypes, List<String> targetTypes) {
    for (final type in placeTypes) {
      if (targetTypes.contains(type)) {
        return true;
      }
    }

    return false;
  }

  int _historyWeight(int index) {
    if (index < 5) {
      return 3;
    }
    if (index < 12) {
      return 2;
    }
    return 1;
  }

  List<String> _desiredEmotionTypes(String? desiredEmotion) {
    switch (desiredEmotion) {
      case 'pose':
        return const <String>['nature', 'parc', 'cafe calme', 'bord de mer'];
      case 'social':
        return const <String>['cafe', 'bar', 'evenement'];
      case 'creatif':
        return const <String>['musee', 'atelier', 'expo', 'librairie'];
      case 'curieux':
        return const <String>['musee', 'expo', 'atelier'];
      case 'motive':
        return const <String>['parc', 'evenement', 'atelier'];
      case 'introspectif':
        return const <String>['librairie', 'cafe calme', 'bord de mer'];
      default:
        return const <String>[];
    }
  }

  List<String> _activityTypes(String? activity) {
    switch (activity) {
      case 'marcher':
        return const <String>['parc', 'nature'];
      case 'cafe calme':
        return const <String>['cafe calme'];
      case 'musee':
        return const <String>['musee', 'expo'];
      case 'lecture':
        return const <String>['librairie', 'cafe calme'];
      case 'ecrire':
        return const <String>['cafe calme', 'librairie'];
      case 'bord de mer':
        return const <String>['bord de mer'];
      case 'cinema':
        return const <String>['cinema'];
      case 'respiration':
        return const <String>['nature', 'parc', 'cafe calme'];
      case 'pause gourmande':
        return const <String>['cafe', 'cafe calme'];
      default:
        return const <String>[];
    }
  }
}
