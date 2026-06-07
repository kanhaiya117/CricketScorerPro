import 'dart:async';

import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

class SpectatorScoreboardScreen extends ConsumerStatefulWidget {
  const SpectatorScoreboardScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<SpectatorScoreboardScreen> createState() =>
      _SpectatorScoreboardScreenState();
}

class _SpectatorScoreboardScreenState
    extends ConsumerState<SpectatorScoreboardScreen> {
  String? _lastBallId;
  OverlayEntry? _celebration;
  Timer? _celebrationTimer;

  void _handleUpdate(MatchModel match) {
    if (match.ballHistory.isEmpty) return;
    final ball = match.ballHistory.last;
    if (_lastBallId == null) {
      _lastBallId = ball.id;
      return;
    }
    if (_lastBallId == ball.id) return;
    _lastBallId = ball.id;
    if (!ball.isWicket && ball.runs != 4 && ball.runs != 6) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ball.isWicket) {
        _showCelebration(
          label: 'WICKET!',
          icon: Icons.sports_cricket,
          color: Colors.red,
          vibration: 180,
        );
      } else {
        _showCelebration(
          label: ball.runs == 4 ? 'FOUR!' : 'SIX!',
          icon: ball.runs == 4 ? Icons.looks_4 : Icons.looks_6,
          color: ball.runs == 4 ? Colors.blue : Colors.purple,
          vibration: 100,
        );
      }
    });
  }

  Future<void> _showCelebration({
    required String label,
    required IconData icon,
    required Color color,
    required int vibration,
  }) async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: vibration);
    } else {
      await HapticFeedback.mediumImpact();
    }
    if (!mounted) return;
    _celebrationTimer?.cancel();
    _celebration?.remove();
    _celebration = OverlayEntry(
      builder: (context) =>
          _LiveCelebration(label: label, icon: icon, color: color),
    );
    Overlay.of(context, rootOverlay: true).insert(_celebration!);
    _celebrationTimer = Timer(const Duration(milliseconds: 1100), () {
      _celebration?.remove();
      _celebration = null;
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _celebration?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(firestoreServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('liveScoreboard'))),
      body: service == null
          ? Center(child: Text(context.tr('offline')))
          : StreamBuilder<MatchModel?>(
              stream: service.watchByCode(widget.code),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(context.tr('invalidCode')));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final match = snapshot.data;
                if (match == null) {
                  return Center(child: Text(context.tr('invalidCode')));
                }
                _handleUpdate(match);
                return ResponsiveContent(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: Theme.of(context).colorScheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: DefaultTextStyle(
                            style: const TextStyle(color: Colors.white),
                            child: Column(
                              children: [
                                Text(
                                  '${match.teamA.name} vs ${match.teamB.name}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${match.currentRuns}/${match.currentWickets}',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${match.overs} ${context.tr('overs')}  •  '
                                  'CRR ${match.currentRunRate.toStringAsFixed(2)}',
                                ),
                                const SizedBox(height: 8),
                                Text('Code: ${match.publicCode}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CurrentPlay(match: match),
                      if (match.innings == 2) ...[
                        const SizedBox(height: 10),
                        Card(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ChaseValue(
                                  label: context.tr('target'),
                                  value: '${match.target}',
                                ),
                                _ChaseValue(
                                  label: context.tr('need'),
                                  value: '${match.runsRequired}',
                                ),
                                _ChaseValue(
                                  label: context.tr('ballsLeft'),
                                  value: '${match.ballsRemaining}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _OverEvents(match: match),
                      if (match.result != null) ...[
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              match.result!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _LiveCelebration extends StatelessWidget {
  const _LiveCelebration({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ColoredBox(
        color: Colors.black45,
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            tween: Tween(begin: .25, end: 1),
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
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
        ),
      ),
    ),
  );
}

class _CurrentPlay extends StatelessWidget {
  const _CurrentPlay({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    String name(TeamModel team, String id) =>
        team.players.firstWhere((player) => player.id == id).name;
    final striker = match.battingTeam.players.firstWhere(
      (player) => player.id == match.strikerId,
    );
    final nonStriker = match.battingTeam.players.firstWhere(
      (player) => player.id == match.nonStrikerId,
    );
    final bowler = match.bowlingTeam.players.firstWhere(
      (player) => player.id == match.currentBowlerId,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.sports_cricket),
              title: Text(
                '${context.tr('striker')}: ${name(match.battingTeam, match.strikerId)}',
              ),
              trailing: Text('${striker.runs} (${striker.ballsFaced})'),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(
                '${context.tr('nonStriker')}: '
                '${name(match.battingTeam, match.nonStrikerId)}',
              ),
              trailing: Text('${nonStriker.runs} (${nonStriker.ballsFaced})'),
            ),
            ListTile(
              leading: const Icon(Icons.sports_baseball),
              title: Text('${context.tr('bowler')}: ${bowler.name}'),
              trailing: Text('${bowler.wickets}/${bowler.runsConceded}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverEvents extends StatelessWidget {
  const _OverEvents({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final inningsBalls = match.ballHistory
        .where((ball) => ball.innings == match.innings)
        .toList();
    final overs = <int, List<BallModel>>{};
    for (final ball in inningsBalls) {
      overs.putIfAbsent(ball.overNumber, () => []).add(ball);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('lastOver'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (overs.isEmpty) const Text('No balls recorded yet'),
            for (final entry in overs.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text('${context.tr('overs')} ${entry.key + 1}'),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.value
                            .map(
                              (ball) => CircleAvatar(
                                radius: 18,
                                backgroundColor: ball.isWicket
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                child: Text(_label(ball)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _label(BallModel ball) {
    if (ball.isWicket) return 'W';
    return switch (ball.ballType) {
      BallType.wide => 'Wd',
      BallType.noBall => 'Nb',
      BallType.deadBall => 'Db',
      BallType.normal => '${ball.runs}',
    };
  }
}

class _ChaseValue extends StatelessWidget {
  const _ChaseValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
