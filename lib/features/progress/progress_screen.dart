import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/watch_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/swim_session.dart';
import 'widgets/stats_summary.dart';
import 'widgets/swolf_chart.dart';
import 'widgets/volume_chart.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _swolfDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: sessionsAsync.when(
          data: (sessions) => CustomScrollView(
            slivers: [
              // ── AppBar + tabs ─────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.backgroundLight,
                elevation: 0,
                title: const Text(
                  'Progression',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Technique'),
                    Tab(text: 'Volume'),
                  ],
                ),
              ),

              // ── Contenu onglets ───────────────────────────────────────
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet Technique : SWOLF + stats
                    _TechniqueTab(
                      sessions: sessions,
                      days: _swolfDays,
                      onDaysChanged: (d) => setState(() => _swolfDays = d),
                    ),
                    // Onglet Volume : histogramme
                    _VolumeTab(sessions: sessions),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Erreur : $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

// ── Onglet Technique ──────────────────────────────────────────────────────────

class _TechniqueTab extends StatelessWidget {
  const _TechniqueTab({
    required this.sessions,
    required this.days,
    required this.onDaysChanged,
  });

  final List<SwimSession> sessions;
  final int days;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // Stats summary
        StatsSummary(sessions: sessions),
        const SizedBox(height: 20),

        // Sélecteur 30j / 90j
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Évolution SWOLF',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              _PeriodToggle(current: days, onChanged: onDaysChanged),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '  Trait pointillé = tendance  ·  Bas = meilleur',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: 8),

        // Graphique SWOLF
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SwolfChart(sessions: sessions, days: days),
          ),
        ),

        const SizedBox(height: 24),

        // Comparaison semaine courante vs précédente
        _WeekComparison(sessions: sessions),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Onglet Volume ─────────────────────────────────────────────────────────────

class _VolumeTab extends StatelessWidget {
  const _VolumeTab({required this.sessions});

  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Volume par semaine',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '90 derniers jours',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: VolumeChart(sessions: sessions),
          ),
        ),
        const SizedBox(height: 24),
        _MonthlyStats(sessions: sessions),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Widgets auxiliaires ───────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(label: '30j', value: 30, current: current, onTap: onChanged),
          _ToggleBtn(label: '90j', value: 90, current: current, onTap: onChanged),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final int value;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WeekComparison extends StatelessWidget {
  const _WeekComparison({required this.sessions});

  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final lastMonday = monday.subtract(const Duration(days: 7));

    final thisWeek = sessions
        .where((s) => s.startTime.isAfter(monday))
        .toList();
    final lastWeek = sessions
        .where((s) =>
            s.startTime.isAfter(lastMonday) &&
            s.startTime.isBefore(monday))
        .toList();

    if (thisWeek.isEmpty && lastWeek.isEmpty) return const SizedBox.shrink();

    final thisSwolf = thisWeek.isEmpty
        ? null
        : thisWeek.map((s) => s.averageSwolf).reduce((a, b) => a + b) /
            thisWeek.length;
    final lastSwolf = lastWeek.isEmpty
        ? null
        : lastWeek.map((s) => s.averageSwolf).reduce((a, b) => a + b) /
            lastWeek.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cette semaine vs semaine dernière',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CompareCard(
                  label: 'Cette semaine',
                  sessions: thisWeek.length,
                  swolf: thisSwolf,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompareCard(
                  label: 'Semaine passée',
                  sessions: lastWeek.length,
                  swolf: lastSwolf,
                  highlight: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.label,
    required this.sessions,
    required this.swolf,
    required this.highlight,
  });

  final String label;
  final int sessions;
  final double? swolf;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withAlpha(15)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.primary.withAlpha(80) : const Color(0xFFDDE7F3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: highlight ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('$sessions séance${sessions > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          if (swolf != null)
            Text('SWOLF ${swolf!.toStringAsFixed(1)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _MonthlyStats extends StatelessWidget {
  const _MonthlyStats({required this.sessions});

  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final thisMonth = sessions
        .where((s) => s.startTime.isAfter(startOfMonth))
        .toList();
    final totalMeters =
        thisMonth.fold(0, (s, e) => s + e.distanceMeters);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE7F3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ce mois-ci',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  totalMeters >= 1000
                      ? '${(totalMeters / 1000).toStringAsFixed(1)} km nagés'
                      : '${totalMeters}m nagés',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                Text('${thisMonth.length} séances',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
