import 'package:flutter/material.dart';

import 'package:honvie/features/home/presentation/home_page.dart';
import 'package:honvie/features/map/presentation/map_page.dart';
import 'package:honvie/features/inspiration/presentation/inspiration_page.dart';
import 'package:honvie/features/community/presentation/explore_page.dart';
import 'package:honvie/features/community/presentation/community_page.dart';
import 'package:honvie/features/profile/presentation/profile_page.dart';

/// Scaffold racine avec navigation basique pour HonVie.
class HonvieScaffold extends StatefulWidget {
  const HonvieScaffold({super.key});

  @override
  State<HonvieScaffold> createState() => _HonvieScaffoldState();
}

class _HonvieScaffoldState extends State<HonvieScaffold> {
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();
  final GlobalKey<InspirationPageState> _inspirationKey =
      GlobalKey<InspirationPageState>();

  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const MapPage(),
    InspirationPage(key: _inspirationKey),
    const ExplorePage(),
    const CommunityPage(),
    ProfilePage(key: _profileKey),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FF),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7FF),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFFF4FA3),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Carte',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star_border),
                label: 'Inspiration',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                label: 'Explorer',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: 'Comm.',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      _inspirationKey.currentState?.runEntranceAnimation();
    } else if (index == 5) {
      _profileKey.currentState?.runEntranceAnimation();
    }
  }
}
