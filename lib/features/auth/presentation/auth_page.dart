import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honvie/core/supabase_client.dart';
import 'package:honvie/features/auth/presentation/login_page.dart';
import 'package:honvie/features/auth/presentation/signup_page.dart';

/// Écran principal d'authentification HonVie.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isSigningIn = false;

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  /// Lance l'authentification Google via Supabase OAuth.
  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de vous connecter avec Google pour le moment.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Widget _buildAuthButton({
    required String label,
    required VoidCallback onPressed,
    Widget? leading,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          foregroundColor: Colors.grey.shade900,
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (leading != null) ...[
                    leading,
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC6F4E4), Color(0xFFFDE3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'HonVie',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "L'art de vivre en solo",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _WelcomeCard(),
                        const SizedBox(height: 48),
                        _buildAuthButton(
                          label: 'Se connecter avec Google',
                          onPressed: _signInWithGoogle,
                          isLoading: _isSigningIn,
                          leading: const Icon(Icons.g_mobiledata, size: 22),
                        ),
                        const SizedBox(height: 16),
                        _buildAuthButton(
                          label: 'Se connecter',
                          onPressed: _openLogin,
                          leading: const Icon(Icons.lock_open, size: 20),
                        ),
                        const SizedBox(height: 16),
                        _buildAuthButton(
                          label: 'Se connecter avec Facebook',
                          onPressed: () {},
                          leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                        ),
                        const SizedBox(height: 16),
                        _buildAuthButton(
                          label: 'Créer un compte',
                          onPressed: _openSignup,
                          leading: const Icon(Icons.mail_outline, size: 20),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          child: const Text('Citer un exemple d\'usage'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Bloc de bienvenue qui contextualise l'application.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Rejoignez une communauté bienveillante dédiée à l\'épanouissement en solo.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
