import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/training_plan_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/session_day_tile.dart';
import 'widgets/week_volume_bar.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentWeekPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              title: planAsync.when(
                data: (plan) => Text(
                  'Semaine ${plan.weekId.split('-W').last}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                loading: () => const Text('Plan'),
                error: (_, s) => const Text('Plan'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  tooltip: 'Recalculer le plan',
                  onPressed: () => ref.invalidate(currentWeekPlanProvider),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: planAsync.when(
                  data: (plan) => WeekVolumeBar(plan: plan),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, s) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ── Bannière ajustement IA ────────────────────────────────────
            SliverToBoxAdapter(
              child: planAsync.when(
                data: (plan) => plan.adjustmentReason != null
                    ? _AdjustmentCard(reason: plan.adjustmentReason!)
                    : const SizedBox(height: 8),
                loading: () => const SizedBox.shrink(),
                error: (_, s) => const SizedBox.shrink(),
              ),
            ),

            // ── Liste des jours ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: planAsync.when(
                data: (plan) => Column(
                  children: plan.sessions
                      .map((s) => SessionDayTile(session: s))
                      .toList(),
                ),
                loading: () => const _PlanSkeleton(),
                error: (e, _) => _ErrorState(message: e.toString()),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  const _AdjustmentCard({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan ajusté automatiquement',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        7,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
