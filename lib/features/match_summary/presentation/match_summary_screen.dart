import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/core/services/pdf_scorecard_service.dart';
import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class MatchSummaryScreen extends ConsumerWidget {
  const MatchSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(currentMatchProvider);
    if (match == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Match not found.')),
      );
    }
    final firstId =
        match.firstInningsBattingTeamId ??
        (match.innings == 1 ? match.battingTeamId : match.bowlingTeamId);
    final first = match.teamA.id == firstId ? match.teamA : match.teamB;
    final second = match.teamA.id == firstId ? match.teamB : match.teamA;
    final firstBalls =
        match.firstInningsLegalBalls ??
        match.ballHistory
            .where((ball) => ball.innings == 1 && ball.isLegalBall)
            .length;
    final secondBalls = match.ballHistory
        .where((ball) => ball.innings == 2 && ball.isLegalBall)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          match.status == MatchStatus.completed
              ? context.tr('matchSummary')
              : context.tr('scorecard'),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('scorecard'),
            onPressed: () async {
              final file = await const PdfScorecardService().generate(match);
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(file.path, mimeType: 'application/pdf')],
                  subject: 'Cric Score Pro Scorecard',
                  text:
                      '${match.teamA.name} vs ${match.teamB.name} '
                      '(${match.publicCode})',
                ),
              );
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ResponsiveContent(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Hero(
              tag: 'score-${match.id}',
              child: Card(
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: Column(
                      children: [
                        Text(
                          '${match.teamA.name} vs ${match.teamB.name}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${first.name} ${first.totalRuns}/${first.wickets} '
                          '(${_overs(firstBalls)})',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (match.innings == 2)
                          Text(
                            '${second.name} ${second.totalRuns}/${second.wickets} '
                            '(${_overs(secondBalls)})',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (match.result != null)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  match.result!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            _InningsCard(
              title: '1st Innings - ${first.name}',
              batting: first,
              bowling: second,
              legalBalls: firstBalls,
            ),
            if (match.innings == 2) ...[
              const SizedBox(height: 12),
              _InningsCard(
                title: '2nd Innings - ${second.name}',
                batting: second,
                bowling: first,
                legalBalls: secondBalls,
              ),
            ],
            if (match.status == MatchStatus.live) ...[
              const SizedBox(height: 12),
              _CurrentPlayers(match: match),
            ],
            const SizedBox(height: 16),
            if (match.status == MatchStatus.completed)
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(context.tr('back')),
              ),
          ],
        ),
      ),
    );
  }

  static String _overs(int balls) => '${balls ~/ 6}.${balls % 6}';
}

class _InningsCard extends StatelessWidget {
  const _InningsCard({
    required this.title,
    required this.batting,
    required this.bowling,
    required this.legalBalls,
  });

  final String title;
  final TeamModel batting;
  final TeamModel bowling;
  final int legalBalls;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${batting.totalRuns}/${batting.wickets} '
            '(${legalBalls ~/ 6}.${legalBalls % 6})  •  '
            'Extras ${batting.extras}',
          ),
          const Divider(),
          Text(
            context.tr('batting'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final player in batting.players)
            if (player.ballsFaced > 0 || player.isOut)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(player.name),
                subtitle: Text(player.dismissalText ?? 'not out'),
                trailing: Text(
                  '${player.runs} (${player.ballsFaced})\n'
                  'SR ${player.strikeRate.toStringAsFixed(1)}',
                  textAlign: TextAlign.right,
                ),
              ),
          const Divider(),
          Text(
            context.tr('bowling'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final player in bowling.players)
            if (player.ballsBowled > 0)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(player.name),
                subtitle: Text(
                  '${player.overs} overs  •  Eco '
                  '${player.economy.toStringAsFixed(1)}',
                ),
                trailing: Text('${player.wickets}/${player.runsConceded}'),
              ),
        ],
      ),
    ),
  );
}

class _CurrentPlayers extends StatelessWidget {
  const _CurrentPlayers({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    String name(TeamModel team, String id) =>
        team.players.firstWhere((player) => player.id == id).name;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('currentPlayers'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Striker: ${name(match.battingTeam, match.strikerId)}'),
            Text('Non-striker: ${name(match.battingTeam, match.nonStrikerId)}'),
            Text('Bowler: ${name(match.bowlingTeam, match.currentBowlerId)}'),
          ],
        ),
      ),
    );
  }
}
