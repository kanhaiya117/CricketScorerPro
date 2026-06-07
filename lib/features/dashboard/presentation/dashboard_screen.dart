import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/core/localization/locale_provider.dart';
import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/main.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/app_background.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _codeController = TextEditingController();
  bool _finding = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _findMatch() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) return;
    final service = ref.read(firestoreServiceProvider);
    if (service == null) {
      _message(context.tr('offline'));
      return;
    }
    setState(() => _finding = true);
    try {
      final match = await service.findByCode(code);
      if (!mounted) return;
      if (match == null) {
        _message(context.tr('invalidCode'));
      } else {
        context.push('/watch/${match.publicCode}');
      }
    } catch (_) {
      if (mounted) _message(context.tr('invalidCode'));
    } finally {
      if (mounted) setState(() => _finding = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(historyProvider);
    final sync = ref.watch(syncProvider);
    final locale = ref.watch(localeProvider);
    final unfinished = matches
        .where((match) => match.status != MatchStatus.completed)
        .firstOrNull;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ResponsiveContent(
            child: RefreshIndicator(
              onRefresh: () => ref.read(syncProvider.notifier).sync(),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 380 ? 14 : 20,
                  vertical: 18,
                ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Cric Score Pro',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(context.tr('tagline')),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: context.tr('language'),
                        initialValue: locale.languageCode,
                        icon: const Icon(Icons.translate),
                        onSelected: (code) => ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(code)),
                        itemBuilder: (_) => AppLocalizations
                            .languageNames
                            .entries
                            .map(
                              (entry) => PopupMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                      ),
                      IconButton(
                        tooltip: 'Theme',
                        onPressed: () =>
                            ref.read(themeModeProvider.notifier).toggle(),
                        icon: const Icon(Icons.brightness_6_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (unfinished != null) ...[
                    _ResumeCard(match: unfinished),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: () => context.push('/setup'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(context.tr('startMatch')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: matches.isEmpty
                        ? null
                        : () => context.push('/history'),
                    icon: const Icon(Icons.history),
                    label: Text(context.tr('matchHistory')),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr('watchLive'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 400;
                          final input = TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 6,
                            onSubmitted: (_) => _findMatch(),
                            decoration: InputDecoration(
                              counterText: '',
                              labelText: context.tr('matchCode'),
                              prefixIcon: const Icon(Icons.tag),
                            ),
                          );
                          final button = FilledButton.icon(
                            onPressed: _finding ? null : _findMatch,
                            icon: _finding
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(context.tr('find')),
                          );
                          return narrow
                              ? Column(
                                  children: [
                                    input,
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: button,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: input),
                                    const SizedBox(width: 10),
                                    button,
                                  ],
                                );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr('cloudBackup'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                      ? context.tr('syncing')
                                      : sync.isOnline
                                      ? context.tr('online')
                                      : context.tr('offline'),
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
                ],
              ),
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MATCH IN PROGRESS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.visibility, size: 18),
                label: Text(match.publicCode),
              ),
            ],
          ),
          Text(
            '${match.teamA.name} vs ${match.teamB.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${match.currentRuns}/${match.currentWickets} '
            '(${match.overs} ov)',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(currentMatchProvider.notifier).load(match.id);
              if (context.mounted) context.push('/live');
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(context.tr('continueMatch')),
          ),
        ],
      ),
    ),
  );
}
