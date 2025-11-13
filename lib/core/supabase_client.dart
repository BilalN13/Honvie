import 'package:supabase_flutter/supabase_flutter.dart';

// Valeurs issues de votre projet Supabase (ici codées en dur pour simplifier le déploiement web).
const String supabaseUrl = 'https://codonhmhomfqapeushae.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZG9uaG1ob21mcWFwZXVzaGFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5ODAyNDUsImV4cCI6MjA3ODU1NjI0NX0.JcnvYeCJV46fb0Uj6XLQB_zEDhZQRnhtDsqb2VdmLOk';

/// Prépare Supabase sans dépendre d'un fichier .env (utile pour Flutter web).
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

/// Client Supabase partagé par l'application.
SupabaseClient get supabase => Supabase.instance.client;
