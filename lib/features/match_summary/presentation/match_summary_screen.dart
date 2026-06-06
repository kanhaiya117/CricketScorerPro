import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
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
    final batters = [...match.battingTeam.players]
      ..sort((a, b) => b.runs.compareTo(a.runs));
    final bowlers = [...match.bowlingTeam.players]
      ..sort((a, b) => b.wickets.compareTo(a.wickets));
    final topBatter = batters.first;
    final topBowler = bowlers.first;
    final text =
        '''
${match.battingTeam.name} ${match.currentRuns}/${match.currentWickets} (${match.overs})

Top Batter:
${topBatter.name} ${topBatter.runs}(${topBatter.ballsFaced})

Top Bowler:
${topBowler.name} ${topBowler.wickets}/${topBowler.runsConceded}

Result:
${match.result ?? 'Match in progress'}''';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          match.status == MatchStatus.completed ? 'Match Summary' : 'Scorecard',
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: text, subject: 'Cricket Scorer Pro'),
            ),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: 'score-${match.id}',
            child: Card(
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      match.battingTeam.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      '${match.currentRuns}/${match.currentWickets}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${match.overs} overs',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (match.result != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                match.result!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          _Section(
            title: 'Batting',
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Batter')),
                DataColumn(label: Text('R')),
                DataColumn(label: Text('B')),
                DataColumn(label: Text('SR')),
              ],
              rows: match.battingTeam.players
                  .map(
                    (p) => DataRow(
                      cells: [
                        DataCell(Text('${p.name}${p.isOut ? '' : '*'}')),
                        DataCell(Text('${p.runs}')),
                        DataCell(Text('${p.ballsFaced}')),
                        DataCell(Text(p.strikeRate.toStringAsFixed(1))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          _Section(
            title: 'Bowling',
            child: DataTable(
              columnSpacing: 18,
              columns: const [
                DataColumn(label: Text('Bowler')),
                DataColumn(label: Text('O')),
                DataColumn(label: Text('R')),
                DataColumn(label: Text('W')),
                DataColumn(label: Text('Eco')),
              ],
              rows: match.bowlingTeam.players
                  .where((p) => p.ballsBowled > 0)
                  .map(
                    (p) => DataRow(
                      cells: [
                        DataCell(Text(p.name)),
                        DataCell(Text(p.overs)),
                        DataCell(Text('${p.runsConceded}')),
                        DataCell(Text('${p.wickets}')),
                        DataCell(Text(p.economy.toStringAsFixed(1))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (match.status == MatchStatus.completed)
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Dashboard'),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
        ],
      ),
    ),
  );
}
