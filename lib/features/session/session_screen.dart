import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/training_block.dart';
import '../../domain/models/training_session.dart';

/// Écran séance guidée — F04 des specs
/// Fonctionne entièrement offline (pas de connexion requise au bord du bassin)
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.session});

  final TrainingSession session;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin {
  late List<_BlockState> _blockStates;
  int _currentBlockIndex = 0;
  int _currentRep = 1;

  // Timer global
  late Stopwatch _globalTimer;
  Timer? _ticker;

  // Timer de récupération inter-répétitions
  int _restSecondsLeft = 0;
  Timer? _restTimer;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _blockStates = widget.session.blocks
        .map((b) => _BlockState(block: b))
        .toList();
    _globalTimer = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Garder l'écran allumé au bord du bassin
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    _globalTimer.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  TrainingBlock get _currentBlock =>
      widget.session.blocks[_currentBlockIndex];

  bool get _isLastBlock =>
      _currentBlockIndex >= widget.session.blocks.length - 1;

  bool get _isLastRep => _currentRep >= _currentBlock.repetitions;

  // ── Actions ──────────────────────────────────────────────────────────────

  void _completeRep() {
    HapticFeedback.mediumImpact();
    setState(() {
      _blockStates[_currentBlockIndex].completedReps = _currentRep;
    });

    if (_isLastRep) {
      _completeBlock();
    } else {
      // Démarrer la récup si définie
      final rest = _currentBlock.restDuration;
      if (rest != null && rest.inSeconds > 0) {
        _startRest(rest.inSeconds);
      } else {
        setState(() => _currentRep++);
      }
    }
  }

  void _startRest(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsLeft = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _restSecondsLeft--);
      if (_restSecondsLeft <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _isResting = false;
          _currentRep++;
        });
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _currentRep++;
    });
  }

  void _completeBlock() {
    setState(() {
      _blockStates[_currentBlockIndex].completed = true;
    });
    if (_isLastBlock) {
      _finishSession();
    } else {
      setState(() {
        _currentBlockIndex++;
        _currentRep = 1;
      });
    }
  }

  void _skipBlock() {
    HapticFeedback.lightImpact();
    if (_isLastBlock) {
      _finishSession();
    } else {
      setState(() {
        _blockStates[_currentBlockIndex].skipped = true;
        _currentBlockIndex++;
        _currentRep = 1;
        _isResting = false;
        _restTimer?.cancel();
      });
    }
  }

  void _finishSession() {
    _globalTimer.stop();
    _ticker?.cancel();
    _restTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _PostSessionScreen(
          session: widget.session,
          duration: _globalTimer.elapsed,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header : timer global + progression
            _SessionHeader(
              elapsed: _globalTimer.elapsed,
              blockIndex: _currentBlockIndex,
              totalBlocks: widget.session.blocks.length,
              onStop: () => _confirmStop(context),
            ),

            // Bloc actuel
            Expanded(
              child: _isResting
                  ? _RestView(
                      secondsLeft: _restSecondsLeft,
                      nextRep: _currentRep + 1,
                      totalReps: _currentBlock.repetitions,
                      onSkip: _skipRest,
                    )
                  : _ActiveBlockView(
                      block: _currentBlock,
                      currentRep: _currentRep,
                      onDone: _completeRep,
                      onSkip: _skipBlock,
                    ),
            ),

            // Liste des blocs (scroll horizontal)
            _BlocksList(
              blocks: widget.session.blocks,
              states: _blockStates,
              currentIndex: _currentBlockIndex,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStop(BuildContext context) async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Arrêter la séance ?',
            style: TextStyle(color: Colors.white)),
        content: const Text('La progression ne sera pas sauvegardée.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Arrêter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (stop == true && context.mounted) Navigator.of(context).pop();
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.elapsed,
    required this.blockIndex,
    required this.totalBlocks,
    required this.onStop,
  });

  final Duration elapsed;
  final int blockIndex;
  final int totalBlocks;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final progress = totalBlocks > 0 ? blockIndex / totalBlocks : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: onStop,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _fmtDuration(elapsed),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Bloc ${blockIndex + 1} / $totalBlocks',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}

class _ActiveBlockView extends StatelessWidget {
  const _ActiveBlockView({
    required this.block,
    required this.currentRep,
    required this.onDone,
    required this.onSkip,
  });

  final TrainingBlock block;
  final int currentRep;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge type de bloc
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _blockColor(block.type).withAlpha(50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blockColor(block.type).withAlpha(120)),
            ),
            child: Text(
              block.name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: _blockColor(block.type),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Distance + répétition
          Text(
            '${block.distanceMeters}m',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Répétition $currentRep / ${block.repetitions}',
            style: const TextStyle(fontSize: 18, color: Colors.white60),
          ),

          if (block.strokeType != null &&
              block.strokeType != StrokeType.unknown) ...[
            const SizedBox(height: 8),
            Text(
              _strokeLabel(block.strokeType!),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            block.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),

          const SizedBox(height: 40),

          // Bouton principal
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blockColor(block.type),
                boxShadow: [
                  BoxShadow(
                    color: _blockColor(block.type).withAlpha(100),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 52),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Terminée', style: TextStyle(color: Colors.white38, fontSize: 13)),

          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next, size: 16, color: Colors.white38),
            label: const Text('Passer ce bloc',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Color _blockColor(BlockType t) => switch (t) {
        BlockType.warmup => AppColors.accent,
        BlockType.drill => AppColors.warning,
        BlockType.main => AppColors.primary,
        BlockType.threshold => const Color(0xFFE63946),
        BlockType.recovery => AppColors.success,
        BlockType.cooldown => AppColors.primaryLight,
      };

  String _strokeLabel(StrokeType s) => switch (s) {
        StrokeType.freestyle => 'Crawl',
        StrokeType.backstroke => 'Dos crawlé',
        StrokeType.breaststroke => 'Brasse',
        StrokeType.butterfly => 'Papillon',
        _ => '',
      };
}

class _RestView extends StatelessWidget {
  const _RestView({
    required this.secondsLeft,
    required this.nextRep,
    required this.totalReps,
    required this.onSkip,
  });

  final int secondsLeft;
  final int nextRep;
  final int totalReps;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'RÉCUPÉRATION',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '$secondsLeft',
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
            height: 1,
          ),
        ),
        const Text('secondes', style: TextStyle(color: Colors.white38, fontSize: 16)),
        const SizedBox(height: 24),
        Text(
          'Prochain : répétition $nextRep / $totalReps',
          style: const TextStyle(color: Colors.white60, fontSize: 15),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
          ),
          onPressed: onSkip,
          child: const Text('Passer la récupération'),
        ),
      ],
    );
  }
}

