import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:honvie/features/auth/presentation/auth_page.dart';
import 'package:honvie/core/supabase_client.dart';
import 'package:honvie/features/profile/data/profile_service.dart';
import 'package:honvie/features/community/data/community_service.dart';
import 'package:honvie/features/community/presentation/community_page.dart';
import 'package:honvie/features/profile/pages/daily_mood_page.dart';
import 'package:honvie/features/profile/pages/challenges_page.dart';
import 'package:honvie/features/profile/pages/visited_places_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = const ProfileService();
  final CommunityService _communityService = const CommunityService();
  late final List<QuickAction> _quickActions;
  static const BoxDecoration _backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF6FE),
        Color(0xFFF5EEFF),
      ],
    ),
  );

  bool _isLoading = true;
  int _streakDays = 0;
  int _completedChallenges = 0;
  List<Map<String, dynamic>> _recentMoods = [];
  List<Map<String, dynamic>> _recentPosts = [];
  String? _errorMessage;
  bool _isLoadingRecentPosts = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );
    _quickActions = [
      QuickAction(
        icon: Icons.edit_outlined,
        label: 'Ajouter une histoire',
        onTap: () => _openCreatePost(context),
      ),
      QuickAction(
        icon: Icons.mood_outlined,
        label: 'Mon humeur du jour',
        onTap: () => _openDailyMood(context),
      ),
      QuickAction(
        icon: Icons.flag_outlined,
        label: 'Voir mes défis',
        onTap: () => _openChallenges(context),
      ),
      QuickAction(
        icon: Icons.place_outlined,
        label: 'Lieux visités',
        onTap: () => _openPlaces(context),
      ),
    ];
    _loadProfileData();
    _loadRecentPosts();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void runEntranceAnimation() {
    _animController.forward(from: 0);
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final streak = await _profileService.getConsecutiveDays();
      final completed = await _profileService.getCompletedChallengesCount();
      final moods = await _profileService.getRecentMoods(days: 7);

      if (!mounted) return;
      setState(() {
        _streakDays = streak;
        _completedChallenges = completed;
        _recentMoods = moods;
        _isLoading = false;
      });
      if (!mounted) return;
      _animController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger le profil.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentPosts() async {
    setState(() {
      _isLoadingRecentPosts = true;
    });

    try {
      final posts = await _communityService.getUserLatestPosts(limit: 3);
      if (!mounted) return;
      setState(() {
        _recentPosts = posts;
        _isLoadingRecentPosts = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Error loading recent posts: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _recentPosts = [];
        _isLoadingRecentPosts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('Profil'),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _loadProfileData,
        ),
      ],
    );

    if (_isLoading) {
      return Container(
        decoration: _backgroundDecoration,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        decoration: _backgroundDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadProfileData,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: _backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: _buildProfileBody(),
      ),
    );
  }

  Widget _buildProfileBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildMoodSection(),
                  const SizedBox(height: 24),
                  _buildRecentPostsSection(context),
                  const SizedBox(height: 16),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildProfileHeader() {
    const borderRadius = BorderRadius.all(Radius.circular(24));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD1F3),
                  Color(0xFFFDEBFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: borderRadius,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: 0.25),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Utilisateur Solo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Membre HonVie',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🔥 $_streakDays jour(s) · 🎯 $_completedChallenges défi(s) relevé(s)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Votre progression',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jours consécutifs',
                _streakDays.toString(),
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Défis relevés',
                _completedChallenges.toString(),
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Lieux visités',
                '0',
                icon: Icons.place_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suivi émotionnel (7 derniers jours)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vos émotions récentes',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentMoods.isEmpty)
          const Text(
            'Aucune humeur enregistrée pour le moment.',
            style: TextStyle(fontSize: 14),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentMoods.map((mood) {
              final dateStr = mood['date'] as String;
              final moodType = mood['mood_type'] as String;
              final parsedDate = DateTime.tryParse(dateStr);
              final formatted = parsedDate != null
                  ? '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}'
                  : dateStr;
              return _buildMoodChip(moodType, formatted);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMoodChip(String moodType, String dateLabel) {
    final lower = moodType.toLowerCase();
    Color background;
    switch (lower) {
      case 'joyeux':
        background = Colors.yellow.withValues(alpha: 0.15);
        break;
      case 'serein':
        background = Colors.blue.withValues(alpha: 0.15);
        break;
      case 'triste':
        background = Colors.blueGrey.withValues(alpha: 0.15);
        break;
      case 'stressé':
      case 'stresse':
        background = Colors.red.withValues(alpha: 0.15);
        break;
      case 'reconnaissant':
        background = Colors.green.withValues(alpha: 0.15);
        break;
      default:
        background = Colors.white;
    }

    final emoji = _emojiForMood(moodType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $moodType',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _emojiForMood(String moodType) {
    switch (moodType.toLowerCase()) {
      case 'joyeux':
        return '😀';
      case 'serein':
        return '🙂';
      case 'triste':
        return '😢';
      case 'stressé':
      case 'stresse':
        return '😥';
      case 'reconnaissant':
        return '🙏';
      default:
        return '🌀';
    }
  }

  Widget _buildQuickActionsSection() {
    if (_quickActions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickActions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _QuickActionChip(action: action),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPostsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Mes dernières histoires',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoadingRecentPosts
                ? const Center(child: CircularProgressIndicator())
                : _recentPosts.isEmpty
                    ? const Text(
                        "Aucune histoire encore 🎈\nCommencez à partager vos moments pour les voir ici.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < _recentPosts.length; i++) ...[
                            _buildRecentPostItem(_recentPosts[i]),
                            if (i != _recentPosts.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                          ],
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPostItem(Map<String, dynamic> post) {
    final title = (post['title'] as String?) ?? 'Histoire sans titre';
    final content = (post['content'] as String?) ?? '';
    final mood = (post['mood_tag'] as String?) ?? 'Humeur';
    final createdAt = post['created_at']?.toString();
    final formattedDate = _formatDate(createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                mood,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  void _openCreatePost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityPage()),
    );
  }

  void _openDailyMood(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DailyMoodPage()),
    );
  }

  void _openChallenges(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChallengesPage()),
    );
  }

  void _openPlaces(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VisitedPlacesPage()),
    );
  }

  Widget _buildStatCard(String label, String value, {IconData? icon}) {
    Color? iconColor;
    if (icon == Icons.calendar_today) {
      iconColor = Colors.pinkAccent;
    } else if (icon == Icons.check_circle_outline) {
      iconColor = Colors.green;
    } else if (icon == Icons.place_outlined) {
      iconColor = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 18,
              color: iconColor ?? Colors.pinkAccent,
            ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.pinkAccent),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(
            color: Colors.pinkAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion.')),
      );
    }
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _QuickActionChip extends StatelessWidget {
  final QuickAction action;

  const _QuickActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                size: 18,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
