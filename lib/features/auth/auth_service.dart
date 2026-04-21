import 'package:supabase_flutter/supabase_flutter.dart';

class AuthUserProfile {
  const AuthUserProfile({
    required this.email,
    required this.displayName,
    required this.avatarFallbackLabel,
    this.firstName,
    this.avatarUrl,
  });

  final String email;
  final String displayName;
  final String avatarFallbackLabel;
  final String? firstName;
  final String? avatarUrl;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      return null;
    }

    return user;
  }

  AuthUserProfile? get currentUserProfile {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email ?? '';
    final rawFirstName = _readMetadataString(metadata, const <String>[
      'first_name',
      'firstName',
      'given_name',
      'givenName',
    ]);
    final rawDisplayName = _readMetadataString(metadata, const <String>[
      'full_name',
      'fullName',
      'display_name',
      'displayName',
      'name',
    ]);
    final avatarUrl = _readMetadataString(metadata, const <String>[
      'avatar_url',
      'avatarUrl',
      'picture',
    ]);
    final resolvedFirstName =
        _extractFirstWord(rawFirstName) ?? _extractFirstWord(rawDisplayName);
    final resolvedDisplayName =
        resolvedFirstName ??
        rawDisplayName ??
        _formatEmailLocalPart(email) ??
        'Profil Honvie';

    return AuthUserProfile(
      email: email,
      displayName: resolvedDisplayName,
      avatarFallbackLabel: _resolveInitial(
        resolvedFirstName ?? resolvedDisplayName,
      ),
      firstName: resolvedFirstName,
      avatarUrl: avatarUrl,
    );
  }

  Session? get currentSession {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (session == null || user == null || user.isAnonymous) {
      return null;
    }

    return session;
  }

  Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> clearAnonymousSessionIfNeeded() async {
    final user = _client.auth.currentUser;
    if (user == null || !user.isAnonymous) {
      return;
    }

    await _client.auth.signOut();
  }

  String? _readMetadataString(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    for (final key in keys) {
      final rawValue = metadata[key];
      if (rawValue is String) {
        final trimmedValue = rawValue.trim();
        if (trimmedValue.isNotEmpty) {
          return trimmedValue;
        }
      }
    }

    return null;
  }

  String? _extractFirstWord(String? value) {
    if (value == null) {
      return null;
    }

    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    return trimmedValue.split(RegExp(r'\s+')).first;
  }

  String? _formatEmailLocalPart(String email) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return null;
    }

    final localPart = trimmedEmail.split('@').first.trim();
    if (localPart.isEmpty) {
      return null;
    }

    final normalized = localPart.replaceAll(RegExp(r'[._-]+'), ' ');
    final words = normalized
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return null;
    }

    final firstWord = words.first;
    return '${firstWord[0].toUpperCase()}${firstWord.substring(1).toLowerCase()}';
  }

  String _resolveInitial(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return 'H';
    }

    return trimmedValue.substring(0, 1).toUpperCase();
  }
}
