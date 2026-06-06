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

  test('match completes when over limit is reached', () {
    var result = match().copyWith(totalOvers: 1);
    for (var i = 0; i < 6; i++) {
      result = engine.recordBall(result, runs: 0);
    }

    expect(result.status, MatchStatus.completed);
  });
}
