import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';
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
  final _customOvers = TextEditingController();
  bool _customOversSelected = false;
  int? _strikerIndex;
  int? _nonStrikerIndex;
  int? _bowlerIndex;
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
    _customOvers.dispose();
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
      3 => !_customOversSelected || (int.tryParse(_customOvers.text) ?? 0) > 0,
      _ =>
        _strikerIndex != null &&
            _nonStrikerIndex != null &&
            _bowlerIndex != null,
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
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _start();
    }
  }

  List<TextEditingController> get _battingPlayers =>
      _batting == 'A' ? _playersA : _playersB;
  List<TextEditingController> get _bowlingPlayers =>
      _batting == 'A' ? _playersB : _playersA;

  Future<void> _selectBatters() async {
    final selected = await showDialog<List<int>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: _BatterSelectionDialog(
          players: _battingPlayers,
          strikerIndex: _strikerIndex,
          nonStrikerIndex: _nonStrikerIndex,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _strikerIndex = selected[0];
        _nonStrikerIndex = selected[1];
      });
    }
  }

  Future<void> _selectBowler() async {
    final selected = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: _PlayerSelectionDialog(
          title: 'Select Opening Bowler',
          players: _bowlingPlayers,
          selectedIndex: _bowlerIndex,
          icon: Icons.sports_baseball,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _bowlerIndex = selected);
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
    final matchId = uuid.v4();
    final match = MatchModel(
      id: matchId,
      matchCode: matchId.replaceAll('-', '').substring(0, 6).toUpperCase(),
      teamA: a,
      teamB: b,
      battingTeamId: batting.id,
      bowlingTeamId: bowling.id,
      strikerId: batting.players[_strikerIndex!].id,
      nonStrikerId: batting.players[_nonStrikerIndex!].id,
      currentBowlerId: bowling.players[_bowlerIndex!].id,
      totalOvers: _overs,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(currentMatchProvider.notifier).start(match);
    if (mounted) context.go('/live');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('startMatch'))),
    body: ResponsiveContent(
      child: Stepper(
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
                    _step == 4 ? Icons.sports_cricket : Icons.arrow_forward,
                  ),
                  label: Text(
                    _step == 4
                        ? context.tr('startMatch')
                        : context.tr('continue'),
                  ),
                ),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(context.tr('back')),
                ),
              ],
            ],
          ),
        ),
        steps: [
          Step(
            title: Text(context.tr('teamASetup')),
            subtitle: Text(
              _teamAConfigured ? _teamA.text : context.tr('addTeamPlayers'),
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
            title: Text(context.tr('teamBSetup')),
            subtitle: Text(
              _teamBConfigured ? _teamB.text : context.tr('addTeamPlayers'),
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
            title: Text(context.tr('battingFirst')),
            isActive: _step >= 2,
            content: RadioGroup<String>(
              groupValue: _batting,
              onChanged: (value) => setState(() {
                _batting = value ?? 'A';
                _strikerIndex = null;
                _nonStrikerIndex = null;
                _bowlerIndex = null;
              }),
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
            title: Text(context.tr('matchOvers')),
            isActive: _step >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 2, 5, 10, 20, 50]
                      .map(
                        (overs) => ChoiceChip(
                          label: Text('$overs Overs'),
                          selected: !_customOversSelected && _overs == overs,
                          onSelected: (_) => setState(() {
                            _customOversSelected = false;
                            _overs = overs;
                            _customOvers.clear();
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _customOvers,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr('customOvers'),
                    hintText: 'Enter overs',
                    prefixIcon: const Icon(Icons.edit_note),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    setState(() {
                      _customOversSelected = value.isNotEmpty;
                      if (parsed != null && parsed > 0) _overs = parsed;
                    });
                  },
                ),
              ],
            ),
          ),
          Step(
            title: Text(context.tr('openingPlayers')),
            subtitle: Text(context.tr('chooseBattersBowler')),
            isActive: _step >= 4,
            content: Column(
              children: [
                _OpeningSelectionCard(
                  title: context.tr('openingBatters'),
                  subtitle: _strikerIndex == null
                      ? context.tr('selectStrikerPartner')
                      : '${_battingPlayers[_strikerIndex!].text}  •  '
                            '${_battingPlayers[_nonStrikerIndex!].text}',
                  icon: Icons.sports_cricket,
                  complete: _strikerIndex != null,
                  buttonLabel: _strikerIndex == null
                      ? context.tr('addBatters')
                      : context.tr('editBatters'),
                  onPressed: _selectBatters,
                ),
                const SizedBox(height: 12),
                _OpeningSelectionCard(
                  title: context.tr('openingBowler'),
                  subtitle: _bowlerIndex == null
                      ? context.tr('selectCurrentBowler')
                      : _bowlingPlayers[_bowlerIndex!].text,
                  icon: Icons.sports_baseball,
                  complete: _bowlerIndex != null,
                  buttonLabel: _bowlerIndex == null
                      ? context.tr('addBowler')
                      : context.tr('editBowler'),
                  onPressed: _selectBowler,
                ),
              ],
            ),
          ),
        ],
      ),
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
              label: Text(
                configured
                    ? context.tr('editPlayers')
                    : context.tr('addPlayers'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OpeningSelectionCard extends StatelessWidget {
  const _OpeningSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.complete,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool complete;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
    color: complete
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle),
              ],
            ),
          ),
          FilledButton.tonal(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    ),
  );
}

