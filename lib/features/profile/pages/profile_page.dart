import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/auth_service.dart';
import '../widgets/profile_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = AuthService.instance.currentUserProfile;
    final displayName = profile?.displayName ?? 'Profil Honvie';
    final email = profile?.email ?? 'Compte Honvie';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.ivory, AppColors.blush, AppColors.mist],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 12),
                      Text('Profil', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 18),
                      Center(
                        child: Column(
                          children: <Widget>[
                            ProfileAvatar(
                              fallbackLabel:
                                  profile?.avatarFallbackLabel ?? 'H',
                              imageUrl: profile?.avatarUrl,
                              size: 76,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.mutedInk,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ton compte est connecte avec :',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _handleSignOut(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: AppColors.softBlack,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Se deconnecter'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await AuthService.instance.signOut();
      if (!context.mounted) {
        return;
      }

      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } on AuthException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deconnexion impossible pour le moment.')),
      );
    }
  }
}
