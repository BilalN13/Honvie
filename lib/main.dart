import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_client.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/root/honvie_scaffold.dart';

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
      routes: const {
        // TODO: Ajouter '/create_post' lorsque l'écran dédié sera disponible.
        // TODO: Ajouter '/daily_mood' lorsque l'écran de sélection d'humeur sera disponible.
        // TODO: Ajouter '/challenges' lorsque la page des défis sera créée.
        // TODO: Ajouter '/places' lorsque la page des lieux visités sera disponible.
      },
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
      return const HonvieScaffold();
    }
  }
}