class _BatterSelectionDialog extends StatefulWidget {
  const _BatterSelectionDialog({
    required this.players,
    this.strikerIndex,
    this.nonStrikerIndex,
  });

  final List<TextEditingController> players;
  final int? strikerIndex;
  final int? nonStrikerIndex;

  @override
  State<_BatterSelectionDialog> createState() => _BatterSelectionDialogState();
}

class _BatterSelectionDialogState extends State<_BatterSelectionDialog> {
  int? striker;
  int? nonStriker;
  late String selectedRole;

  @override
  void initState() {
    super.initState();
    striker = widget.strikerIndex;
    nonStriker = widget.nonStrikerIndex;
    selectedRole = striker == null ? 'striker' : 'nonStriker';
  }

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
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                final isStriker = striker == index;
                final isNonStriker = nonStriker == index;
                final blocked = selectedRole == 'striker'
                    ? isNonStriker
                    : isStriker;
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
                    title: Text(widget.players[index].text),
                    subtitle: Text(
                      isStriker
                          ? context.tr('striker')
                          : isNonStriker
                          ? context.tr('nonStriker')
                          : blocked
                          ? context.tr('unavailable')
                          : context.tr('available'),
                    ),
                    trailing: isStriker || isNonStriker
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.touch_app_outlined),
                    onTap: blocked
                        ? null
                        : () => setState(() {
                            if (selectedRole == 'striker') {
                              striker = index;
                              selectedRole = 'nonStriker';
                            } else {
                              nonStriker = index;
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
        onPressed: striker != null && nonStriker != null
            ? () => Navigator.pop(context, [striker!, nonStriker!])
            : null,
        icon: const Icon(Icons.check),
        label: Text(context.tr('confirm')),
      ),
    ],
  );
}

class _PlayerSelectionDialog extends StatelessWidget {
  const _PlayerSelectionDialog({
    required this.title,
    required this.players,
    required this.icon,
    this.selectedIndex,
  });

  final String title;
  final List<TextEditingController> players;
  final IconData icon;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: players.length,
        itemBuilder: (context, index) => Card(
          color: selectedIndex == index
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: Icon(icon),
            title: Text(players[index].text),
            trailing: selectedIndex == index
                ? const Icon(Icons.check_circle)
                : null,
            onTap: () => Navigator.pop(context, index),
          ),
        ),
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

  void _editPlayer(int index) {
    setState(() => _editingIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = widget.players[index];
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

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
        title: Text(context.tr('players11')),
        actions: [
          TextButton(
            onPressed: _isValid
                ? () {
                    _speech.stop();
                    Navigator.pop(context, true);
                  }
                : null,
            child: Text(context.tr('save').toUpperCase()),
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
              decoration: InputDecoration(
                labelText: context.tr('teamName'),
                prefixIcon: const Icon(Icons.shield_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  context.tr('players11'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.mic_none, size: 18),
                const SizedBox(width: 4),
                Text(context.tr('tapMic')),
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
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: context.tr('playerName'),
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
                          onPressed: () {
                            if (editing) {
                              setState(() => _editingIndex = null);
                            } else {
                              _editPlayer(index);
                            }
                          },
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
