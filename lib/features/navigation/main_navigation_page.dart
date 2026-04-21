import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_bottom_navigation_bar.dart';
import '../explore/models/explore_navigation_models.dart';
import '../journal/controllers/local_checkin_store.dart';
import '../explore/pages/explore_page.dart';
import '../history/pages/history_page.dart';
import '../home/pages/home_page.dart';
import '../journal/pages/journal_page.dart';
import '../stats/pages/stats_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final LocalCheckinStore _checkinStore = LocalCheckinStore.instance;
  final ValueNotifier<ExploreViewRequest?> _exploreRequestNotifier =
      ValueNotifier<ExploreViewRequest?>(null);
  int _nextExploreRequestId = 0;

  @override
  void initState() {
    super.initState();
    _checkinStore.ensureRemoteHydrated();
  }

  @override
  void dispose() {
    _exploreRequestNotifier.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index < 0 || index >= _pages.length) {
      debugPrint(
        'MainNavigationPage: ignored invalid navigation index=$index, '
        'children.length=${_pages.length}',
      );
      return;
    }

    debugPrint(
      'MainNavigationPage: switching to currentIndex=$index, '
      'children.length=${_pages.length}',
    );
    setState(() {
      _currentIndex = index;
    });
  }

  void _openExploreForMe() {
    _nextExploreRequestId += 1;
    _exploreRequestNotifier.value = ExploreViewRequest(
      filter: ExploreFilterType.forMe,
      requestId: _nextExploreRequestId,
    );

    if (_currentIndex == 1) {
      return;
    }

    setState(() {
      _currentIndex = 1;
    });
  }

  Future<void> _openJournalFlow() async {
    await _checkinStore.ensureRemoteHydrated();

    if (!mounted) {
      return;
    }

    final shouldReturnHome = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Journal Check-in',
      barrierDismissible: false,
      barrierColor: AppColors.softBlack.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (BuildContext context, _, __) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 24, 10, 96),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Material(
                    color: AppColors.white,
                    child: const JournalPage(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
    );

    if (shouldReturnHome == true && mounted) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  List<Widget> get _pages => <Widget>[
    HomePage(onViewMoreOptionsPressed: _openExploreForMe),
    ExplorePage(requestListenable: _exploreRequestNotifier),
    const HistoryPage(),
    const StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    debugPrint(
      'MainNavigationPage: build currentIndex=$_currentIndex, '
      'children.length=${pages.length}',
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.ivory, AppColors.blush, AppColors.mist],
          ),
        ),
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: HonvieBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onDestinationSelected,
        onCenterTap: _openJournalFlow,
      ),
    );
  }
}
