import '../home/models/home_models.dart';
import 'personalization_service.dart';

class RecommendationService {
  RecommendationService._();

  static final RecommendationService instance = RecommendationService._();
  static const int _contextMatchScoreThreshold = 7;
  static const int _topRecommendationMinimumScore = 4;
  static const int _maxContextMatches = 3;

  List<NearbyPlace> mergeAndRankPlaces({
    required List<NearbyPlace> googlePlaces,
    required List<NearbyPlace> userPlaces,
    required String? currentEmotion,
    required String? desiredEmotion,
    required String? activity,
    PersonalizationProfile? personalizationProfile,
  }) {
    final merged = <NearbyPlace>[
      ..._deduplicatePlaces(userPlaces),
      ..._deduplicatePlaces(googlePlaces),
    ];

    return rankPlaces(
      places: _deduplicatePlaces(merged),
      currentEmotion: currentEmotion,
      desiredEmotion: desiredEmotion,
      activity: activity,
      personalizationProfile: personalizationProfile,
    );
  }

  List<String> recommendedPlaceTypes({
    required String? currentEmotion,
    required String? desiredEmotion,
    required String? activity,
  }) {
    final ordered = <String>[
      ..._desiredEmotionTypes(desiredEmotion),
      ..._activityTypes(activity),
      ..._currentEmotionTypes(currentEmotion),
    ];

    final unique = ordered.toSet().toList();
    if (unique.isEmpty) {
      return const <String>['cafe calme', 'parc', 'musee'];
    }

    return unique;
  }

  List<NearbyPlace> rankPlaces({
    required List<NearbyPlace> places,
    required String? currentEmotion,
    required String? desiredEmotion,
    required String? activity,
    PersonalizationProfile? personalizationProfile,
  }) {
    final desiredTypes = _desiredEmotionTypes(desiredEmotion);
    final activityTypes = _activityTypes(activity);
    final currentTypes = _currentEmotionTypes(currentEmotion);
    final profile = personalizationProfile ?? PersonalizationProfile.empty;

    final ranked = places.map((NearbyPlace place) {
      final distanceKm = _placeDistanceInKm(place);
      final desiredMatched = _matchesAny(place.types, desiredTypes);
      final activityMatched = _matchesAny(place.types, activityTypes);
      final currentMatched = _matchesAny(place.types, currentTypes);
      final desiredMoodMatched = _matchesMoodTag(
        place.moodTags,
        desiredEmotion,
      );
      final currentMoodMatched = _matchesMoodTag(
        place.moodTags,
        currentEmotion,
      );
      final personalizationMatch = PersonalizationService.instance.matchPlace(
        place: place,
        profile: profile,
      );

      var score = 0;
      if (desiredMatched) {
        score += 4;
      }
      if (desiredMoodMatched) {
        score += 6;
      }
      if (activityMatched) {
        score += 3;
      }
      if (currentMatched) {
        score += 1;
      }
      if (currentMoodMatched) {
        score += 1;
      }
      if (place.isUserAdded) {
        score += 2;
      }
      score += personalizationMatch.bonus;
      score += _socialProofBoost(place.socialProofCount);

      if (distanceKm < 1) {
        score += 2;
      } else if (distanceKm < 3) {
        score += 1;
      }

      final hasDesiredContextMatch = desiredMatched || desiredMoodMatched;
      final isContextCandidate =
          (hasDesiredContextMatch && activityMatched) ||
          score >= _contextMatchScoreThreshold;

      return place.copyWith(
        recommendationScore: score,
        recommendationReason: _buildReason(
          place: place,
          desiredEmotion: desiredEmotion,
          activity: activity,
          desiredMatched: desiredMatched,
          desiredMoodMatched: desiredMoodMatched,
          activityMatched: activityMatched,
          currentMatched: currentMatched,
          distanceKm: distanceKm,
          personalizationReason: personalizationMatch.reason,
        ),
        isContextMatch: isContextCandidate,
      );
    }).toList();

    ranked.sort((NearbyPlace left, NearbyPlace right) {
      final byScore = right.recommendationScore.compareTo(
        left.recommendationScore,
      );
      if (byScore != 0) {
        return byScore;
      }

      return _placeDistanceInKm(left).compareTo(_placeDistanceInKm(right));
    });

    final hasContextualMatch = ranked.any((NearbyPlace place) {
      return place.recommendationScore >= 4;
    });

    if (!hasContextualMatch) {
      ranked.sort((NearbyPlace left, NearbyPlace right) {
        final byDistance = _placeDistanceInKm(
          left,
        ).compareTo(_placeDistanceInKm(right));
        if (byDistance != 0) {
          return byDistance;
        }

        return right.recommendationScore.compareTo(left.recommendationScore);
      });
    }

    return _limitContextMatches(ranked);
  }

