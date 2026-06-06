import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';

class MatchEngine {
  const MatchEngine();

  MatchModel recordBall(
    MatchModel match, {
    required int runs,
    BallType ballType = BallType.normal,
    WicketType wicketType = WicketType.none,
    String? dismissedBatsmanId,
    String? nextBatsmanId,
    String? ballId,
    DateTime? timestamp,
  }) {
    if (match.status == MatchStatus.completed) {
      throw StateError('Cannot score a completed match.');
    }
    if (runs < 0) throw ArgumentError.value(runs, 'runs');

    final isLegal = ballType == BallType.normal;
    final extraRuns = ballType == BallType.wide || ballType == BallType.noBall
        ? 1
        : 0;
    final batRuns = ballType == BallType.normal || ballType == BallType.noBall
        ? runs
        : 0;
    final ball = BallModel(
      id: ballId ?? '${match.id}-${match.ballHistory.length + 1}',
      overNumber: match.legalBalls ~/ 6,
      ballNumber: isLegal ? (match.legalBalls % 6) + 1 : match.legalBalls % 6,
      runs: batRuns,
      extraRuns: extraRuns,
      ballType: ballType,
      wicketType: wicketType,
      batsmanId: match.strikerId,
      bowlerId: match.currentBowlerId,
      isLegalBall: isLegal,
      timestamp: timestamp ?? DateTime.now(),
      dismissedBatsmanId: wicketType == WicketType.none
          ? null
          : dismissedBatsmanId ?? match.strikerId,
    );

    var batting = match.battingTeam;
    var bowling = match.bowlingTeam;
    final battingPlayers = [...batting.players];
    final bowlingPlayers = [...bowling.players];
    final strikerIndex = battingPlayers.indexWhere(
      (player) => player.id == match.strikerId,
    );
    final bowlerIndex = bowlingPlayers.indexWhere(
      (player) => player.id == match.currentBowlerId,
    );

    if (strikerIndex < 0 || bowlerIndex < 0) {
      throw StateError(
        'Selected striker or bowler is not in the active teams.',
      );
    }

    battingPlayers[strikerIndex] = battingPlayers[strikerIndex].copyWith(
      runs: battingPlayers[strikerIndex].runs + batRuns,
      ballsFaced: battingPlayers[strikerIndex].ballsFaced + (isLegal ? 1 : 0),
      fours: battingPlayers[strikerIndex].fours + (batRuns == 4 ? 1 : 0),
      sixes: battingPlayers[strikerIndex].sixes + (batRuns == 6 ? 1 : 0),
    );

    final bowlerWicket =
        wicketType == WicketType.bowled ||
        wicketType == WicketType.caught ||
        wicketType == WicketType.lbw;
    bowlingPlayers[bowlerIndex] = bowlingPlayers[bowlerIndex].copyWith(
      ballsBowled: bowlingPlayers[bowlerIndex].ballsBowled + (isLegal ? 1 : 0),
      runsConceded:
          bowlingPlayers[bowlerIndex].runsConceded + batRuns + extraRuns,
      wickets: bowlingPlayers[bowlerIndex].wickets + (bowlerWicket ? 1 : 0),
    );

    var wickets = match.currentWickets;
    var strikerId = match.strikerId;
    var nonStrikerId = match.nonStrikerId;
    if (wicketType != WicketType.none) {
      final dismissedId = dismissedBatsmanId ?? match.strikerId;
      final dismissedIndex = battingPlayers.indexWhere(
        (player) => player.id == dismissedId,
      );
      if (dismissedIndex >= 0) {
        battingPlayers[dismissedIndex] = battingPlayers[dismissedIndex]
            .copyWith(isOut: true, outType: wicketType);
      }
      wickets++;
      if (nextBatsmanId != null) {
        if (dismissedId == nonStrikerId) {
          nonStrikerId = nextBatsmanId;
        } else {
          strikerId = nextBatsmanId;
        }
      }
    } else if (batRuns.isOdd) {
      (strikerId, nonStrikerId) = (nonStrikerId, strikerId);
    }

    final legalBalls = match.legalBalls + (isLegal ? 1 : 0);
    if (isLegal && legalBalls % 6 == 0) {
      (strikerId, nonStrikerId) = (nonStrikerId, strikerId);
    }

    final total = batRuns + extraRuns;
    batting = batting.copyWith(
      players: battingPlayers,
      totalRuns: batting.totalRuns + total,
      wickets: wickets,
      extras: batting.extras + extraRuns,
    );
    bowling = bowling.copyWith(players: bowlingPlayers);
    final completed =
        legalBalls >= match.totalOvers * 6 || wickets >= match.maxWickets;
    final updated = match.copyWith(
      teamA: match.teamA.id == batting.id ? batting : bowling,
      teamB: match.teamB.id == batting.id ? batting : bowling,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      currentRuns: match.currentRuns + total,
      currentWickets: wickets,
      legalBalls: legalBalls,
      ballHistory: [...match.ballHistory, ball],
      updatedAt: timestamp ?? DateTime.now(),
      status: completed ? MatchStatus.completed : MatchStatus.live,
      syncStatus: SyncStatus.pending,
      result: completed
          ? '${batting.name} finished ${match.currentRuns + total}/$wickets'
          : match.result,
    );
    return updated;
  }

  MatchModel changeBowler(MatchModel match, String bowlerId) {
    if (!match.bowlingTeam.players.any((player) => player.id == bowlerId)) {
      throw ArgumentError('Bowler must belong to the bowling team.');
    }
    return match.copyWith(
      currentBowlerId: bowlerId,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
  }

  MatchModel endMatch(MatchModel match) => match.copyWith(
    status: MatchStatus.completed,
    updatedAt: DateTime.now(),
    syncStatus: SyncStatus.pending,
    result:
        match.result ??
        '${match.battingTeam.name} finished ${match.currentRuns}/${match.currentWickets}',
  );

  MatchModel undo(MatchModel match) {
    if (match.ballHistory.isEmpty) return match;
    final seed = match.copyWith(
      teamA: _resetTeam(match.teamA),
      teamB: _resetTeam(match.teamB),
      currentRuns: 0,
      currentWickets: 0,
      legalBalls: 0,
      ballHistory: const [],
      strikerId: match.battingTeam.players[0].id,
      nonStrikerId: match.battingTeam.players[1].id,
      status: MatchStatus.live,
      result: null,
    );
    var rebuilt = seed;
    for (final ball in match.ballHistory.take(match.ballHistory.length - 1)) {
      final next = ball.isWicket
          ? match.battingTeam.players
                .where(
                  (p) =>
                      !p.isOut &&
                      p.id != rebuilt.strikerId &&
                      p.id != rebuilt.nonStrikerId,
                )
                .map((p) => p.id)
                .firstOrNull
          : null;
      rebuilt = recordBall(
        rebuilt,
        runs: ball.runs,
        ballType: ball.ballType,
        wicketType: ball.wicketType,
        dismissedBatsmanId: ball.dismissedBatsmanId,
        nextBatsmanId: next,
        ballId: ball.id,
        timestamp: ball.timestamp,
      );
    }
    return rebuilt.copyWith(updatedAt: DateTime.now());
  }

  TeamModel _resetTeam(TeamModel team) => team.copyWith(
    totalRuns: 0,
    wickets: 0,
    extras: 0,
    players: team.players
        .map((p) => PlayerModel(id: p.id, name: p.name))
        .toList(),
  );
}
