import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/training_plan_provider.dart';
import '../../core/providers/watch_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/enums.dart';
import 'widgets/body_battery_card.dart';
import 'widgets/last_session_card.dart';
import 'widgets/today_session_card.dart';
import 'widgets/week_chips.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentWeekPlanProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final metricsAsync = ref.watch(watchMetricsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar collapsible ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              pinned: false,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: _Header(),
              ),
            ),

            // ── Chips de la semaine ────────────────────────────────────────
            SliverToBoxAdapter(
              child: planAsync.when(
                data: (plan) => Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: WeekChips(plan: plan),
                ),
                loading: () => const _ChipsPlaceholder(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),

            // ── Ajustement Body Battery ────────────────────────────────────
            SliverToBoxAdapter(
              child: planAsync.when(
                data: (plan) => plan.adjustmentReason != null
                    ? _AdjustmentBanner(reason: plan.adjustmentReason!)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),

            // ── Séance du jour ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                child: Text(
                  'Séance du jour',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: planAsync.when(
                data: (plan) {
                  final today = plan.todaySession;
                  if (today == null || today.status == SessionStatus.rest) {
                    return const _RestDayCard();
                  }
                  return TodaySessionCard(session: today);
                },
                loading: () => const _CardPlaceholder(height: 200),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
            ),

            // ── Body Battery ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: metricsAsync.when(
                data: (metrics) => metrics.bodyBattery != null
                    ? BodyBatteryCard(metrics: metrics)
                    : const SizedBox.shrink(),
                loading: () => const _CardPlaceholder(height: 80),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),

            // ── Dernière séance ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                child: Text(
                  'Dernière activité',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) return const _NoSessionCard();
                  final last = sessions.first;
                  final prev = sessions.length > 1 ? sessions[1] : null;
                  return LastSessionCard(
                    session: last,
                    previousSession: prev,
                  );
                },
                loading: () => const _CardPlaceholder(height: 100),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final weekNum = _isoWeekNumber(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Semaine $weekNum · ${_formatDate(now)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Bouton sync
        IconButton(
          icon: const Icon(Icons.sync, color: AppColors.primary),
          tooltip: 'Synchroniser',
          onPressed: () {
            // TODO: déclencher syncNow()
          },
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Bonjour 👋';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));
    return ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  }
}

class _AdjustmentBanner extends StatelessWidget {
  const _AdjustmentBanner({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.bedtime_outlined, size: 32, color: AppColors.accent),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jour de repos',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Récupération active — marche, étirements',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 32, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'Aucune séance synchronisée',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Connecter ma montre'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ChipsPlaceholder extends StatelessWidget {
  const _ChipsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Container(
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