  List<NearbyPlace> _limitContextMatches(List<NearbyPlace> places) {
    var remainingContextMatches = _maxContextMatches;

    return places.map((NearbyPlace place) {
      if (!place.isContextMatch) {
        return place.copyWith(isContextMatch: false);
      }

      if (remainingContextMatches <= 0) {
        return place.copyWith(isContextMatch: false);
      }

      remainingContextMatches -= 1;
      return place;
    }).toList();
  }

  NearbyPlace? topRecommendedPlace({required List<NearbyPlace> places}) {
    for (final place in places) {
      if (place.isContextMatch ||
          place.recommendationScore >= _topRecommendationMinimumScore) {
        return place;
      }
    }

    return null;
  }

  String buildHistoryInsightBase({
    required String? currentEmotion,
    required List<String> reasons,
    required String? desiredEmotion,
  }) {
    final primaryReason = _historyPrimaryReason(reasons);
    final desiredEmotionLabel = _historyDesiredEmotionLabel(desiredEmotion);

    if (desiredEmotionLabel != null && primaryReason != null) {
      return 'Tu voulais te sentir plus $desiredEmotionLabel apres un moment lie a $primaryReason.';
    }

    if (desiredEmotionLabel != null) {
      return 'Tu voulais retrouver un peu plus de $desiredEmotionLabel dans ce moment.';
    }

    if (currentEmotion == 'enerve' && primaryReason != null) {
      return 'Ce moment semblait te peser a cause de $primaryReason.';
    }

    if (currentEmotion == 'triste' && primaryReason != null) {
      return 'Tu traversais un moment sensible lie a $primaryReason.';
    }

    if (primaryReason != null) {
      return 'Ce moment semblait beaucoup tourne autour de $primaryReason.';
    }

    return 'Ce moment comptait pour toi.';
  }

  bool _matchesAny(List<String> placeTypes, List<String> targetTypes) {
    for (final type in placeTypes) {
      if (targetTypes.contains(type)) {
        return true;
      }
    }
    return false;
  }

  double _distanceInKm(String distance) {
    final normalized = distance.trim().toLowerCase();

    if (normalized.endsWith('km')) {
      final value = normalized.replaceAll('km', '').trim();
      return double.tryParse(value) ?? 99;
    }

    if (normalized.endsWith('m')) {
      final value = normalized.replaceAll('m', '').trim();
      final meters = double.tryParse(value) ?? 99000;
      return meters / 1000;
    }

    return 99;
  }

  double _placeDistanceInKm(NearbyPlace place) {
    if (place.distanceKm != null) {
      return place.distanceKm!;
    }

    return _distanceInKm(place.distance);
  }

  String _buildReason({
    required NearbyPlace place,
    required String? desiredEmotion,
    required String? activity,
    required bool desiredMatched,
    required bool desiredMoodMatched,
    required bool activityMatched,
    required bool currentMatched,
    required double distanceKm,
    required String? personalizationReason,
  }) {
    if (desiredMatched || desiredMoodMatched || activityMatched) {
      return _currentCheckinReason(
        place: place,
        desiredEmotion: desiredEmotion,
        activity: activity,
        desiredMatched: desiredMatched,
        desiredMoodMatched: desiredMoodMatched,
        activityMatched: activityMatched,
      );
    }

    if (personalizationReason != null) {
      return personalizationReason;
    }

    return _fallbackReason(
      place: place,
      currentMatched: currentMatched,
      distanceKm: distanceKm,
    );
  }

