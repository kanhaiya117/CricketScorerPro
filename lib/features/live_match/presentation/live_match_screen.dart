import 'dart:async';

import 'package:cricket_scorer_pro/features/live_match/engine/match_insights.dart';
import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

class LiveMatchScreen extends ConsumerWidget {
  const LiveMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: Chip(
                  avatar: const Icon(Icons.visibility, size: 17),
                  label: Text(match.publicCode),
                  visualDensity: VisualDensity.compact,
                ),
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
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(const MatchInsights().forMatch(match)),
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
                          backgroundColor: Colors.green.shade700,
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
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () => _extraSheet(context, ref, match),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('extra')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: match.ballHistory.isEmpty
                        ? null
                        : () => ref.read(currentMatchProvider.notifier).undo(),
                    icon: const Icon(Icons.undo),
                    label: Text(context.tr('undo')),
                  ),
                  TextButton.icon(
                    onPressed: () => _bowlerSheet(context, ref, match),
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(context.tr('changeBowler')),
                  ),
                  TextButton.icon(
                    onPressed: () => _endMatch(context, ref),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(context.tr('end')),
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
    if (runs == 4 || runs == 6) {
      unawaited(
        _showCelebration(
          context,
          label: runs == 4 ? 'FOUR!' : 'SIX!',
          icon: runs == 4 ? Icons.looks_4 : Icons.looks_6,
          color: runs == 4 ? Colors.blue : Colors.purple,
        ),
      );
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
              BallType.deadBall,
            ])
              ListTile(
                title: Text(switch (value) {
                  BallType.wide => 'Wide (+1)',
                  BallType.noBall => 'No Ball (+1)',
                  BallType.deadBall => 'Dead Ball',
                  _ => '',
                }),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (type != null && context.mounted) {
      await _score(context, ref, match, runs: 0, type: type);
    }
  }

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
    await _vibrate(180);
    if (context.mounted && updated != null) {
      unawaited(
        _showCelebration(
          context,
          label: 'WICKET!',
          icon: Icons.sports_cricket,
          color: Colors.red,
        ),
      );
    }
    if (context.mounted && updated?.status == MatchStatus.completed) {
      context.go('/summary');
    }
  }

  Future<void> _vibrate(int duration) async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: duration);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> _showCelebration(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) async {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 950)).then((_) {
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
      transitionDuration: const Duration(milliseconds: 280),
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
      isDismissible: !overComplete,
      enableDrag: !overComplete,
      builder: (context) => PopScope(
        canPop: !overComplete,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .76,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    overComplete
                        ? context.tr('overComplete')
                        : context.tr('changeBowler'),
                  ),
                  subtitle: Text(context.tr('selectNewBowler')),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: match.bowlingTeam.players.length,
                    itemBuilder: (context, index) {
                      final player = match.bowlingTeam.players[index];
                      final unavailable = player.id == match.currentBowlerId;
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
            BallType.wide => 'Wd',
            BallType.noBall => 'Nb',
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

  Future<String?> _selectPlayer(
    BuildContext context, {
    required String title,
    required TeamModel team,
    String? excludedId,
    IconData icon = Icons.person,
  }) => showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => PopScope(
      canPop: false,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .72,
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(icon),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final player in team.players)
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          enabled: !player.isOut && player.id != excludedId,
                          leading: CircleAvatar(child: Icon(icon)),
                          title: Text(player.name),
                          subtitle: Text(
                            player.isOut
                                ? 'Out - unavailable'
                                : player.id == excludedId
                                ? 'Already selected'
                                : 'Available',
                          ),
                          trailing: player.isOut || player.id == excludedId
                              ? const Icon(Icons.block)
                              : const Icon(Icons.check_circle_outline),
                          onTap: player.isOut || player.id == excludedId
                              ? null
                              : () => Navigator.pop(context, player.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final batting = match.bowlingTeam;
    final bowling = match.battingTeam;
    final striker = await _selectPlayer(
      context,
      title: 'Select Striker',
      team: batting,
      icon: Icons.sports_cricket,
    );
    if (striker == null || !context.mounted) return;
    final nonStriker = await _selectPlayer(
      context,
      title: 'Select Non-striker',
      team: batting,
      excludedId: striker,
      icon: Icons.people_alt_outlined,
    );
    if (nonStriker == null || !context.mounted) return;
    final bowler = await _selectPlayer(
      context,
      title: 'Select Opening Bowler',
      team: bowling,
      icon: Icons.sports_baseball,
    );
    if (bowler == null) return;
    await ref
        .read(currentMatchProvider.notifier)
        .startSecondInnings(
          strikerId: striker,
          nonStrikerId: nonStriker,
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
