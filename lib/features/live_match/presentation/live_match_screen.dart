import 'dart:async';

import 'package:cricket_scorer_pro/core/ads/innings_banner_popup.dart';
import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/copyable_match_code.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  String? _popupToken;
  Timer? _popupRetry;
  Completer<void>? _popupCompletion;
  int _undoCount = 0;

  void _scheduleInningsPopup(MatchModel match) {
    if (match.status != MatchStatus.live) return;
    final token = '${match.id}:${match.innings}';
    if (_popupToken == token) return;
    _popupRetry?.cancel();
    _popupToken = token;
    final completion = Completer<void>();
    _popupCompletion = completion;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final result = await InningsBannerPopup.showIfNeeded(
          context,
          matchId: match.id,
          innings: match.innings,
          audience: 'scorer',
        );
        if (result == BannerPopupResult.unavailable && mounted) {
          _popupRetry?.cancel();
          _popupRetry = Timer(const Duration(seconds: 30), () {
            if (!mounted) return;
            _popupToken = null;
            final current = ref.read(currentMatchProvider);
            if (current != null) _scheduleInningsPopup(current);
          });
        }
      } finally {
        if (!completion.isCompleted) completion.complete();
      }
    });
  }

  Future<void> _waitForInningsPopup(MatchModel match) async {
    _scheduleInningsPopup(match);
    final completion = _popupCompletion;
    if (completion != null) await completion.future;
  }

  bool _canChangeBowler(MatchModel match) =>
      match.status == MatchStatus.live && match.overComplete;

  @override
  void dispose() {
    _popupRetry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(currentMatchProvider);
    if (match == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No active match found.')),
      );
    }
    if (match.status == MatchStatus.inningsBreak) {
      return _InningsBreakScreen(match: match);
    }
    _scheduleInningsPopup(match);
    final striker = _player(match.battingTeam, match.strikerId);
    final nonStriker = _player(match.battingTeam, match.nonStrikerId);
    final bowler = _player(match.bowlingTeam, match.currentBowlerId);
    final lastSix = match.ballHistory.reversed
        .where((ball) => ball.innings == match.innings)
        .take(6)
        .toList()
        .reversed;
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${match.teamA.name} vs ${match.teamB.name}'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CopyableMatchCode(code: match.publicCode, compact: true),
              ),
            ),
            IconButton(
              tooltip: context.tr('scorecard'),
              onPressed: () => context.push('/summary'),
              icon: const Icon(Icons.scoreboard_outlined),
            ),
          ],
        ),
        body: ResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _ScoreHero(match: match),
              if (match.innings == 2) ...[
                const SizedBox(height: 10),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ChaseStat(
                          label: context.tr('target'),
                          value: '${match.target}',
                        ),
                        _ChaseStat(
                          label: context.tr('need'),
                          value:
                              '${match.runsRequired} from ${match.ballsRemaining}',
                        ),
                        _ChaseStat(
                          label: context.tr('rrr'),
                          value: match.requiredRunRate.toStringAsFixed(2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PlayerRow(
                        player: striker,
                        label: context.tr('striker'),
                        active: true,
                      ),
                      const Divider(),
                      _PlayerRow(
                        player: nonStriker,
                        label: context.tr('nonStriker'),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.sports_baseball),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${bowler.name}  ${bowler.wickets}/${bowler.runsConceded} (${bowler.overs})',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('last6'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: lastSix
                    .map((ball) => _BallBadge(ball: ball))
                    .toList(),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 500 ? 6 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.65,
                children: [0, 1, 2, 3, 4, 6]
                    .map(
                      (run) => FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _runButtonColor(run),
                          foregroundColor: Colors.white,
                          elevation: run == 4 || run == 6 ? 3 : 1,
                          shadowColor: _runButtonColor(
                            run,
                          ).withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () => _score(context, ref, match, runs: run),
                        child: Text(
                          '$run',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _wicketSheet(context, ref, match),
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('wicket')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _extraSheet(context, ref, match),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(context.tr('extra')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ScorerActionButton(
                      icon: Icons.undo_rounded,
                      label: context.tr('undo'),
                      onPressed:
                          match.ballHistory
                                  .where(
                                    (ball) => ball.innings == match.innings,
                                  )
                                  .isEmpty ||
                              _undoCount >= 2
                          ? null
                          : () => _undo(ref),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScorerActionButton(
                      icon: Icons.sports_baseball_outlined,
                      label: context.tr('changeBowler'),
                      onPressed: _canChangeBowler(match)
                          ? () => _bowlerSheet(
                              context,
                              ref,
                              match,
                              overComplete: true,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScorerActionButton(
                      icon: Icons.stop_circle_outlined,
                      label: context.tr('end'),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _endMatch(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PlayerModel _player(TeamModel team, String id) =>
      team.players.firstWhere((p) => p.id == id);

  Future<void> _score(
    BuildContext context,
    WidgetRef ref,
    MatchModel before, {
    required int runs,
    BallType type = BallType.normal,
  }) async {
    await _vibrate(runs == 4 || runs == 6 ? 90 : 35);
    final updated = await ref
        .read(currentMatchProvider.notifier)
        .score(runs: runs, ballType: type);
    if (!context.mounted || updated == null) return;
    if (_undoCount != 0) {
      setState(() => _undoCount = 0);
    }
    await _waitForInningsPopup(updated);
    if (!context.mounted) return;
    if (runs == 4 || runs == 6) {
      await _showCelebration(
        context,
        label: runs == 4 ? 'FOUR!' : 'SIX!',
        icon: runs == 4 ? Icons.looks_4 : Icons.looks_6,
        color: runs == 4 ? Colors.blue : Colors.purple,
      );
      if (!context.mounted) return;
    }
    if (updated.status == MatchStatus.completed) {
      context.go('/summary');
    } else if (updated.status == MatchStatus.live &&
        updated.overComplete &&
        updated.legalBalls != before.legalBalls &&
        updated.legalBalls % 6 == 0) {
      await _bowlerSheet(context, ref, updated, overComplete: true);
    }
  }

  Future<void> _extraSheet(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
  ) async {
    final type = await showModalBottomSheet<BallType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('selectExtra'),
              style: const TextStyle(fontSize: 20),
            ),
            for (final value in [
              BallType.wide,
              BallType.noBall,
              BallType.bye,
              BallType.legBye,
              BallType.deadBall,
            ])
              ListTile(
                title: Text(switch (value) {
                  BallType.wide => 'Wide',
                  BallType.noBall => 'No Ball',
                  BallType.bye => 'Bye',
                  BallType.legBye => 'Leg Bye',
                  BallType.deadBall => 'Dead Ball',
                  _ => '',
                }),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    if (type == BallType.deadBall) {
      await _score(context, ref, match, runs: 0, type: type);
      return;
    }
    final values = switch (type) {
      BallType.wide => [0, 1, 2, 3, 4],
      BallType.noBall => [0, 1, 2, 3, 4, 6],
      BallType.bye || BallType.legBye => [1, 2, 3, 4],
      _ => <int>[],
    };
    final runs = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_extraTitle(type), style: const TextStyle(fontSize: 20)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final value in values)
                    FilledButton.tonal(
                      onPressed: () => Navigator.pop(context, value),
                      child: Text(_extraOption(type, value)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (runs != null && context.mounted) {
      await _score(context, ref, match, runs: runs, type: type);
    }
  }

  String _extraTitle(BallType type) => switch (type) {
    BallType.wide => 'Wide runs',
    BallType.noBall => 'No Ball + bat runs',
    BallType.bye => 'Bye runs',
    BallType.legBye => 'Leg Bye runs',
    _ => 'Extras',
  };

  String _extraOption(BallType type, int runs) => switch (type) {
    BallType.wide => runs == 0 ? 'Wide (1)' : 'Wide +$runs (${runs + 1})',
    BallType.noBall => runs == 0 ? 'No Ball (1)' : 'No Ball +$runs',
    BallType.bye => 'Bye +$runs',
    BallType.legBye => 'Leg Bye +$runs',
    _ => '$runs',
  };

  Future<void> _wicketSheet(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
  ) async {
    final type = await showModalBottomSheet<WicketType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('howOut'), style: const TextStyle(fontSize: 20)),
            for (final value in [
              WicketType.bowled,
              WicketType.caught,
              WicketType.lbw,
              WicketType.runOut,
            ])
              ListTile(
                title: Text(
                  value.name == 'runOut' ? 'Run Out' : value.name.toUpperCase(),
                ),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    String dismissed = match.strikerId;
    if (type == WicketType.runOut) {
      dismissed =
          await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(title: Text('Dismissed batter')),
                  for (final id in [match.strikerId, match.nonStrikerId])
                    ListTile(
                      title: Text(_player(match.battingTeam, id).name),
                      onTap: () => Navigator.pop(context, id),
                    ),
                ],
              ),
            ),
          ) ??
          match.strikerId;
    }
    String? fielderId;
    if (type == WicketType.caught || type == WicketType.runOut) {
      if (!context.mounted) return;
      fielderId = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  type == WicketType.caught
                      ? 'Who took the catch?'
                      : 'Select the fielder',
                ),
              ),
              for (final player in match.bowlingTeam.players)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(player.name),
                  onTap: () => Navigator.pop(context, player.id),
                ),
            ],
          ),
        ),
      );
      if (fielderId == null) return;
    }
    if (!context.mounted) return;
    final available = match.battingTeam.players
        .where(
          (p) =>
              !p.isOut && p.id != match.strikerId && p.id != match.nonStrikerId,
        )
        .toList();
    final next = available.isEmpty
        ? null
        : await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(title: Text(context.tr('nextBatter'))),
                  for (final player in available)
                    ListTile(
                      title: Text(player.name),
                      onTap: () => Navigator.pop(context, player.id),
                    ),
                ],
              ),
            ),
          );
    if (available.isNotEmpty && next == null) return;
    final updated = await ref
        .read(currentMatchProvider.notifier)
        .score(
          runs: 0,
          wicketType: type,
          dismissedBatsmanId: dismissed,
          nextBatsmanId: next,
          fielderId: fielderId,
        );
    if (updated != null && _undoCount != 0 && mounted) {
      setState(() => _undoCount = 0);
    }
    await _vibrate(180);
    if (updated != null && context.mounted) {
      await _waitForInningsPopup(updated);
    }
    if (context.mounted && updated != null) {
      await _showCelebration(
        context,
        label: 'WICKET!',
        icon: Icons.sports_cricket,
        color: Colors.red,
      );
    }
    if (!context.mounted || updated == null) return;
    if (updated.status == MatchStatus.completed) {
      context.go('/summary');
    } else if (updated.status == MatchStatus.live &&
        updated.overComplete &&
        updated.legalBalls != match.legalBalls &&
        updated.legalBalls % 6 == 0) {
      await _bowlerSheet(context, ref, updated, overComplete: true);
    }
  }

  Future<void> _vibrate(int duration) async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: duration);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> _undo(WidgetRef ref) async {
    if (_undoCount >= 2) return;
    await ref.read(currentMatchProvider.notifier).undo();
    if (!mounted) return;
    setState(() => _undoCount++);
  }

  Future<void> _showCelebration(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) async {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 650)).then((_) {
        if (context.mounted &&
            Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }),
    );
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 76),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        ),
      ),
    );
  }

  Future<void> _bowlerSheet(
    BuildContext context,
    WidgetRef ref,
    MatchModel match, {
    bool overComplete = false,
  }) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PopScope(
        canPop: false,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .76,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.sports_baseball,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    overComplete
                        ? context.tr('overComplete')
                        : context.tr('changeBowler'),
                  ),
                  subtitle: Text(context.tr('selectNewBowler')),
                  trailing: overComplete
                      ? null
                      : IconButton.filledTonal(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: match.bowlingTeam.players.length,
                    itemBuilder: (context, index) {
                      final player = match.bowlingTeam.players[index];
                      final unavailable =
                          player.id ==
                          (match.previousBowlerId ?? match.currentBowlerId);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        color: unavailable
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                            : null,
                        child: ListTile(
                          enabled: !unavailable,
                          leading: CircleAvatar(
                            child: Icon(
                              unavailable ? Icons.block : Icons.sports_baseball,
                            ),
                          ),
                          title: Text(player.name),
                          subtitle: Text(
                            unavailable
                                ? context.tr('unavailable')
                                : '${player.overs} ov  •  '
                                      '${player.runsConceded} runs  •  '
                                      '${player.wickets} wickets  •  '
                                      'Eco ${player.economy.toStringAsFixed(1)}',
                          ),
                          trailing: unavailable
                              ? const Icon(Icons.lock_outline)
                              : const Icon(Icons.arrow_forward),
                          onTap: unavailable
                              ? null
                              : () => Navigator.pop(context, player.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (id != null) {
      await ref.read(currentMatchProvider.notifier).changeBowler(id);
    }
  }

  Future<void> _endMatch(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('endMatch')),
        content: const Text('The current score will be saved as final.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('endMatch')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(currentMatchProvider.notifier).endMatch();
      if (context.mounted) context.go('/summary');
    }
  }

  Color _runButtonColor(int run) {
    return switch (run) {
      0 => const Color(0xFF546E7A),
      1 => const Color(0xFF277A62),
      2 => const Color(0xFF19766F),
      3 => const Color(0xFF166E80),
      4 => const Color(0xFF1769AA),
      6 => const Color(0xFF7B4EA3),
      _ => const Color(0xFF277A62),
    };
  }
}

class _ScorerActionButton extends StatelessWidget {
  const _ScorerActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;
    final containerColor = color == null
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.errorContainer;
    final contentColor = color == null
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: containerColor,
        foregroundColor: contentColor,
        disabledBackgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
        disabledForegroundColor: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        elevation: 1,
        shadowColor: buttonColor.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context) => Hero(
    tag: 'score-${match.id}',
    child: Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            children: [
              Text(
                match.battingTeam.name,
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                '${match.currentRuns}/${match.currentWickets}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${match.overs} overs  |  CRR ${match.currentRunRate.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.label,
    this.active = false,
  });
  final PlayerModel player;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(active ? Icons.play_arrow : Icons.person_outline),
      const SizedBox(width: 8),
      Expanded(child: Text('$label: ${player.name}')),
      Text(
        '${player.runs} (${player.ballsFaced})',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _BallBadge extends StatelessWidget {
  const _BallBadge({required this.ball});
  final BallModel ball;

  @override
  Widget build(BuildContext context) {
    final label = ball.isWicket
        ? 'W'
        : switch (ball.ballType) {
            BallType.wide => ball.extraRuns == 1 ? 'Wd' : '${ball.extraRuns}Wd',
            BallType.noBall => ball.runs == 0 ? 'Nb' : 'Nb+${ball.runs}',
            BallType.bye => 'B${ball.extraRuns}',
            BallType.legBye => 'Lb${ball.extraRuns}',
            BallType.deadBall => 'Db',
            BallType.normal => '${ball.runs}',
          };
    return CircleAvatar(
      backgroundColor: ball.isWicket
          ? Colors.red
          : ball.ballType == BallType.normal
          ? Colors.green
          : Colors.orange,
      foregroundColor: Colors.white,
      child: Text(label),
    );
  }
}

class _ChaseStat extends StatelessWidget {
  const _ChaseStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _InningsBreakScreen extends ConsumerWidget {
  const _InningsBreakScreen({required this.match});

  final MatchModel match;

  Future<List<String>?> _selectOpeningBatters(BuildContext context) =>
      showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: _SecondInningsBattersDialog(
            players: match.bowlingTeam.players,
          ),
        ),
      );

  Future<String?> _selectOpeningBowler(BuildContext context) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: _SecondInningsBowlerDialog(players: match.battingTeam.players),
        ),
      );

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final batters = await _selectOpeningBatters(context);
    if (batters == null || !context.mounted) return;
    final bowler = await _selectOpeningBowler(context);
    if (bowler == null) return;
    await ref
        .read(currentMatchProvider.notifier)
        .startSecondInnings(
          strikerId: batters[0],
          nonStrikerId: batters[1],
          bowlerId: bowler,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.tr('inningsBreak'))),
    body: ResponsiveContent(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.swap_horiz, size: 54),
                    const SizedBox(height: 12),
                    Text(
                      '${match.battingTeam.name} Innings Complete',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${match.currentRuns}/${match.currentWickets} '
                      '(${match.overs} overs)',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${match.bowlingTeam.name} need ${match.target} runs to win',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _start(context, ref),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(context.tr('startChase')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SecondInningsBattersDialog extends StatefulWidget {
  const _SecondInningsBattersDialog({required this.players});

  final List<PlayerModel> players;

  @override
  State<_SecondInningsBattersDialog> createState() =>
      _SecondInningsBattersDialogState();
}

