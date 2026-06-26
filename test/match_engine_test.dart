import 'package:cricket_scorer_pro/features/live_match/engine/match_engine.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = MatchEngine();

  MatchModel match() {
    const batting = TeamModel(
      id: 'bat',
      name: 'Batting',
      players: [
        PlayerModel(id: 'b1', name: 'One'),
        PlayerModel(id: 'b2', name: 'Two'),
        PlayerModel(id: 'b3', name: 'Three'),
      ],
    );
    const bowling = TeamModel(
      id: 'bowl',
      name: 'Bowling',
      players: [
        PlayerModel(id: 'p1', name: 'Bowler One'),
        PlayerModel(id: 'p2', name: 'Bowler Two'),
      ],
    );
    final now = DateTime(2026);
    return MatchModel(
      id: 'match',
      teamA: batting,
      teamB: bowling,
      battingTeamId: batting.id,
      bowlingTeamId: bowling.id,
      strikerId: 'b1',
      nonStrikerId: 'b2',
      currentBowlerId: 'p1',
      totalOvers: 2,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('legal ball increments ball count and batter statistics', () {
    final result = engine.recordBall(match(), runs: 4);

    expect(result.legalBalls, 1);
    expect(result.currentRuns, 4);
    expect(result.overs, '0.1');
    expect(result.battingTeam.players.first.runs, 4);
    expect(result.battingTeam.players.first.fours, 1);
    expect(result.battingTeam.players.first.ballsFaced, 1);
  });

  test('wide and no ball add one but do not count legal balls', () {
    var result = engine.recordBall(match(), runs: 0, ballType: BallType.wide);
    result = engine.recordBall(result, runs: 0, ballType: BallType.noBall);

    expect(result.currentRuns, 2);
    expect(result.battingTeam.extras, 2);
    expect(result.legalBalls, 0);
    expect(result.bowlingTeam.players.first.runsConceded, 2);
  });

  test('wide boundary adds five wides without a legal ball', () {
    final result = engine.recordBall(match(), runs: 4, ballType: BallType.wide);

    expect(result.currentRuns, 5);
    expect(result.battingTeam.extras, 5);
    expect(result.battingTeam.wideExtras, 5);
    expect(result.battingTeam.players.first.runs, 0);
    expect(result.legalBalls, 0);
    expect(result.bowlingTeam.players.first.runsConceded, 5);
  });

  test('no ball boundary credits batter and no ball extra', () {
    final result = engine.recordBall(
      match(),
      runs: 4,
      ballType: BallType.noBall,
    );

    expect(result.currentRuns, 5);
    expect(result.battingTeam.extras, 1);
    expect(result.battingTeam.noBallExtras, 1);
    expect(result.battingTeam.players.first.runs, 4);
    expect(result.battingTeam.players.first.fours, 1);
    expect(result.battingTeam.players.first.ballsFaced, 0);
    expect(result.legalBalls, 0);
    expect(result.bowlingTeam.players.first.runsConceded, 5);
  });

  test('leg bye adds extras and legal ball but does not charge bowler', () {
    final result = engine.recordBall(
      match(),
      runs: 3,
      ballType: BallType.legBye,
    );

    expect(result.currentRuns, 3);
    expect(result.battingTeam.extras, 3);
    expect(result.battingTeam.legByeExtras, 3);
    expect(result.battingTeam.players.first.runs, 0);
    expect(result.battingTeam.players.first.ballsFaced, 1);
    expect(result.legalBalls, 1);
    expect(result.strikerId, 'b2');
    expect(result.bowlingTeam.players.first.runsConceded, 0);
  });

  test('undo restores advanced extra and player statistics', () {
    final before = match();
    var result = engine.recordBall(before, runs: 4, ballType: BallType.noBall);
    result = engine.undo(result);

    expect(result.currentRuns, before.currentRuns);
    expect(result.legalBalls, before.legalBalls);
    expect(result.strikerId, before.strikerId);
    expect(result.battingTeam.extras, 0);
    expect(result.battingTeam.noBallExtras, 0);
    expect(result.battingTeam.players.first.runs, 0);
    expect(result.battingTeam.players.first.fours, 0);
    expect(result.bowlingTeam.players.first.runsConceded, 0);
    expect(result.ballHistory, isEmpty);
  });

  test('undo first innings final ball clears innings snapshot and target', () {
    var result = match().copyWith(totalOvers: 1);
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }
    expect(result.status, MatchStatus.inningsBreak);
    expect(result.target, 1);

    result = engine.undo(result);

    expect(result.status, MatchStatus.live);
    expect(result.overs, '0.5');
    expect(result.firstInningsRuns, isNull);
    expect(result.target, isNull);
  });

  test('odd run rotates strike', () {
    final result = engine.recordBall(match(), runs: 1);

    expect(result.strikerId, 'b2');
    expect(result.nonStrikerId, 'b1');
  });

  test('six legal balls complete over and swap strike', () {
    var result = match();
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }

    expect(result.legalBalls, 6);
    expect(result.overs, '1.0');
    expect(result.overComplete, isTrue);
    expect(result.strikerId, 'b2');
  });

  test('bowled wicket credits bowler and brings next batter', () {
    final result = engine.recordBall(
      match(),
      runs: 0,
      wicketType: WicketType.bowled,
      dismissedBatsmanId: 'b1',
      nextBatsmanId: 'b3',
    );

    expect(result.currentWickets, 1);
    expect(result.strikerId, 'b3');
    expect(result.battingTeam.players.first.isOut, isTrue);
    expect(result.bowlingTeam.players.first.wickets, 1);
  });

  test('run out does not credit bowler', () {
    final result = engine.recordBall(
      match(),
      runs: 0,
      wicketType: WicketType.runOut,
      dismissedBatsmanId: 'b1',
      nextBatsmanId: 'b3',
    );

    expect(result.currentWickets, 1);
    expect(result.bowlingTeam.players.first.wickets, 0);
  });

  test('first innings moves to innings break at over limit', () {
    var result = match().copyWith(totalOvers: 1);
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }

    expect(result.status, MatchStatus.inningsBreak);
    expect(result.target, 1);
  });

  test('odd run on final ball swaps twice and keeps original striker', () {
    var result = match();
    for (var i = 0; i < 5; i++) {
      result = engine.recordBall(result, runs: 0);
    }
    result = engine.recordBall(result, runs: 1);

    expect(result.strikerId, 'b1');
    expect(result.nonStrikerId, 'b2');
  });

  test('second innings completes when target is chased', () {
    var result = match().copyWith(totalOvers: 1);
    result = engine.recordBall(result, runs: 4);
    for (var i = 0; i < 5; i++) {
      result = engine.recordBall(result, runs: 0);
    }
    result = engine.startSecondInnings(
      result,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
    );
    result = engine.recordBall(result, runs: 6);

    expect(result.status, MatchStatus.completed);
    expect(result.result, contains('won by'));
  });

  test('caught dismissal records catcher and bowler', () {
    final result = engine.recordBall(
      match(),
      runs: 0,
      wicketType: WicketType.caught,
      dismissedBatsmanId: 'b1',
      nextBatsmanId: 'b3',
      fielderId: 'p2',
    );

    expect(
      result.battingTeam.players.first.dismissalText,
      'c Bowler Two b Bowler One',
    );
  });

  test('previous over bowler cannot continue', () {
    var result = match();
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }

    expect(() => engine.changeBowler(result, 'p1'), throwsArgumentError);
  });

  test('bowler can change multiple times before next over starts', () {
    var result = match();
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }

    result = engine.changeBowler(result, 'p2');
    result = engine.changeBowler(result, 'p2');

    expect(result.currentBowlerId, 'p2');
    expect(result.previousBowlerId, 'p1');
  });

  test('bowler cannot change after next over starts', () {
    var result = match();
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }
    result = engine.changeBowler(result, 'p2');
    result = engine.recordBall(result, runs: 0);

    expect(() => engine.changeBowler(result, 'p1'), throwsStateError);
  });

  test('undo across over boundary restores the ball bowler', () {
    var result = match().copyWith(totalOvers: 3);
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }
    result = engine.changeBowler(result, 'p2');
    result = engine.recordBall(result, runs: 1);

    result = engine.undo(result);
    expect(result.overs, '1.0');
    expect(result.currentBowlerId, 'p2');
    expect(result.overComplete, isTrue);

    result = engine.undo(result);
    expect(result.overs, '0.5');
    expect(result.currentBowlerId, 'p1');
    expect(result.overComplete, isFalse);
  });

  test('older saved match JSON loads without new innings fields', () {
    final json = match().toJson()
      ..remove('firstInningsBattingTeamId')
      ..remove('firstInningsRuns')
      ..remove('firstInningsWickets')
      ..remove('firstInningsLegalBalls')
      ..remove('previousBowlerId');

    final restored = MatchModel.fromJson(json);

    expect(restored.innings, 1);
    expect(restored.firstInningsRuns, isNull);
    expect(restored.status, MatchStatus.live);
    expect(restored.publicCode.length, 6);
  });
}
