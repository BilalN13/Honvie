import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../journal/constants/checkin_mappings.dart';
import '../../places/place_metadata.dart';
import '../data/stats_service.dart';
import '../models/stats_summary.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final StatsService _statsService = StatsService.instance;
  late Future<StatsSummary> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _statsService.fetchStatsSummary();
  }

  Future<void> _refresh() async {
    final future = _statsService.fetchStatsSummary();
    setState(() {
      _statsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<StatsSummary>(
        future: _statsFuture,
        builder: (BuildContext context, AsyncSnapshot<StatsSummary> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _StatsFeedback(
              title: 'Statistiques indisponibles',
              subtitle:
                  'Les tendances ne peuvent pas etre calculees pour le moment.',
            );
          }

          final summary = snapshot.data ?? StatsSummary.empty;
          if (summary.totalCheckins == 0) {
            return const _StatsFeedback(
              title: 'Pas encore de donnees',
              subtitle:
                  'Ta progression apparaitra ici apres tes premiers check-ins valides.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 126),
              children: <Widget>[
                const _StatsHeader(),
                const SizedBox(height: 16),
                const _StatsSectionHeader(
                  title: 'Vue rapide',
                  subtitle: 'Tes reperes essentiels en un coup d oeil.',
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatsCard(
                        title: 'Total check-ins',
                        value: '${summary.totalCheckins}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatsCard(
                        title: 'Cette semaine',
                        value: '${summary.weeklyCheckins}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatsCard(
                        title: 'Serie actuelle',
                        value: '${summary.streak} jours d affilee',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatsCard(
                        title: 'Completion moyenne',
                        value:
                            '${summary.averageCompletionLevel.toStringAsFixed(1)}/4',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatsCard(
                        title: 'Moyenne recente',
                        value: '${summary.last7DaysAvg.toStringAsFixed(1)}/4',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatsCard(
                        title: 'Tendance',
                        value: _trendLabel(summary.trend),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _StatsSectionHeader(
                  title: 'Tendances personnelles',
                  subtitle:
                      'Ce que tu ressens, ce que tu recherches et ce qui revient.',
                ),
                const SizedBox(height: 10),
                _StatsCard(
                  title: 'Emotion actuelle la plus frequente',
                  value: CheckinMappings.labelForEmotion(
                    summary.mostFrequentCurrentEmotion,
                  ),
                ),
                const SizedBox(height: 10),
                _StatsCard(
                  title: 'Emotion recherchee la plus frequente',
                  value: CheckinMappings.labelForDesiredEmotion(
                    summary.mostFrequentDesiredEmotion,
                  ),
                ),
                const SizedBox(height: 10),
                _StatsCard(
                  title: 'Activite la plus frequente',
                  value:
                      summary.mostFrequentActivity ??
                      'Pas encore assez de recul',
                ),
                const SizedBox(height: 10),
                _StatsCard(
                  title: 'Type de lieu le plus present',
                  value: summary.mostFrequentPlaceType == null
                      ? 'Pas encore assez de recul'
                      : PlaceMetadata.labelForType(
                          summary.mostFrequentPlaceType!,
                        ),
                ),
                const SizedBox(height: 18),
                const _StatsSectionHeader(
                  title: 'Insights',
                  subtitle:
                      'Quelques phrases simples pour lire ta progression.',
                ),
                const SizedBox(height: 10),
                if (summary.insights.isEmpty)
                  const _StatsInsightCard(
                    message:
                        'Tes insights apparaitront ici des que quelques habitudes se dessineront.',
                  )
                else
                  Column(
                    children: List<Widget>.generate(summary.insights.length, (
                      int index,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == summary.insights.length - 1 ? 0 : 10,
                        ),
                        child: _StatsInsightCard(
                          message: summary.insights[index],
                        ),
                      );
                    }),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _trendLabel(String trend) {
    switch (trend) {
      case 'up':
        return 'En hausse';
      case 'down':
        return 'En baisse';
      default:
        return 'Stable';
    }
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Statistiques', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Ta progression personnelle et les reperes qui reviennent souvent.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _StatsSectionHeader extends StatelessWidget {
  const _StatsSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _StatsInsightCard extends StatelessWidget {
  const _StatsInsightCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.ink, height: 1.35),
      ),
    );
  }
}

class _StatsFeedback extends StatelessWidget {
  const _StatsFeedback({required this.title, required this.subtitle});

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
