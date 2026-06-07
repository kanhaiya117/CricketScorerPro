import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MatchHistoryScreen extends ConsumerStatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  ConsumerState<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends ConsumerState<MatchHistoryScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(historyProvider).where((match) {
      final text = '${match.teamA.name} ${match.teamB.name}'.toLowerCase();
      return text.contains(query.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('matchHistory'))),
      body: ResponsiveContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                hintText: 'Search teams',
                leading: const Icon(Icons.search),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.scoreboard_outlined, size: 54),
                          SizedBox(height: 12),
                          Text('No matches found'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return Dismissible(
                          key: ValueKey(match.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete match?'),
                              content: const Text(
                                'This removes the match from this device and cloud backup.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) => ref
                              .read(historyProvider.notifier)
                              .delete(match.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Text(
                                '${match.teamA.name} vs ${match.teamB.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat.yMMMd().add_jm().format(match.createdAt)}\n'
                                '${match.result ?? 'Match in progress'}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${match.currentRuns}/${match.currentWickets}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(match.overs),
                                ],
                              ),
                              onTap: () async {
                                await ref
                                    .read(currentMatchProvider.notifier)
                                    .load(match.id);
                                if (!context.mounted) return;
                                context.push(
                                  match.status == MatchStatus.completed
                                      ? '/summary'
                                      : '/live',
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
