import '../../home/models/home_models.dart';
import '../place_metadata.dart';

abstract final class FallbackPlaces {
  static const double defaultLatitude = 43.2965;
  static const double defaultLongitude = 5.3698;
  static const double _marseilleMinLatitude = 43.20;
  static const double _marseilleMaxLatitude = 43.32;
  static const double _marseilleMinLongitude = 5.33;
  static const double _marseilleMaxLongitude = 5.40;

  static final List<NearbyPlace> items = List<NearbyPlace>.unmodifiable(
    <NearbyPlace>[
      _marseillePlace(
        id: 'vieux-port-de-marseille',
        name: 'Vieux-Port de Marseille',
        types: <String>['bord de mer', 'evenement', 'cafe'],
        moodTags: <String>['social', 'pose'],
        popularMoodTag: 'social',
        latitude: 43.2965,
        longitude: 5.3698,
        distanceKm: 0.4,
        recommendationReason:
            'Grand classique pour une marche courte au bord de l eau.',
      ),
      _marseillePlace(
        id: 'place-aux-huiles',
        name: 'Place aux Huiles',
        types: <String>['bar', 'cafe', 'evenement'],
        moodTags: <String>['social', 'pose'],
        popularMoodTag: 'social',
        latitude: 43.2921,
        longitude: 5.3710,
        distanceKm: 0.55,
        recommendationReason:
            'Terrasses et ambiance port pour un rendez-vous simple.',
      ),
      _marseillePlace(
        id: 'mucem',
        name: 'Mucem',
        types: <String>['musee', 'expo'],
        moodTags: <String>['curieux', 'creatif'],
        popularMoodTag: 'curieux',
        latitude: 43.2969,
        longitude: 5.3614,
        distanceKm: 0.85,
        recommendationReason:
            'Lieu culturel central avec vue mer et expositions.',
      ),
      _marseillePlace(
        id: 'cinema-la-baleine',
        name: 'Cinema La Baleine',
        types: <String>['cinema', 'evenement'],
        moodTags: <String>['pose', 'curieux'],
        popularMoodTag: 'curieux',
        latitude: 43.2918,
        longitude: 5.3785,
        distanceKm: 1.1,
        recommendationReason:
            'Cinema art et essai du Cours Julien pour decrocher un peu.',
      ),
      _marseillePlace(
        id: 'cours-julien',
        name: 'Cours Julien',
        types: <String>['cafe', 'bar', 'evenement'],
        moodTags: <String>['social', 'creatif', 'curieux'],
        popularMoodTag: 'social',
        latitude: 43.2937,
        longitude: 5.3797,
        distanceKm: 1.15,
        recommendationReason:
            'Quartier anime pour un cafe, un film ou un moment social.',
      ),
      _marseillePlace(
        id: 'librairie-maupetit',
        name: 'Librairie Maupetit',
        types: <String>['librairie', 'cafe calme'],
        moodTags: <String>['introspectif', 'curieux'],
        popularMoodTag: 'introspectif',
        latitude: 43.2963,
        longitude: 5.3791,
        distanceKm: 1.0,
        recommendationReason: 'Grande librairie centrale pour lire ou flaner.',
      ),
      _marseillePlace(
        id: 'corniche-kennedy',
        name: 'Corniche Kennedy',
        types: <String>['bord de mer', 'nature'],
        moodTags: <String>['introspectif', 'pose'],
        popularMoodTag: 'pose',
        latitude: 43.2858,
        longitude: 5.3612,
        distanceKm: 2.35,
        recommendationReason:
            'Balade en bord de mer avec vue ouverte sur la rade.',
      ),
      _marseillePlace(
        id: 'palais-longchamp',
        name: 'Palais Longchamp',
        types: <String>['parc', 'musee'],
        moodTags: <String>['curieux', 'pose'],
        popularMoodTag: 'pose',
        latitude: 43.3046,
        longitude: 5.3919,
        distanceKm: 2.4,
        recommendationReason: 'Jardin et monument pour marcher au calme.',
      ),
      _marseillePlace(
        id: 'friche-la-belle-de-mai',
        name: 'Friche la Belle de Mai',
        types: <String>['atelier', 'expo', 'evenement'],
        moodTags: <String>['creatif', 'social', 'curieux'],
        popularMoodTag: 'creatif',
        latitude: 43.3113,
        longitude: 5.3841,
        distanceKm: 2.6,
        recommendationReason:
            'Spot creatif vivant pour une parenthese expo ou rooftop.',
      ),
      _marseillePlace(
        id: 'parc-borely',
        name: 'Parc Borely',
        types: <String>['parc', 'nature'],
        moodTags: <String>['pose', 'motive'],
        popularMoodTag: 'pose',
        latitude: 43.2540,
        longitude: 5.3870,
        distanceKm: 4.3,
        recommendationReason:
            'Grand parc pour souffler, marcher ou se poser pres du lac.',
      ),
      _marseillePlace(
        id: 'les-goudes',
        name: 'Les Goudes',
        types: <String>['bord de mer', 'nature'],
        moodTags: <String>['pose', 'introspectif'],
        popularMoodTag: 'pose',
        latitude: 43.2130,
        longitude: 5.3540,
        distanceKm: 10.0,
        recommendationReason:
            'Escapade bord de mer pour prendre l air loin du centre.',
      ),
    ],
  );

  static NearbyPlace _marseillePlace({
    required String id,
    required String name,
    required List<String> types,
    required List<String> moodTags,
    required double latitude,
    required double longitude,
    required double distanceKm,
    String? popularMoodTag,
    String? recommendationReason,
  }) {
    _validateMarseilleCoordinates(
      name: name,
      latitude: latitude,
      longitude: longitude,
    );
    final resolvedTypes = types.toSet().toList();

    return NearbyPlace(
      id: id,
      name: name,
      distance: _formatDistance(distanceKm),
      category: PlaceMetadata.categoryLabel(
        primaryType: null,
        internalTypes: resolvedTypes,
      ),
      icon: PlaceMetadata.iconForTypes(resolvedTypes),
      types: resolvedTypes,
      moodTags: moodTags.toSet().toList(),
      popularMoodTag: popularMoodTag,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
      recommendationReason: recommendationReason,
    );
  }

  static void _validateMarseilleCoordinates({
    required String name,
    required double latitude,
    required double longitude,
  }) {
    final isValidCoordinate =
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    if (!isValidCoordinate) {
      throw ArgumentError.value(
        '$latitude,$longitude',
        name,
        'Fallback place coordinates must be valid GPS values.',
      );
    }

    final isInMarseilleBounds =
        latitude >= _marseilleMinLatitude &&
        latitude <= _marseilleMaxLatitude &&
        longitude >= _marseilleMinLongitude &&
        longitude <= _marseilleMaxLongitude;
    if (!isInMarseilleBounds) {
      throw ArgumentError.value(
        '$latitude,$longitude',
        name,
        'Fallback place must stay within Marseille bounds.',
      );
    }
  }

  static String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
