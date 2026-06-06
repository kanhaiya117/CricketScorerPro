import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  final _teamA = TextEditingController(text: 'Team A');
  final _teamB = TextEditingController(text: 'Team B');
  late final List<TextEditingController> _playersA;
  late final List<TextEditingController> _playersB;
  bool _teamAConfigured = false;
  bool _teamBConfigured = false;
  int _step = 0;
  int _overs = 5;
  String _batting = 'A';

  @override
  void initState() {
    super.initState();
    _playersA = _defaultPlayers('Team A');
    _playersB = _defaultPlayers('Team B');
  }

  List<TextEditingController> _defaultPlayers(String team) => List.generate(
    11,
    (index) => TextEditingController(text: '$team Player ${index + 1}'),
  );

  @override
  void dispose() {
    _teamA.dispose();
    _teamB.dispose();
    for (final controller in [..._playersA, ..._playersB]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validTeam(
    TextEditingController team,
    List<TextEditingController> players,
    bool configured,
  ) =>
      configured &&
      team.text.trim().isNotEmpty &&
      players.length == 11 &&
      players.every((player) => player.text.trim().isNotEmpty);

  void _continue() {
    final valid = switch (_step) {
      0 => _validTeam(_teamA, _playersA, _teamAConfigured),
      1 => _validTeam(_teamB, _playersB, _teamBConfigured),
      2 => _batting.isNotEmpty,
      _ => _overs > 0,
    };
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _step < 2
                ? 'Open Add Players and save the 11-player team first.'
                : 'Complete this step before continuing.',
          ),
        ),
      );
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _start();
    }
  }

  Future<void> _openRoster({
    required TextEditingController team,
    required List<TextEditingController> players,
    required bool isTeamA,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RosterDialog(team: team, players: players),
    );
    if (saved == true && mounted) {
      setState(() {
        if (isTeamA) {
          _teamAConfigured = true;
        } else {
          _teamBConfigured = true;
        }
      });
    }
  }

  Future<void> _start() async {
    const uuid = Uuid();
    TeamModel buildTeam(String name, List<TextEditingController> controllers) {
      return TeamModel(
        id: uuid.v4(),
        name: name.trim(),
        players: controllers
            .map(
              (player) => PlayerModel(id: uuid.v4(), name: player.text.trim()),
            )
            .toList(),
      );
    }

    final a = buildTeam(_teamA.text, _playersA);
    final b = buildTeam(_teamB.text, _playersB);
    final batting = _batting == 'A' ? a : b;
    final bowling = _batting == 'A' ? b : a;
    final now = DateTime.now();
    final match = MatchModel(
      id: uuid.v4(),
      teamA: a,
      teamB: b,
      battingTeamId: batting.id,
      bowlingTeamId: bowling.id,
      strikerId: batting.players[0].id,
      nonStrikerId: batting.players[1].id,
      currentBowlerId: bowling.players[0].id,
      totalOvers: _overs,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(currentMatchProvider.notifier).start(match);
    if (mounted) context.go('/live');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Start Match')),
    body: Stepper(
      currentStep: _step,
      onStepTapped: (value) {
        if (value <= _step) setState(() => _step = value);
      },
      onStepContinue: _continue,
      onStepCancel: _step == 0 ? null : () => setState(() => _step--),
      controlsBuilder: (context, details) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: details.onStepContinue,
                icon: Icon(
                  _step == 3 ? Icons.sports_cricket : Icons.arrow_forward,
                ),
                label: Text(_step == 3 ? 'Start Match' : 'Continue'),
              ),
            ),
            if (_step > 0) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: details.onStepCancel,
                child: const Text('Back'),
              ),
            ],
          ],
        ),
      ),
      steps: [
        Step(
          title: const Text('Team A Setup'),
          subtitle: Text(
            _teamAConfigured ? _teamA.text : 'Add team and players',
          ),
          isActive: _step >= 0,
          state: _teamAConfigured ? StepState.complete : StepState.indexed,
          content: _TeamRosterCard(
            teamLabel: 'Team A',
            teamName: _teamA.text,
            configured: _teamAConfigured,
            onPressed: () =>
                _openRoster(team: _teamA, players: _playersA, isTeamA: true),
          ),
        ),
        Step(
          title: const Text('Team B Setup'),
          subtitle: Text(
            _teamBConfigured ? _teamB.text : 'Add team and players',
          ),
          isActive: _step >= 1,
          state: _teamBConfigured ? StepState.complete : StepState.indexed,
          content: _TeamRosterCard(
            teamLabel: 'Team B',
            teamName: _teamB.text,
            configured: _teamBConfigured,
            onPressed: () =>
                _openRoster(team: _teamB, players: _playersB, isTeamA: false),
          ),
        ),
        Step(
          title: const Text('Batting First'),
          isActive: _step >= 2,
          content: RadioGroup<String>(
            groupValue: _batting,
            onChanged: (value) => setState(() => _batting = value ?? 'A'),
            child: Column(
              children: [
                RadioListTile(
                  value: 'A',
                  title: Text(_teamA.text),
                  secondary: const Icon(Icons.sports_cricket),
                ),
                RadioListTile(
                  value: 'B',
                  title: Text(_teamB.text),
                  secondary: const Icon(Icons.sports_cricket),
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Match Overs'),
          isActive: _step >= 3,
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 5, 10, 20, 50]
                .map(
                  (overs) => ChoiceChip(
                    label: Text('$overs Overs'),
                    selected: _overs == overs,
                    onSelected: (_) => setState(() => _overs = overs),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

class _TeamRosterCard extends StatelessWidget {
  const _TeamRosterCard({
    required this.teamLabel,
    required this.teamName,
    required this.configured,
    required this.onPressed,
  });

  final String teamLabel;
  final String teamName;
  final bool configured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.groups_rounded,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            configured ? teamName : '$teamLabel Playing XI',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            configured
                ? '11 players ready'
                : 'Add the team name and confirm all 11 players.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(configured ? Icons.edit : Icons.group_add),
              label: Text(configured ? 'Edit Players' : 'Add Players'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RosterDialog extends StatefulWidget {
  const _RosterDialog({required this.team, required this.players});

  final TextEditingController team;
  final List<TextEditingController> players;

  @override
  State<_RosterDialog> createState() => _RosterDialogState();
}

class _RosterDialogState extends State<_RosterDialog> {
  final SpeechToText _speech = SpeechToText();
  int? _editingIndex;
  int? _listeningIndex;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listeningIndex = null);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listeningIndex = null);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening(int index) async {
    if (_speech.isListening) {
      await _speech.stop();
      if (_listeningIndex == index) return;
    }
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone speech recognition is unavailable.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _editingIndex = index;
      _listeningIndex = index;
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (result) {
        widget.players[index].text = result.recognizedWords;
        widget.players[index].selection = TextSelection.collapsed(
          offset: widget.players[index].text.length,
        );
        if (mounted) setState(() {});
      },
    );
  }

  bool get _isValid =>
      widget.team.text.trim().isNotEmpty &&
      widget.players.every((player) => player.text.trim().isNotEmpty);

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close),
        ),
        title: const Text('Team Playing XI'),
        actions: [
          TextButton(
            onPressed: _isValid
                ? () {
                    _speech.stop();
                    Navigator.pop(context, true);
                  }
                : null,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: widget.team,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Team name',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  '11 Players',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.mic_none, size: 18),
                const SizedBox(width: 4),
                const Text('Tap mic to speak'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: widget.players.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final editing = _editingIndex == index;
                final listening = _listeningIndex == index;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 18, child: Text('${index + 1}')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: editing
                              ? TextField(
                                  controller: widget.players[index],
                                  autofocus: !listening,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) =>
                                      setState(() => _editingIndex = null),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Player name',
                                  ),
                                )
                              : Text(
                                  widget.players[index].text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        IconButton(
                          tooltip: editing ? 'Done editing' : 'Edit player',
                          onPressed: () => setState(
                            () => _editingIndex = editing ? null : index,
                          ),
                          icon: Icon(editing ? Icons.check : Icons.edit),
                        ),
                        IconButton.filledTonal(
                          tooltip: listening ? 'Stop listening' : 'Speak name',
                          onPressed: () => _toggleListening(index),
                          style: IconButton.styleFrom(
                            backgroundColor: listening
                                ? Theme.of(context).colorScheme.error
                                : null,
                            foregroundColor: listening ? Colors.white : null,
                          ),
                          icon: Icon(listening ? Icons.mic : Icons.mic_none),
                        ),
                      ],
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
