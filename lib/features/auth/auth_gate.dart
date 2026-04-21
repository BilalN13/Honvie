import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../journal/controllers/local_checkin_store.dart';
import '../navigation/main_navigation_page.dart';
import 'auth_page.dart';
import 'auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService.instance;
  final LocalCheckinStore _checkinStore = LocalCheckinStore.instance;

  StreamSubscription<AuthState>? _authSubscription;
  Session? _currentSession;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _currentSession = _authService.currentSession;
    _lastUserId = _currentSession?.user.id;

    if (_currentSession != null) {
      _checkinStore.ensureRemoteHydrated();
    }

    _authSubscription = _authService.authStateChanges().listen((
      AuthState state,
    ) {
      final nextSession = _normalizeSession(state.session);
      _handleSessionChanged(nextSession);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentSession = nextSession;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleSessionChanged(Session? nextSession) {
    final nextUserId = nextSession?.user.id;
    if (nextUserId == _lastUserId) {
      return;
    }

    _lastUserId = nextUserId;
    _checkinStore.resetForAuthChange();

    if (nextSession != null) {
      _checkinStore.ensureRemoteHydrated();
    }
  }

  Session? _normalizeSession(Session? session) {
    final user = session?.user;
    if (session == null || user == null || user.isAnonymous) {
      return null;
    }

    return session;
  }

  @override
  Widget build(BuildContext context) {
    final session = _currentSession;
    if (session == null) {
      return const AuthPage();
    }

    return MainNavigationPage(key: ValueKey<String>(session.user.id));
  }
}
