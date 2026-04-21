import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../checkin/data/checkin_service.dart';
import '../../checkin/widgets/place_journal_actions.dart';
import '../../checkin/widgets/place_note_dialog.dart';
import '../../auth/auth_service.dart';
import '../../../core/location/location_service.dart';
import '../../../core/maps/google_maps_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/event_model.dart';
import '../../events/event_service.dart';
import '../../journal/constants/checkin_mappings.dart';
import '../../journal/controllers/local_checkin_store.dart';
import '../../journal/models/checkin_record.dart';
import '../../places/data/fallback_places.dart';
import '../../places/data/google_places_service.dart';
import '../../places/place_metadata.dart';
import '../../places_user/user_place_model.dart';
import '../../places_user/user_place_service.dart';
import '../../places_user/widgets/add_user_place_modal.dart';
import '../../profile/pages/profile_page.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../recommendation/personalization_service.dart';
import '../../recommendation/recommendation_service.dart';
import '../models/home_models.dart';
import '../widgets/check_in_progress_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_section_title.dart';
import '../widgets/last_checkin_card.dart';
import '../widgets/mood_chart_card.dart';
import '../widgets/nearby_event_card.dart';
import '../widgets/nearby_place_card.dart';
import '../widgets/suggested_activity_card.dart';
import '../widgets/week_calendar_strip.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onViewMoreOptionsPressed});

  final VoidCallback? onViewMoreOptionsPressed;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Duration _recentCheckinMaxAge = Duration(days: 3);

  final LocalCheckinStore _store = LocalCheckinStore.instance;
  final LocationService _locationService = LocationService.instance;
  final GooglePlacesService _googlePlacesService = GooglePlacesService.instance;
  final UserPlaceService _userPlaceService = UserPlaceService.instance;
  final EventService _eventService = EventService.instance;
  final CheckinService _checkinService = CheckinService.instance;
  final PersonalizationService _personalizationService =
      PersonalizationService.instance;
  String _lastRecommendationKey = '';
  late List<NearbyPlace> _allRecommendedPlaces;
  late List<NearbyPlace> _resolvedNearbyPlaces;
  NearbyPlace? _topRecommendedPlace;
  List<EventItem> _nearbyEvents = const <EventItem>[];
  PersonalizationProfile _personalizationProfile = PersonalizationProfile.empty;

  static final List<NearbyPlace> _fallbackNearbyPlaces = FallbackPlaces.items;

  static const List<SuggestedActivity> _suggestedActivities =
      <SuggestedActivity>[
        SuggestedActivity(
          title: 'Coffee break',
          subtitle: 'A calmer stop nearby',
          tag: 'Soft',
          icon: Icons.local_cafe_rounded,
        ),
        SuggestedActivity(
          title: 'Short walk',
          subtitle: '10 min to reset your mood',
          tag: 'Quick',
          icon: Icons.directions_walk_rounded,
        ),
        SuggestedActivity(
          title: 'Breathing pause',
          subtitle: 'A light reset before tonight',
          tag: 'Now',
          icon: Icons.air_rounded,
        ),
      ];

  @override
  void initState() {
    super.initState();
    final initialRankedPlaces = _rankPlaces(
      _recommendationRecord,
      googlePlaces: _fallbackNearbyPlaces,
    );
    _allRecommendedPlaces = initialRankedPlaces;
    _resolvedNearbyPlaces = initialRankedPlaces.take(3).toList();
    _topRecommendedPlace = _resolveTopRecommendedPlace(initialRankedPlaces);
    _store.addListener(_handleStoreChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNearbyPlaces(force: true);
    });
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    super.dispose();
  }

  void _handleStoreChanged() {
    final record = _recommendationRecord;
    final recommendationKey = _recommendationKey(record);
    if (recommendationKey == _lastRecommendationKey) {
      return;
    }

    _applyLocalRecommendationUpdate(record);
    _refreshNearbyPlaces();
  }

  Future<void> _refreshNearbyPlaces({bool force = false}) async {
    final record = _recommendationRecord;
    final recommendationKey = _recommendationKey(record);

    if (!force && recommendationKey == _lastRecommendationKey) {
      return;
    }

    _lastRecommendationKey = recommendationKey;
    final personalizationFuture = _personalizationService.fetchProfile(
      forceRefresh: true,
    );

    final fallbackRanked = _rankPlaces(
      record,
      googlePlaces: _fallbackNearbyPlaces,
      personalizationProfile: _personalizationProfile,
    );
    if (mounted) {
      setState(() {
        _allRecommendedPlaces = fallbackRanked;
        _resolvedNearbyPlaces = fallbackRanked.take(3).toList();
        _topRecommendedPlace = _resolveTopRecommendedPlace(fallbackRanked);
      });
    }

    final location = await _locationService.getCurrentLocation();
    if (!mounted || _lastRecommendationKey != recommendationKey) {
      return;
    }

    final personalizationProfile = await personalizationFuture;
    if (!mounted || _lastRecommendationKey != recommendationKey) {
      return;
    }

    _personalizationProfile = personalizationProfile;

    if (location == null) {
      final rerankedFallback = _rankPlaces(
        record,
        googlePlaces: _fallbackNearbyPlaces,
        personalizationProfile: personalizationProfile,
      );
      setState(() {
        _allRecommendedPlaces = rerankedFallback;
        _resolvedNearbyPlaces = rerankedFallback.take(3).toList();
        _topRecommendedPlace = _resolveTopRecommendedPlace(rerankedFallback);
      });
      return;
    }

    final types = RecommendationService.instance.recommendedPlaceTypes(
      currentEmotion: record?.currentEmotion,
      desiredEmotion: record?.desiredEmotion,
      activity: record?.activity,
    );

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _eventService.fetchNearbyEvents(
        lat: location.latitude,
        lng: location.longitude,
        currentEmotion: record?.currentEmotion,
        desiredEmotion: record?.desiredEmotion,
        activity: record?.activity,
      ),
      _googlePlacesService.fetchNearbyPlaces(
        lat: location.latitude,
        lng: location.longitude,
        includedTypes: types,
      ),
      _userPlaceService.fetchNearbyPlaces(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    ]);

    final events = results[0] as List<EventItem>;
    final realPlaces = results[1] as List<NearbyPlace>;
    final userPlaces = results[2] as List<NearbyPlace>;

    if (mounted && _lastRecommendationKey == recommendationKey) {
      setState(() {
        _nearbyEvents = events;
      });
    }

    if (!mounted || _lastRecommendationKey != recommendationKey) {
      return;
    }

    if (realPlaces.isEmpty) {
      debugPrint(
        'HomePage: Google Places unavailable or returned 0 places. '
        'Fallback places are being used, and add buttons may be disabled '
        'because fallback places do not include latitude/longitude.',
      );
    }

    setState(() {
      final rankedPlaces = _rankPlaces(
        record,
        googlePlaces: realPlaces.isEmpty ? _fallbackNearbyPlaces : realPlaces,
        userPlaces: userPlaces,
        personalizationProfile: personalizationProfile,
      );
      _allRecommendedPlaces = rankedPlaces;
      _resolvedNearbyPlaces = rankedPlaces.take(3).toList();
      _topRecommendedPlace = _resolveTopRecommendedPlace(rankedPlaces);
    });
  }

  CheckinRecord? get _recommendationRecord {
    return _store.todayRecord ?? _store.latestSavedRecord;
  }

  void _applyLocalRecommendationUpdate(CheckinRecord? record) {
    final basePlaces = _allRecommendedPlaces.isEmpty
        ? _fallbackNearbyPlaces
        : _allRecommendedPlaces;
    final rerankedPlaces = _rankPlaces(
      record,
      googlePlaces: basePlaces,
      personalizationProfile: _personalizationProfile,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _allRecommendedPlaces = rerankedPlaces;
      _resolvedNearbyPlaces = rerankedPlaces.take(3).toList();
      _topRecommendedPlace = _resolveTopRecommendedPlace(rerankedPlaces);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (BuildContext context, _) {
        final accountProfile = AuthService.instance.currentUserProfile;
        final todayRecord = _store.draftForToday ?? _store.todayRecord;
        final latestRecord = _store.draftForToday ?? _store.latestSavedRecord;
        final latestValidatedRecord =
            _store.todayRecord ?? _store.latestSavedRecord;
        final hasRecentCheckin = _hasRecentCheckin(latestValidatedRecord);
        final summary = _buildSummary(todayRecord);
        final moodEntries = _buildMoodEntries(_store.recentChartRecords);
        final lastCheckIn = _buildLastCheckIn(latestRecord);
        final nearbyPlaces = _resolvedNearbyPlaces.take(3).toList();
        final nearbyEvents = _nearbyEvents.take(3).toList();
        final topRecommendedPlace = _topRecommendedPlace;

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 126),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                HomeHeader(
                  greeting:
                      'Hey, ${accountProfile?.firstName ?? 'toi'}! \u{1F44B}',
                  dateBadgeLabel: _formatHeaderDate(DateTime.now()),
                  streakLabel: '${_store.weeklyCompletedCount}',
                  trailing: ProfileAvatarButton(
                    fallbackLabel: accountProfile?.avatarFallbackLabel ?? 'H',
                    imageUrl: accountProfile?.avatarUrl,
                    onTap: _openProfilePage,
                    tooltip: accountProfile?.displayName ?? 'Profil',
                  ),
                ),
                const SizedBox(height: 10),
                WeekCalendarStrip(days: _buildWeekDays(_store)),
                const SizedBox(height: 10),
                CheckInProgressCard(summary: summary),
                const SizedBox(height: 10),
                MoodChartCard(entries: moodEntries),
                const SizedBox(height: 8),
                LastCheckInCard(snapshot: lastCheckIn),
                if (hasRecentCheckin &&
                    topRecommendedPlace != null) ...<Widget>[
                  const SizedBox(height: 18),
                  const HomeSectionTitle(
                    title: 'Suggestion du moment',
                    subtitle: 'Une option simple et coherente pour maintenant.',
                  ),
                  const SizedBox(height: 10),
                  _MomentSuggestionCard(
                    place: topRecommendedPlace,
                    onDirectionsPressed: () =>
                        _openDirectionsForPlace(topRecommendedPlace),
                    onViewMoreOptionsPressed: widget.onViewMoreOptionsPressed,
                    onFavoritePressed: () => _savePlaceSelection(
                      place: topRecommendedPlace,
                      status: CheckinPlaceStatus.favorite,
                    ),
                    onLaterPressed: () => _savePlaceSelection(
                      place: topRecommendedPlace,
                      status: CheckinPlaceStatus.later,
                    ),
                    onVisitedPressed: () => _savePlaceSelection(
                      place: topRecommendedPlace,
                      status: CheckinPlaceStatus.visited,
                    ),
                    onNotePressed: () =>
                        _promptForPlaceNote(topRecommendedPlace),
                  ),
                ] else ...<Widget>[
                  const SizedBox(height: 18),
                  const HomeSectionTitle(
                    title: 'Tu ne sais pas quoi faire ?',
                    subtitle: 'On peut te proposer une idee pres de toi.',
                  ),
                  const SizedBox(height: 10),
                  _QuickIdeaCard(onPressed: widget.onViewMoreOptionsPressed),
                ],
                const SizedBox(height: 18),
                const HomeSectionTitle(
                  title: 'Lieux autour de moi',
                  subtitle: 'Des endroits calmes a portee de main.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 212,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: nearbyPlaces.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final place = nearbyPlaces[index];

                      return NearbyPlaceCard(
                        place: place,
                        showAddButton: !place.isUserAdded,
                        onAddPressed: _buildAddPlaceAction(place),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const HomeSectionTitle(
                  title: 'Activites suggerees autour de moi',
                  subtitle: 'Toujours apres la partie emotionnelle.',
                ),
                const SizedBox(height: 10),
                Column(
                  children: List<Widget>.generate(_suggestedActivities.length, (
                    int index,
                  ) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _suggestedActivities.length - 1
                            ? 0
                            : 8,
                      ),
                      child: SuggestedActivityCard(
                        activity: _suggestedActivities[index],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const HomeSectionTitle(
                  title: 'Evenements autour de moi',
                  subtitle:
                      'Des rendez-vous proches dans les prochaines heures.',
                ),
                const SizedBox(height: 10),
                if (nearbyEvents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.88),
                      ),
                    ),
                    child: Text(
                      'Aucun evenement proche pour le moment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  Column(
                    children: List<Widget>.generate(nearbyEvents.length, (
                      int index,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == nearbyEvents.length - 1 ? 0 : 8,
                        ),
                        child: NearbyEventCard(event: nearbyEvents[index]),
                      );
                    }),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  VoidCallback? _buildAddPlaceAction(NearbyPlace place) {
    if (place.isUserAdded) {
      debugPrint(
        'HomePage: add button disabled for "${place.name}" because the place '
        'already comes from user_places aggregation.',
      );
      return null;
    }

    final currentUserExists = _hasCurrentSupabaseUser();
    final resolvedType = _resolvePlaceType(place);
    final hasName = place.name.trim().isNotEmpty;
    final hasType = resolvedType != null;
    final hasLatitude = place.latitude != null;
    final hasLongitude = place.longitude != null;
    final hasMinimalData = hasName && hasType && hasLatitude && hasLongitude;
    final usingFallbackLikeSource = !hasLatitude || !hasLongitude;

    debugPrint(
      'HomePage: add-place diagnostics for "${place.name}": '
      'currentUserExists=$currentUserExists, '
      'hasName=$hasName, '
      'hasType=$hasType, '
      'resolvedType=${resolvedType ?? 'none'}, '
      'hasLatitude=$hasLatitude, '
      'hasLongitude=$hasLongitude, '
      'isUserAdded=${place.isUserAdded}.',
    );

    if (!hasMinimalData) {
      if (usingFallbackLikeSource) {
        debugPrint(
          'HomePage: add button disabled for "${place.name}" because the place '
          'is missing latitude/longitude. This usually means the card is coming '
          'from fallback/mock data or another source without precise coordinates.',
        );
      } else {
        debugPrint(
          'HomePage: add button disabled for "${place.name}" because minimal '
          'data are incomplete. Required: name + type + latitude + longitude.',
        );
      }
      return null;
    }

    debugPrint(
      'HomePage: add button enabled for "${place.name}". Minimal place data '
      'are available and Supabase auth is not required to pre-enable the CTA.',
    );

    return () => _handleAddPlace(place);
  }

  bool _hasCurrentSupabaseUser() {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      return currentUser != null && !currentUser.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openProfilePage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
  }

  String? _resolvePlaceType(NearbyPlace place) {
    for (final candidate in PlaceMetadata.selectableTypes) {
      if (place.types.contains(candidate)) {
        return candidate;
      }
    }

    if (place.types.isNotEmpty) {
      return place.types.first;
    }

    return null;
  }

  Future<void> _handleAddPlace(NearbyPlace place) async {
    final resolvedType = _resolvePlaceType(place);

    debugPrint(
      'HomePage: opening add place modal for "${place.name}". '
      'currentUserExists=${_hasCurrentSupabaseUser()}, '
      'hasName=${place.name.trim().isNotEmpty}, '
      'hasType=${resolvedType != null}, '
      'resolvedType=${resolvedType ?? 'none'}, '
      'hasLatitude=${place.latitude != null}, '
      'hasLongitude=${place.longitude != null}.',
    );

    final draft = await showModalBottomSheet<UserPlaceDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddUserPlaceModal(place: place),
    );

    if (draft == null) {
      return;
    }

    try {
      await _userPlaceService.savePlace(draft);
    } catch (error, stackTrace) {
      debugPrint(
        'HomePage: savePlace failed for "${draft.name}". '
        'This may depend on Supabase auth, the user_places table migration, '
        'or another unavailable backend source.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Synchronisation impossible'),
            content: const Text(
              'Le lieu n a pas pu etre enregistre dans Supabase pour le moment.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lieu enregistre.')));
    await _refreshNearbyPlaces(force: true);
  }

  List<NearbyPlace> _rankPlaces(
    CheckinRecord? record, {
    required List<NearbyPlace> googlePlaces,
    List<NearbyPlace> userPlaces = const <NearbyPlace>[],
    PersonalizationProfile? personalizationProfile,
  }) {
    return RecommendationService.instance.mergeAndRankPlaces(
      googlePlaces: googlePlaces,
      userPlaces: userPlaces,
      currentEmotion: record?.currentEmotion,
      desiredEmotion: record?.desiredEmotion,
      activity: record?.activity,
      personalizationProfile: personalizationProfile ?? _personalizationProfile,
    );
  }

  NearbyPlace? _resolveTopRecommendedPlace(List<NearbyPlace> places) {
    return RecommendationService.instance.topRecommendedPlace(places: places);
  }

  Future<void> _openDirectionsForPlace(NearbyPlace place) async {
    final latitude = place.latitude;
    final longitude = place.longitude;
    if (latitude == null || longitude == null) {
      debugPrint(
        'HomePage: selected place "${place.name}" has no coordinates. '
        'Google Maps launch skipped.',
      );
      return;
    }

    debugPrint(
      'HomePage: selected place "${place.name}". '
      'Opening Google Maps with coordinates $latitude,$longitude.',
    );

    final launched = await GoogleMapsLauncher.openPlace(
      latitude: latitude,
      longitude: longitude,
    );
    if (launched || !mounted) {
      return;
    }

    debugPrint(
      'HomePage: Google Maps launch failed for "${place.name}" '
      'with coordinates $latitude,$longitude.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible d ouvrir l itineraire pour ce lieu.'),
      ),
    );
  }

  Future<void> _savePlaceSelection({
    required NearbyPlace place,
    CheckinPlaceStatus? status,
    String? note,
  }) async {
    final todayRecord = _store.todayRecord;
    if (todayRecord == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Valide d abord ton check-in du jour pour enrichir ce moment.',
          ),
        ),
      );
      return;
    }

    try {
      final updatedRecord = await _checkinService.updateTodayJournalContext(
        selectedPlaceName: place.name,
        selectedPlaceStatus: status,
        writtenNote: note,
      );
      _store.applyPersistedRecord(updatedRecord);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_placeActionMessage(place, status, note))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d enregistrer ce moment pour le moment.'),
        ),
      );
    }
  }

  Future<void> _promptForPlaceNote(NearbyPlace place) async {
    final note = await showPlaceNoteDialog(
      context,
      title: 'Ajouter une note pour ce lieu',
    );
    if (note == null || note.trim().isEmpty) {
      return;
    }

    await _savePlaceSelection(place: place, note: note);
  }

  String _placeActionMessage(
    NearbyPlace place,
    CheckinPlaceStatus? status,
    String? note,
  ) {
    if (note != null && note.trim().isNotEmpty) {
      return 'Ta note a ete ajoutee a ${place.name}.';
    }

    switch (status) {
      case CheckinPlaceStatus.favorite:
        return '${place.name} a ete ajoute en favori.';
      case CheckinPlaceStatus.later:
        return '${place.name} est garde pour plus tard.';
      case CheckinPlaceStatus.visited:
        return '${place.name} est marque comme visite.';
      case null:
        return 'Ton moment a ete mis a jour.';
    }
  }

  String _recommendationKey(CheckinRecord? record) {
    return <String>[
      record?.currentEmotion ?? '',
      record?.desiredEmotion ?? '',
      record?.activity ?? '',
    ].join('|');
  }

  CheckInSummary _buildSummary(CheckinRecord? currentRecord) {
    return CheckInSummary(
      completedToday: currentRecord?.completionLevel ?? 0,
      totalToday: 4,
      weeklyCheckIns: _store.weeklyCompletedCount,
      note: 'Check-in',
      emoji: CheckinMappings.emojiForEmotion(currentRecord?.currentEmotion),
      dateBadge: _formatHeaderDate(DateTime.now()),
    );
  }

  List<MoodEntry> _buildMoodEntries(List<CheckinRecord> records) {
    return records.map((CheckinRecord record) {
      return MoodEntry(
        label: _formatChartLabel(record.date),
        completionLevel: record.completionLevel,
        color: CheckinMappings.colorForEmotion(record.currentEmotion),
        emoji: record.completionLevel == 0
            ? null
            : CheckinMappings.emojiForEmotion(record.currentEmotion),
      );
    }).toList();
  }

  LastCheckInSnapshot _buildLastCheckIn(CheckinRecord? record) {
    if (record == null) {
      return const LastCheckInSnapshot(
        title: 'Pas encore de check-in',
        description: 'Ton ressenti du jour apparaitra ici.',
        emoji: '\u{1F642}',
        accentColor: AppColors.primaryOrange,
      );
    }

    return LastCheckInSnapshot(
      title: CheckinMappings.labelForEmotion(record.currentEmotion),
      description: CheckinMappings.associatedText(
        currentEmotion: record.currentEmotion,
        reasons: record.reasons,
        desiredEmotion: record.desiredEmotion,
      ),
      emoji: CheckinMappings.emojiForEmotion(record.currentEmotion),
      accentColor: CheckinMappings.colorForEmotion(record.currentEmotion),
    );
  }

  List<WeekDayStatus> _buildWeekDays(LocalCheckinStore store) {
    final now = DateTime.now();
    final records = store.recentChartRecords;

    return List<WeekDayStatus>.generate(7, (int index) {
      final date = now.subtract(Duration(days: 6 - index));
      CheckinRecord? recordForDay;

      for (final record in records) {
        if (_isSameDay(record.date, date)) {
          recordForDay = record;
          break;
        }
      }

      return WeekDayStatus(
        label: _weekdayLabels[date.weekday - 1],
        dayNumber: date.day,
        isSelected: _isSameDay(date, now),
        marker: recordForDay == null
            ? null
            : CheckinMappings.emojiForEmotion(recordForDay.currentEmotion),
      );
    });
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  bool _hasRecentCheckin(CheckinRecord? record) {
    if (record == null) {
      return false;
    }

    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedRecord = DateTime(
      record.date.year,
      record.date.month,
      record.date.day,
    );

    final age = normalizedNow.difference(normalizedRecord);
    return !age.isNegative && age <= _recentCheckinMaxAge;
  }

  String _formatHeaderDate(DateTime date) {
    return '${_headerWeekdays[date.weekday - 1]}, ${date.day} ${_headerMonths[date.month - 1]}';
  }

  String _formatChartLabel(DateTime date) {
    return '${date.day}/${date.month}';
  }

  static const List<String> _weekdayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _headerWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _headerMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _MomentSuggestionCard extends StatelessWidget {
  const _MomentSuggestionCard({
    required this.place,
    required this.onDirectionsPressed,
    this.onViewMoreOptionsPressed,
    required this.onFavoritePressed,
    required this.onLaterPressed,
    required this.onVisitedPressed,
    required this.onNotePressed,
  });

  final NearbyPlace place;
  final VoidCallback onDirectionsPressed;
  final VoidCallback? onViewMoreOptionsPressed;
  final VoidCallback onFavoritePressed;
  final VoidCallback onLaterPressed;
  final VoidCallback onVisitedPressed;
  final VoidCallback onNotePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDirections = place.latitude != null && place.longitude != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(place.icon, color: AppColors.ink, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                place.distance,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (place.recommendationReason != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              place.recommendationReason!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasDirections ? onDirectionsPressed : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.softBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Itineraire'),
            ),
          ),
          if (onViewMoreOptionsPressed != null) ...<Widget>[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onViewMoreOptionsPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mutedInk,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Voir d'autres options",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          PlaceJournalActions(
            onFavoritePressed: onFavoritePressed,
            onLaterPressed: onLaterPressed,
            onVisitedPressed: onVisitedPressed,
            onNotePressed: onNotePressed,
          ),
        ],
      ),
    );
  }
}

class _QuickIdeaCard extends StatelessWidget {
  const _QuickIdeaCard({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'On peut te guider vers quelques options simples autour de toi.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.softBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Trouver une idee'),
            ),
          ),
        ],
      ),
    );
  }
}
