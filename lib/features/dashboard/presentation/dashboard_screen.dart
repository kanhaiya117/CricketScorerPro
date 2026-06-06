import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/main.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(historyProvider);
    final sync = ref.watch(syncProvider);
    final unfinished = matches
        .where((m) => m.status != MatchStatus.completed)
        .firstOrNull;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(syncProvider.notifier).sync(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.sports_cricket,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cricket Scorer Pro',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text('Score every ball. Anywhere.'),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Toggle theme',
                      onPressed: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                      icon: const Icon(Icons.brightness_6_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (unfinished != null) ...[
                  _ResumeCard(match: unfinished),
                  const SizedBox(height: 18),
                ],
                FilledButton.icon(
                  onPressed: () => context.push('/setup'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Start New Match'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: matches.isEmpty
                      ? null
                      : () => context.push('/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('Match History'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cloud backup',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(
                          sync.isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: sync.isOnline ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sync.isSyncing
                                    ? 'Syncing...'
                                    : sync.isOnline
                                    ? 'Online'
                                    : 'Offline - saved locally',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                sync.lastSynced == null
                                    ? 'No cloud sync this session'
                                    : 'Last synced ${DateFormat.jm().format(sync.lastSynced!)}',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: sync.isOnline
                              ? () => ref.read(syncProvider.notifier).sync()
                              : null,
                          icon: const Icon(Icons.sync),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${matches.length} match${matches.length == 1 ? '' : 'es'} saved on this device',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumeCard extends ConsumerWidget {
  const _ResumeCard({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH IN PROGRESS',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            '${match.teamA.name} vs ${match.teamB.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${match.currentRuns}/${match.currentWickets}  (${match.overs} ov)',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(currentMatchProvider.notifier).load(match.id);
              if (context.mounted) context.push('/live');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Continue Match'),
          ),
        ],
      ),
    ),
  );
}
