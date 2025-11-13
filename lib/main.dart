import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_client.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/home/presentation/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const HonVieApp());
}

class HonVieApp extends StatelessWidget {
  const HonVieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HonVie',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = supabase.auth.currentSession;
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _session = data.session;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const AuthPage();
    } else {
      return const HomePage();
    }
  }
}
