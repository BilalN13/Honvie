import 'package:flutter/material.dart';
import 'package:honvie/features/home/data/challenge_service.dart';
import 'package:honvie/features/home/data/mood_service.dart';

/// Modèle simple pour représenter une humeur proposée.
class Mood {
  const Mood({
    required this.label,
    required this.emoji,
    required this.color,
  });

  final String label;
  final String emoji;
  final Color color;
}

/// Modèle simple pour les lieux recommandés autour de l'utilisateur.
class Place {
  const Place({
    required this.name,
    required this.description,
    required this.rating,
    required this.icon,
  });

  final String name;
  final String description;
  final double rating;
  final IconData icon;
}

const _moods = <Mood>[
  Mood(label: 'Joyeux', emoji: '😀', color: Color(0xFFFFF1B5)),
  Mood(label: 'Serein', emoji: '🙂', color: Color(0xFFC4F5FF)),
  Mood(label: 'Triste', emoji: '😢', color: Color(0xFFE2E2FF)),
  Mood(label: 'Stressé', emoji: '😰', color: Color(0xFFFFD7D7)),
  Mood(label: 'Reconnaissant', emoji: '🙏', color: Color(0xFFD7FFE3)),
];

const _places = <Place>[
  Place(
    name: 'Café Lumière',
    description: 'Salon cosy pour se détendre',
    rating: 4.8,
    icon: Icons.coffee,
  ),
  Place(
    name: 'Parc Horizon',
    description: 'Balade zen au coucher du soleil',
    rating: 4.6,
    icon: Icons.park,
  ),
  Place(
    name: 'Studio Respire',
    description: 'Yoga & méditation guidée',
    rating: 4.7,
    icon: Icons.self_improvement,
  ),
];

/// Écran d'accueil HonVie.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MoodService _moodService = const MoodService();
  final ChallengeService _challengeService = const ChallengeService();

  String? _selectedMood;
  Map<String, dynamic>? _todayChallenge;
  bool _completed = false;
  bool _isLoadingChallenge = true;
  String? _challengeError;

  @override
  void initState() {
    super.initState();
    _loadMood();
    _loadDailyChallenge();
    _loadCompletion();
  }

  Future<void> _loadMood() async {
    try {
      final storedMood = await _moodService.getMoodForToday();
      if (!mounted) return;
      setState(() => _selectedMood = storedMood);
    } catch (_) {
      // Ignoré pour garder l'UI fluide en cas d'erreur ponctuelle.
    }
  }

  Future<void> _loadDailyChallenge() async {
    setState(() {
      _isLoadingChallenge = true;
      _challengeError = null;
    });

    try {
      var challenge = await _challengeService.getTodayChallenge();
      if (challenge == null) {
        await _challengeService.setTodayChallenge({
          'title': 'Méditation de 10 minutes',
          'description':
              'Prenez un moment pour respirer profondément et recentrer votre esprit.',
          'duration_minutes': 10,
          'category': 'Méditation',
          'difficulty': 'facile',
        });
        challenge = await _challengeService.getTodayChallenge();
      }

      if (!mounted) return;
      setState(() {
        _todayChallenge = challenge;
      });
    } catch (e, s) {
      // ignore: avoid_print
      print('Error loading daily challenge: $e\\n$s');

      if (mounted) {
        setState(() {
          _challengeError = "Impossible de charger le défi du jour.";
          _todayChallenge = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChallenge = false;
        });
      }
    }
  }

  Future<void> _loadCompletion() async {
    try {
      final completed = await _challengeService.hasUserCompletedToday();
      if (!mounted) return;
      setState(() => _completed = completed);
    } catch (_) {
      // On ignore volontairement les erreurs ponctuelles de récupération.
    }
  }

  Future<void> _onMoodSelected(String moodType) async {
    try {
      await _moodService.saveMoodForToday(moodType);
      if (!mounted) return;
      setState(() => _selectedMood = moodType);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Humeur enregistrée pour aujourd\'hui')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'enregistrer votre humeur.')),
      );
    }
  }

  Future<void> _onChallengePressed() async {
    if (_completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déjà complété aujourd\'hui')),
      );
      return;
    }

    try {
      await _challengeService.completeChallenge();
      if (!mounted) return;
      setState(() => _completed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Défi relevé !')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de valider le défi.')),
      );
    }
  }


  Widget _buildDailyChallengeSection() {
    if (_isLoadingChallenge) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_challengeError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Text(
          _challengeError!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (_todayChallenge == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Text("Pas de défi programmé pour aujourd'hui."),
      );
    }

    return _DailyChallengeSection(
      challenge: _todayChallenge!,
      completed: _completed,
      onPressed: _onChallengePressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 24),
              _MoodSection(
                selectedMood: _selectedMood,
                onMoodSelected: _onMoodSelected,
              ),
              const SizedBox(height: 32),
              _buildDailyChallengeSection(),
              const SizedBox(height: 32),
              const _PlacesSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD1F3), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.pinkAccent),
          ),
          const SizedBox(width: 12),
          const Text(
            'HonVie',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Profil'),
          ),
        ],
      ),
    );
  }
}

class _MoodSection extends StatelessWidget {
  const _MoodSection({
    required this.selectedMood,
    required this.onMoodSelected,
  });

  final String? selectedMood;
  final ValueChanged<String> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comment vous sentez-vous aujourd\'hui ?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _moods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final mood = _moods[index];
              final isSelected = mood.label == selectedMood;
              return _buildMoodCard(
                mood: mood,
                isSelected: isSelected,
                onTap: () => onMoodSelected(mood.label),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodCard({
    required Mood mood,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        height: 120,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: mood.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? Colors.pinkAccent : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                mood.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  mood.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyChallengeSection extends StatelessWidget {
  const _DailyChallengeSection({
    required this.challenge,
    required this.completed,
    required this.onPressed,
  });

  final Map<String, dynamic> challenge;
  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final difficulty = (challenge['difficulty'] as String?) ?? 'facile';
    final title = (challenge['title'] as String?) ?? 'Défi du jour';
    final description = (challenge['description'] as String?) ??
        'Prenez un moment pour vous aujourd\'hui.';
    final duration = challenge['duration_minutes'];
    final category = (challenge['category'] as String?) ?? 'Méditation';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Défi du jour',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  difficulty,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Colors.black54),
              const SizedBox(width: 6),
              Text(duration != null ? '$duration min' : '10 min'),
              const SizedBox(width: 16),
              const Icon(Icons.self_improvement, size: 20, color: Colors.black54),
              const SizedBox(width: 6),
              Text(category),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: completed ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    completed ? Colors.grey.shade400 : const Color(0xFFFF7AC7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                completed ? 'Défi complété ✔' : 'Relever le défi',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacesSection extends StatelessWidget {
  const _PlacesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lieux à proximité',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final place = _places[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(place.icon, size: 28, color: Colors.pinkAccent),
                    const SizedBox(height: 12),
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.description,
                      style: const TextStyle(color: Colors.black54, height: 1.3),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(place.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
