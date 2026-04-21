import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../journal/controllers/local_checkin_store.dart';
import '../data/history_service.dart';
import '../models/history_item.dart';
import 'history_moment_detail_page.dart';
import '../widgets/history_moment_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService.instance;
  final LocalCheckinStore _store = LocalCheckinStore.instance;
  late Future<List<HistoryItem>> _historyFuture;
  int _lastPersistedRevision = 0;

  @override
  void initState() {
    super.initState();
    _lastPersistedRevision = _store.persistedRevision;
    _store.addListener(_handleStoreChanged);
    _historyFuture = _historyService.fetchCheckinHistory();
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _historyService.fetchCheckinHistory();
    setState(() {
      _historyFuture = future;
    });
    await future;
  }

  void _handleStoreChanged() {
    final nextRevision = _store.persistedRevision;
    if (nextRevision == _lastPersistedRevision) {
      return;
    }

    _lastPersistedRevision = nextRevision;
    _refresh();
  }

  void _openHistoryDetail(HistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryMomentDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<HistoryItem>>(
        future: _historyFuture,
        builder: (BuildContext context, AsyncSnapshot<List<HistoryItem>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HistoryFeedback(
              title: 'Historique indisponible',
              subtitle:
                  'Les check-ins passes ne peuvent pas etre charges pour le moment.',
            );
          }

          final items = snapshot.data ?? const <HistoryItem>[];
          if (items.isEmpty) {
            return const _HistoryFeedback(
              title: 'Aucun check-in pour le moment',
              subtitle:
                  'Ton historique apparaitra ici des que tu auras valide quelques check-ins.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 126),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return const _HistoryHeader();
                }

                final item = items[index - 1];
                return HistoryMomentCard(
                  item: item,
                  onTap: () => _openHistoryDetail(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Historique', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Retrouve ici le fil de tes moments, emotions et sorties.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HistoryFeedback extends StatelessWidget {
  const _HistoryFeedback({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