  String _currentCheckinReason({
    required NearbyPlace place,
    required String? desiredEmotion,
    required String? activity,
    required bool desiredMatched,
    required bool desiredMoodMatched,
    required bool activityMatched,
  }) {
    if (place.isUserAdded && desiredMoodMatched) {
      if (place.socialProofCount > 1) {
        return 'Tu reviens souvent vers ce genre de lieu';
      }
      return 'Ca pourrait t aider a te recentrer';
    }

    if (desiredMatched) {
      switch (desiredEmotion) {
        case 'pose':
          return 'Ca pourrait t aider a te recentrer';
        case 'social':
          return 'Une option douce pour t ouvrir un peu';
        case 'creatif':
          return 'Un bon appui pour ton elan creatif';
        case 'introspectif':
          return 'Une option douce pour ton moment interieur';
        case 'curieux':
          return 'Ca pourrait nourrir ton envie de decouverte';
        case 'motive':
          return 'Ca peut soutenir ton elan du moment';
      }
    }

    if (activityMatched) {
      switch (activity) {
        case 'marcher':
          return 'Une option douce pour bouger un peu';
        case 'cafe calme':
          return 'Une option douce pour te poser';
        case 'musee':
          return 'Ca pourrait t aider a changer d ambiance';
        case 'lecture':
          return 'Un cadre doux pour ralentir un peu';
        case 'ecrire':
          return 'Ca pourrait t aider a poser tes pensees';
        case 'bord de mer':
          return 'Ca pourrait t aider a prendre un peu d air';
        case 'cinema':
          return 'Une option douce pour decrocher un peu';
        case 'respiration':
          return 'Un bon cadre pour revenir au calme';
        case 'pause gourmande':
          return 'Une option douce pour souffler un peu';
      }
    }

    return 'Une option douce pour ton moment actuel';
  }

  String _fallbackReason({
    required NearbyPlace place,
    required bool currentMatched,
    required double distanceKm,
  }) {
    if (distanceKm < 1) {
      if (place.isUserAdded) {
        return 'Une option simple, tout pres de toi';
      }
      return 'Une option simple, pres de toi';
    }

    if (currentMatched) {
      return 'Une option douce pour ton moment actuel';
    }

    if (place.isUserAdded) {
      if (place.socialProofCount > 1) {
        return 'Un lieu qui peut te faire du bien';
      }
      return 'Une option simple pour aujourd hui';
    }

    return 'Une option douce pour ton moment actuel';
  }

  int _socialProofBoost(int socialProofCount) {
    if (socialProofCount < 2) {
      return 0;
    }

    return socialProofCount > 4 ? 4 : socialProofCount - 1;
  }

  List<NearbyPlace> _deduplicatePlaces(List<NearbyPlace> places) {
    final seenKeys = <String>{};
    final deduplicated = <NearbyPlace>[];

    for (final place in places) {
      final key = _placeKey(place);
      if (seenKeys.add(key)) {
        deduplicated.add(place);
      }
    }

    return deduplicated;
  }

  String _placeKey(NearbyPlace place) {
    final lat = place.latitude?.toStringAsFixed(4) ?? '';
    final lng = place.longitude?.toStringAsFixed(4) ?? '';
    return '${place.name.toLowerCase()}|$lat|$lng';
  }

  bool _matchesMoodTag(List<String> moodTags, String? targetMood) {
    if (targetMood == null) {
      return false;
    }

    return moodTags.contains(targetMood);
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

  List<String> _currentEmotionTypes(String? currentEmotion) {
    switch (currentEmotion) {
      case 'enerve':
        return const <String>['nature', 'parc', 'cafe calme', 'bord de mer'];
      case 'triste':
        return const <String>[
          'cafe calme',
          'nature',
          'librairie',
          'bord de mer',
        ];
      case 'neutre':
        return const <String>['cafe calme', 'parc', 'musee'];
      case 'content':
        return const <String>['cafe', 'parc', 'musee'];
      case 'joyeux':
        return const <String>['evenement', 'cafe', 'bar', 'expo'];
      default:
        return const <String>[];
    }
  }

  String? _historyPrimaryReason(List<String> reasons) {
    if (reasons.isEmpty) {
      return null;
    }

    return reasons.first.trim().toLowerCase();
  }

  String? _historyDesiredEmotionLabel(String? desiredEmotion) {
    switch (desiredEmotion) {
      case 'motive':
        return 'motive';
      case 'pose':
        return 'apaise';
      case 'curieux':
        return 'curieux';
      case 'creatif':
        return 'creatif';
      case 'social':
        return 'ouvert';
      case 'introspectif':
        return 'aligne';
      default:
        return null;
    }
  }
}