class _SecondInningsBattersDialogState
    extends State<_SecondInningsBattersDialog> {
  String? strikerId;
  String? nonStrikerId;
  String selectedRole = 'striker';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('openingBatters')),
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'striker',
                icon: const Icon(Icons.sports_cricket),
                label: Text(context.tr('striker')),
              ),
              ButtonSegment(
                value: 'nonStriker',
                icon: const Icon(Icons.people_outline),
                label: Text(context.tr('nonStriker')),
              ),
            ],
            selected: {selectedRole},
            onSelectionChanged: (selection) =>
                setState(() => selectedRole = selection.first),
          ),
          const SizedBox(height: 10),
          Text(
            selectedRole == 'striker'
                ? context.tr('selectStriker')
                : context.tr('selectNonStriker'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                final player = widget.players[index];
                final isStriker = strikerId == player.id;
                final isNonStriker = nonStrikerId == player.id;
                final blocked =
                    player.isOut ||
                    (selectedRole == 'striker' ? isNonStriker : isStriker);
                return Card(
                  color: isStriker || isNonStriker
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    enabled: !blocked,
                    leading: CircleAvatar(
                      child: isStriker
                          ? const Icon(Icons.sports_cricket)
                          : isNonStriker
                          ? const Icon(Icons.people_outline)
                          : Text('${index + 1}'),
                    ),
                    title: Text(player.name),
                    subtitle: Text(
                      isStriker
                          ? context.tr('striker')
                          : isNonStriker
                          ? context.tr('nonStriker')
                          : player.isOut
                          ? 'Out - unavailable'
                          : context.tr('available'),
                    ),
                    trailing: isStriker || isNonStriker
                        ? const Icon(Icons.check_circle)
                        : blocked
                        ? const Icon(Icons.block)
                        : const Icon(Icons.touch_app_outlined),
                    onTap: blocked
                        ? null
                        : () => setState(() {
                            if (selectedRole == 'striker') {
                              strikerId = player.id;
                              selectedRole = 'nonStriker';
                            } else {
                              nonStrikerId = player.id;
                            }
                          }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      FilledButton.icon(
        onPressed: strikerId != null && nonStrikerId != null
            ? () => Navigator.pop(context, [strikerId!, nonStrikerId!])
            : null,
        icon: const Icon(Icons.check),
        label: Text(context.tr('confirm')),
      ),
    ],
  );
}

class _SecondInningsBowlerDialog extends StatefulWidget {
  const _SecondInningsBowlerDialog({required this.players});

  final List<PlayerModel> players;

  @override
  State<_SecondInningsBowlerDialog> createState() =>
      _SecondInningsBowlerDialogState();
}

class _SecondInningsBowlerDialogState
    extends State<_SecondInningsBowlerDialog> {
  String? selectedId;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Select Opening Bowler'),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.players.length,
        itemBuilder: (context, index) {
          final player = widget.players[index];
          final selected = selectedId == player.id;
          return Card(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: const Icon(Icons.sports_baseball),
              title: Text(player.name),
              trailing: selected ? const Icon(Icons.check_circle) : null,
              onTap: () => setState(() => selectedId = player.id),
            ),
          );
        },
      ),
    ),
    actions: [
      FilledButton.icon(
        onPressed: selectedId == null
            ? null
            : () => Navigator.pop(context, selectedId),
        icon: const Icon(Icons.check),
        label: Text(context.tr('confirm')),
      ),
    ],
  );
}
