class UserPlaceDraft {
  const UserPlaceDraft({
    required this.name,
    required this.type,
    required this.moodTags,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String type;
  final List<String> moodTags;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toSupabaseInsert({required String userId}) {
    return <String, dynamic>{
      'user_id': userId,
      'name': name,
      'type': type,
      'mood_tags': moodTags,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class UserPlace {
  const UserPlace({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.moodTags,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String type;
  final List<String> moodTags;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  factory UserPlace.fromSupabase(Map<String, dynamic> map) {
    return UserPlace(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      moodTags: (map['mood_tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic tag) => tag.toString())
          .toList(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PublicUserPlace {
  const PublicUserPlace({
    required this.name,
    required this.type,
    required this.moodTags,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String name;
  final String type;
  final List<String> moodTags;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  factory PublicUserPlace.fromSupabase(Map<String, dynamic> map) {
    return PublicUserPlace(
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      moodTags: (map['mood_tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic tag) => tag.toString())
          .toList(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

abstract final class UserPlaceOptions {
  static const List<String> moodTags = <String>[
    'pose',
    'social',
    'creatif',
    'curieux',
    'motive',
    'introspectif',
  ];

  static String labelForMood(String moodTag) {
    switch (moodTag) {
      case 'pose':
        return 'Pose';
      case 'social':
        return 'Social';
      case 'creatif':
        return 'Creatif';
      case 'curieux':
        return 'Curieux';
      case 'motive':
        return 'Motive';
      case 'introspectif':
        return 'Introspectif';
      default:
        return moodTag;
    }
  }
}
