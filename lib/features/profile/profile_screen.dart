import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/watch_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/enums.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(watchMetricsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _ProfileHeader(),
            ),

            // ── Montre connectée ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionTitle(title: 'Montre connectée'),
            ),
            SliverToBoxAdapter(
              child: metricsAsync.when(
                data: (m) => _WatchCard(source: m.source, lastSync: m.timestamp),
                loading: () => const _CardSkeleton(height: 80),
                error: (_, s) => const _WatchCard(source: WatchSource.garmin, lastSync: null),
              ),
            ),

            // ── Profil nageur ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _SectionTitle(title: 'Mon profil')),
            const SliverToBoxAdapter(child: _SwimmerProfileCard()),

            // ── Abonnement ────────────────────────────────────────────────
            SliverToBoxAdapter(child: _SectionTitle(title: 'Abonnement')),
            const SliverToBoxAdapter(child: _SubscriptionCard()),

            // ── Paramètres ────────────────────────────────────────────────
            SliverToBoxAdapter(child: _SectionTitle(title: 'Paramètres')),
            const SliverToBoxAdapter(child: _SettingsList()),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withAlpha(40),
            child: const Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fabrice',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Niveau intermédiaire',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              // TODO: éditer le profil
            },
          ),
        ],
      ),
    );
  }
}

// ── Montre connectée ──────────────────────────────────────────────────────────

class _WatchCard extends StatelessWidget {
  const _WatchCard({required this.source, required this.lastSync});

  final WatchSource source;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7F3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _watchColor(source).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_watchIcon(source), color: _watchColor(source), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _watchLabel(source),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  lastSync != null
                      ? 'Dernière sync : ${_fmtSync(lastSync!)}'
                      : 'En attente de synchronisation',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Badge statut — mock = "Simulation"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Simulation',
              style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _watchColor(WatchSource s) => switch (s) {
        WatchSource.garmin => const Color(0xFF00A650),
        WatchSource.coros => const Color(0xFF0066CC),
        WatchSource.apple => const Color(0xFF555555),
        _ => AppColors.primary,
      };

  IconData _watchIcon(WatchSource s) => switch (s) {
        WatchSource.garmin => Icons.watch,
        WatchSource.coros => Icons.watch_outlined,
        WatchSource.apple => Icons.watch_later_outlined,
        _ => Icons.device_unknown_outlined,
      };

  String _watchLabel(WatchSource s) => switch (s) {
        WatchSource.garmin => 'Garmin',
        WatchSource.coros => 'Coros',
        WatchSource.apple => 'Apple Watch',
        WatchSource.polar => 'Polar',
        WatchSource.manual => 'Saisie manuelle',
      };

  String _fmtSync(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Profil nageur ─────────────────────────────────────────────────────────────

class _SwimmerProfileCard extends StatelessWidget {
  const _SwimmerProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7F3)),
      ),
      child: Column(
        children: [
          _ProfileRow(
            icon: Icons.flag_outlined,
            label: 'Objectif',
            value: 'Progression en piscine',
          ),
          const Divider(height: 1, indent: 54),
          _ProfileRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fréquence',
            value: '3 séances / semaine',
          ),
          const Divider(height: 1, indent: 54),
          _ProfileRow(
            icon: Icons.pool_outlined,
            label: 'Bassin',
            value: '50m',
          ),
          const Divider(height: 1, indent: 54),
          _ProfileRow(
            icon: Icons.show_chart,
            label: 'SWOLF moyen',
            value: '~48',
            trailing: const Text(
              'intermédiaire',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          ?trailing,
          if (trailing == null)
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
        ],
      ),
    );
  }
}

// ── Abonnement ────────────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan Libre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Historique 30j · 3 séances types',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              minimumSize: Size.zero,
            ),
            onPressed: () {
              // TODO: page upgrade
            },
            child: const Text('Passer à Progress'),
          ),
        ],
      ),
    );
  }
}

// ── Paramètres ────────────────────────────────────────────────────────────────

class _SettingsList extends StatelessWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7F3)),
      ),
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.notifications_outlined,
            label: 'Rappels de séance',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 54),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Confidentialité et données',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 54),
          _SettingTile(
            icon: Icons.help_outline,
            label: 'Aide et support',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 54),
          _SettingTile(
            icon: Icons.logout,
            label: 'Déconnecter la montre',
            color: AppColors.error,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: c)),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}

// ── Utils ─────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
