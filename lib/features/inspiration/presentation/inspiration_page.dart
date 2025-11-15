import 'package:flutter/material.dart';

import 'package:honvie/features/inspiration/data/inspiration_service.dart';

class InspirationPage extends StatefulWidget {
  const InspirationPage({super.key});

  @override
  State<InspirationPage> createState() => InspirationPageState();
}

class InspirationPageState extends State<InspirationPage>
    with SingleTickerProviderStateMixin {
  final InspirationService _service = const InspirationService();
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
  String? _errorMessage;
  Map<String, dynamic>? _quote;
  Map<String, dynamic>? _ritual;
  List<Map<String, dynamic>> _tips = [];
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

    _loadInspiration();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void runEntranceAnimation() {
    _animController.forward(from: 0);
  }

  Future<void> _loadInspiration() async {
    _animController.reset();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quote = await _service.getRandomQuote();
      final ritual = await _service.getRandomRitual();
      final tips = await _service.getTips();

      setState(() {
        _quote = quote;
        _ritual = ritual;
        _tips = tips;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() {
        _errorMessage = "Impossible de charger l'inspiration pour le moment.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('Inspiration'),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _loadInspiration,
        ),
      ],
    );

    if (_isLoading) {
      return Container(
        decoration: _backgroundDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: const Center(child: CircularProgressIndicator()),
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
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadInspiration,
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
        body: _buildContentBody(),
      ),
    );
  }

  Widget _buildContentBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuoteSection(),
              const SizedBox(height: 24),
              _buildRitualSection(),
              const SizedBox(height: 24),
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteSection() {
    if (_quote == null) {
      return const Text('Pas encore de citation disponible.');
    }

    final content = _quote?['content']?.toString() ?? '';
    final author = _quote?['author']?.toString() ?? 'Inconnu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8D9FF), Color(0xFFFDEBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Citation inspirante',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              author,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRitualSection() {
    if (_ritual == null) {
      return const Text('Aucun rituel disponible pour le moment.');
    }

    final title = _ritual?['title']?.toString() ?? 'Rituel du jour';
    final description = _ritual?['description']?.toString() ?? '';
    final duration = _ritual?['duration'];
    final difficulty = _ritual?['difficulty']?.toString();
    final category = _ritual?['category']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE7FFF6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rituel du jour',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (duration != null)
                _buildInfoChip(Icons.timer_outlined, '$duration min'),
              if (difficulty != null && difficulty.isNotEmpty)
                _buildInfoChip(Icons.leaderboard_outlined, difficulty),
              if (category != null && category.isNotEmpty)
                _buildInfoChip(Icons.category_outlined, category),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    if (_tips.isEmpty) {
      return const Text('Pas encore de conseils ajoutés.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conseils bien-être',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _tips.map((tip) {
            final title = tip['title']?.toString() ?? '';
            final description = tip['description']?.toString() ?? '';
            final tag = tip['tag']?.toString();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (tag != null && tag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.pinkAccent),
      backgroundColor: Colors.pinkAccent.withValues(alpha: 0.1),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