class _BlocksList extends StatelessWidget {
  const _BlocksList({
    required this.blocks,
    required this.states,
    required this.currentIndex,
  });

  final List<TrainingBlock> blocks;
  final List<_BlockState> states;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: AppColors.surfaceDark,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: blocks.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final block = blocks[i];
          final state = states[i];
          final isActive = i == currentIndex;
          final isDone = state.completed;
          final isSkipped = state.skipped;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? _blockColor(block.type).withAlpha(60)
                  : isDone
                      ? AppColors.success.withAlpha(30)
                      : Colors.white10,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: _blockColor(block.type))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDone)
                  const Icon(Icons.check, size: 14, color: AppColors.success)
                else if (isSkipped)
                  const Icon(Icons.remove, size: 14, color: Colors.white38)
                else
                  Icon(Icons.circle, size: 8, color: _blockColor(block.type)),
                const SizedBox(height: 3),
                Text(
                  block.name.split(' ').first,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.white : Colors.white38,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _blockColor(BlockType t) => switch (t) {
        BlockType.warmup => AppColors.accent,
        BlockType.drill => AppColors.warning,
        BlockType.main => AppColors.primary,
        BlockType.threshold => const Color(0xFFE63946),
        BlockType.recovery => AppColors.success,
        BlockType.cooldown => AppColors.primaryLight,
      };
}

// ── Post-séance ───────────────────────────────────────────────────────────────

class _PostSessionScreen extends StatelessWidget {
  const _PostSessionScreen({
    required this.session,
    required this.duration,
  });

  final TrainingSession session;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final totalDist = session.totalDistanceMeters;
    final mins = duration.inMinutes;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Icône succès
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Séance terminée !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bravo — synchronise ta montre pour enregistrer les données réelles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 40),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PostStat(label: 'Distance prévue', value: '${totalDist}m'),
                  _PostStat(label: 'Durée réelle', value: '$mins min'),
                ],
              ),

              const Spacer(),

              // Boutons
              FilledButton.icon(
                onPressed: () {
                  // TODO: déclencher sync montre
                },
                icon: const Icon(Icons.sync),
                label: const Text('Synchroniser la montre'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Retour au dashboard',
                    style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostStat extends StatelessWidget {
  const _PostStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}

// ── État d'un bloc ────────────────────────────────────────────────────────────

class _BlockState {
  _BlockState({required this.block});
  final TrainingBlock block;
  bool completed = false;
  bool skipped = false;
  int completedReps = 0;
}
