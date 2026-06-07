import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpectatorScoreboardScreen extends ConsumerWidget {
  const SpectatorScoreboardScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(firestoreServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('liveScoreboard'))),
      body: service == null
          ? Center(child: Text(context.tr('offline')))
          : StreamBuilder<MatchModel?>(
              stream: service.watchByCode(code),
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
        .toList()
        .reversed
        .take(24)
        .toList()
        .reversed;
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
                    SizedBox(width: 62, child: Text('Over ${entry.key + 1}')),
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
