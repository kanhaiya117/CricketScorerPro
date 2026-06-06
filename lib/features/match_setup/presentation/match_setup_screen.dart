import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  final _teamA = TextEditingController(text: 'Team A');
  final _teamB = TextEditingController(text: 'Team B');
  final _playersA = [TextEditingController(), TextEditingController()];
  final _playersB = [TextEditingController(), TextEditingController()];
  int _step = 0;
  int _overs = 5;
  String _batting = 'A';

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
  ) {
    return team.text.trim().isNotEmpty &&
        players.length >= 2 &&
        players.every((p) => p.text.trim().isNotEmpty);
  }

  void _continue() {
    final valid = switch (_step) {
      0 => _validTeam(_teamA, _playersA),
      1 => _validTeam(_teamB, _playersB),
      2 => _batting.isNotEmpty,
      _ => _overs > 0,
    };
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields before continuing.')),
      );
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _start();
    }
  }

  Future<void> _start() async {
    const uuid = Uuid();
    TeamModel buildTeam(String name, List<TextEditingController> controllers) {
      return TeamModel(
        id: uuid.v4(),
        name: name.trim(),
        players: controllers
            .map((p) => PlayerModel(id: uuid.v4(), name: p.text.trim()))
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
    appBar: AppBar(title: const Text('New Match')),
    body: Stepper(
      currentStep: _step,
      onStepTapped: (value) => setState(() => _step = value),
      onStepContinue: _continue,
      onStepCancel: _step == 0 ? null : () => setState(() => _step--),
      controlsBuilder: (context, details) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Row(
          children: [
            FilledButton(
              onPressed: details.onStepContinue,
              child: Text(_step == 3 ? 'Start Match' : 'Continue'),
            ),
            if (_step > 0)
              TextButton(
                onPressed: details.onStepCancel,
                child: const Text('Back'),
              ),
          ],
        ),
      ),
      steps: [
        Step(
          title: const Text('Team A'),
          isActive: _step >= 0,
          content: _TeamEditor(
            team: _teamA,
            players: _playersA,
            onChanged: () => setState(() {}),
          ),
        ),
        Step(
          title: const Text('Team B'),
          isActive: _step >= 1,
          content: _TeamEditor(
            team: _teamB,
            players: _playersB,
            onChanged: () => setState(() {}),
          ),
        ),
        Step(
          title: const Text('Batting first'),
          isActive: _step >= 2,
          content: RadioGroup<String>(
            groupValue: _batting,
            onChanged: (value) => setState(() => _batting = value ?? 'A'),
            child: Column(
              children: [
                RadioListTile(value: 'A', title: Text(_teamA.text)),
                RadioListTile(value: 'B', title: Text(_teamB.text)),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Overs'),
          isActive: _step >= 3,
          content: Wrap(
            spacing: 8,
            children: [1, 2, 5, 10, 20, 50]
                .map(
                  (overs) => ChoiceChip(
                    label: Text('$overs'),
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

class _TeamEditor extends StatelessWidget {
  const _TeamEditor({
    required this.team,
    required this.players,
    required this.onChanged,
  });
  final TextEditingController team;
  final List<TextEditingController> players;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        controller: team,
        decoration: const InputDecoration(labelText: 'Team name'),
      ),
      const SizedBox(height: 12),
      ...List.generate(
        players.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: players[index],
            decoration: InputDecoration(
              labelText: 'Player ${index + 1}',
              suffixIcon: players.length > 2
                  ? IconButton(
                      onPressed: () {
                        players.removeAt(index).dispose();
                        onChanged();
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    )
                  : null,
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            players.add(TextEditingController());
            onChanged();
          },
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add player'),
        ),
      ),
    ],
  );
}
