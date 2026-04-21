import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nyunrttvscvlxetbiwan.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55dW5ydHR2c2N2bHhldGJpd2FuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MTQ1MzQsImV4cCI6MjA5MTQ5MDUzNH0.NCGOHVCsJrwJ1wE0TTtfJiMEsSa4dbY0u2HouTxrI0E',
  );

  await AuthService.instance.clearAnonymousSessionIfNeeded();

  runApp(const HonvieApp());
}

class HonvieApp extends StatelessWidget {
  const HonvieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Honvie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
