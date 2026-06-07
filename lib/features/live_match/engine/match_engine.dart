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
    String? fielderId,
    String? ballId,
    DateTime? timestamp,
  }) {
    if (match.status != MatchStatus.live) {
      throw StateError('The match is not ready for scoring.');
    }
    if (runs < 0) throw ArgumentError.value(runs, 'runs');

    final isLegal = ballType == BallType.normal;
    final extraRuns = ballType == BallType.wide || ballType == BallType.noBall
        ? 1
        : 0;
    final batRuns = ballType == BallType.normal || ballType == BallType.noBall
        ? runs
        : 0;
    final dismissedId = wicketType == WicketType.none
        ? null
        : dismissedBatsmanId ?? match.strikerId;
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
      dismissedBatsmanId: dismissedId,
      fielderId: fielderId,
      innings: match.innings,
      previousStrikerId: match.strikerId,
      previousNonStrikerId: match.nonStrikerId,
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
      throw StateError('The selected striker or bowler is unavailable.');
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
    if (wicketType != WicketType.none && dismissedId != null) {
      final dismissedIndex = battingPlayers.indexWhere(
        (player) => player.id == dismissedId,
      );
      if (dismissedIndex >= 0) {
        battingPlayers[dismissedIndex] = battingPlayers[dismissedIndex]
            .copyWith(
              isOut: true,
              outType: wicketType,
              dismissalText: _dismissalText(
                wicketType,
                bowling,
                match.currentBowlerId,
                fielderId,
              ),
            );
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
    final runsTotal = match.currentRuns + total;
    batting = batting.copyWith(
      players: battingPlayers,
      totalRuns: runsTotal,
      wickets: wickets,
      extras: batting.extras + extraRuns,
    );
    bowling = bowling.copyWith(players: bowlingPlayers);
    final inningsFinished =
        legalBalls >= match.totalOvers * 6 || wickets >= match.maxWickets;
    final chaseWon =
        match.innings == 2 &&
        match.target != null &&
        runsTotal >= match.target!;
    final matchFinished = match.innings == 2 && (inningsFinished || chaseWon);
    final status = matchFinished
        ? MatchStatus.completed
        : inningsFinished
        ? MatchStatus.inningsBreak
        : MatchStatus.live;

    return match.copyWith(
      teamA: match.teamA.id == batting.id ? batting : bowling,
      teamB: match.teamB.id == batting.id ? batting : bowling,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      currentRuns: runsTotal,
      currentWickets: wickets,
      legalBalls: legalBalls,
      ballHistory: [...match.ballHistory, ball],
      updatedAt: timestamp ?? DateTime.now(),
      status: status,
      syncStatus: SyncStatus.pending,
      firstInningsBattingTeamId: match.innings == 1 && inningsFinished
          ? batting.id
          : match.firstInningsBattingTeamId,
      firstInningsRuns: match.innings == 1 && inningsFinished
          ? runsTotal
          : match.firstInningsRuns,
      firstInningsWickets: match.innings == 1 && inningsFinished
          ? wickets
          : match.firstInningsWickets,
      firstInningsLegalBalls: match.innings == 1 && inningsFinished
          ? legalBalls
          : match.firstInningsLegalBalls,
      result: matchFinished
          ? _result(match, batting, runsTotal, wickets)
          : null,
    );
  }

  MatchModel startSecondInnings(
    MatchModel match, {
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) {
    if (match.status != MatchStatus.inningsBreak || match.innings != 1) {
      throw StateError('The first innings is not complete.');
    }
    final batting = match.bowlingTeam.copyWith(
      totalRuns: 0,
      wickets: 0,
      extras: 0,
    );
    final bowling = match.battingTeam;
    _validateOpeners(batting, strikerId, nonStrikerId);
    _validateBowler(bowling, bowlerId);
    return match.copyWith(
      teamA: match.teamA.id == batting.id ? batting : bowling,
      teamB: match.teamB.id == batting.id ? batting : bowling,
      battingTeamId: batting.id,
      bowlingTeamId: bowling.id,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      currentBowlerId: bowlerId,
      clearPreviousBowler: true,
      currentRuns: 0,
      currentWickets: 0,
      legalBalls: 0,
      innings: 2,
      status: MatchStatus.live,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      clearResult: true,
    );
  }

  MatchModel changeBowler(MatchModel match, String bowlerId) {
    _validateBowler(match.bowlingTeam, bowlerId);
    if (bowlerId == match.currentBowlerId && match.overComplete) {
      throw ArgumentError('The previous-over bowler cannot bowl again.');
    }
    return match.copyWith(
      previousBowlerId: match.currentBowlerId,
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
        'Match ended at ${match.battingTeam.name} '
            '${match.currentRuns}/${match.currentWickets}',
  );

  MatchModel undo(MatchModel match) {
    final currentBalls = match.ballHistory
        .where((ball) => ball.innings == match.innings)
        .toList();
    if (currentBalls.isEmpty) return match;
    final ball = currentBalls.last;
    var batting = match.battingTeam;
    var bowling = match.bowlingTeam;
    final battingPlayers = [...batting.players];
    final bowlingPlayers = [...bowling.players];
    final batterIndex = battingPlayers.indexWhere(
      (player) => player.id == ball.batsmanId,
    );
    final bowlerIndex = bowlingPlayers.indexWhere(
      (player) => player.id == ball.bowlerId,
    );
    if (batterIndex >= 0) {
      final player = battingPlayers[batterIndex];
      battingPlayers[batterIndex] = player.copyWith(
        runs: player.runs - ball.runs,
        ballsFaced: player.ballsFaced - (ball.isLegalBall ? 1 : 0),
        fours: player.fours - (ball.runs == 4 ? 1 : 0),
        sixes: player.sixes - (ball.runs == 6 ? 1 : 0),
      );
    }
    if (ball.dismissedBatsmanId != null) {
      final outIndex = battingPlayers.indexWhere(
        (player) => player.id == ball.dismissedBatsmanId,
      );
      if (outIndex >= 0) {
        final player = battingPlayers[outIndex];
        battingPlayers[outIndex] = PlayerModel(
          id: player.id,
          name: player.name,
          runs: player.runs,
          ballsFaced: player.ballsFaced,
          fours: player.fours,
          sixes: player.sixes,
          ballsBowled: player.ballsBowled,
          maidens: player.maidens,
          wickets: player.wickets,
          runsConceded: player.runsConceded,
        );
      }
    }
    if (bowlerIndex >= 0) {
      final bowler = bowlingPlayers[bowlerIndex];
      final credited =
          ball.wicketType == WicketType.bowled ||
          ball.wicketType == WicketType.caught ||
          ball.wicketType == WicketType.lbw;
      bowlingPlayers[bowlerIndex] = bowler.copyWith(
        ballsBowled: bowler.ballsBowled - (ball.isLegalBall ? 1 : 0),
        runsConceded: bowler.runsConceded - ball.totalRuns,
        wickets: bowler.wickets - (credited ? 1 : 0),
      );
    }
    batting = batting.copyWith(
      players: battingPlayers,
      totalRuns: batting.totalRuns - ball.totalRuns,
      wickets: batting.wickets - (ball.isWicket ? 1 : 0),
      extras: batting.extras - ball.extraRuns,
    );
    bowling = bowling.copyWith(players: bowlingPlayers);
    return match.copyWith(
      teamA: match.teamA.id == batting.id ? batting : bowling,
      teamB: match.teamB.id == batting.id ? batting : bowling,
      strikerId: ball.previousStrikerId ?? ball.batsmanId,
      nonStrikerId: ball.previousNonStrikerId ?? match.nonStrikerId,
      currentRuns: match.currentRuns - ball.totalRuns,
      currentWickets: match.currentWickets - (ball.isWicket ? 1 : 0),
      legalBalls: match.legalBalls - (ball.isLegalBall ? 1 : 0),
      ballHistory: match.ballHistory.sublist(0, match.ballHistory.length - 1),
      status: MatchStatus.live,
      clearResult: true,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
  }

  String _dismissalText(
    WicketType type,
    TeamModel bowling,
    String bowlerId,
    String? fielderId,
  ) {
    final bowler = bowling.players.firstWhere((p) => p.id == bowlerId).name;
    final fielder = fielderId == null
        ? null
        : bowling.players.firstWhere((p) => p.id == fielderId).name;
    return switch (type) {
      WicketType.bowled => 'b $bowler',
      WicketType.caught => 'c ${fielder ?? 'Unknown'} b $bowler',
      WicketType.lbw => 'lbw b $bowler',
      WicketType.runOut => 'run out (${fielder ?? 'Unknown'})',
      WicketType.none => 'not out',
    };
  }

  String _result(
    MatchModel before,
    TeamModel chasingTeam,
    int chasingRuns,
    int chasingWickets,
  ) {
    final target = before.target!;
    if (chasingRuns >= target) {
      final wicketsLeft = chasingTeam.players.length - 1 - chasingWickets;
      return '${chasingTeam.name} won by $wicketsLeft wickets';
    }
    if (chasingRuns == target - 1) return 'Match tied';
    final firstTeam = before.firstInningsBattingTeamId == before.teamA.id
        ? before.teamA
        : before.teamB;
    return '${firstTeam.name} won by ${target - 1 - chasingRuns} runs';
  }

  void _validateOpeners(TeamModel team, String striker, String nonStriker) {
    if (striker == nonStriker ||
        !team.players.any((p) => p.id == striker && !p.isOut) ||
        !team.players.any((p) => p.id == nonStriker && !p.isOut)) {
      throw ArgumentError('Select two available batting players.');
    }
  }

  void _validateBowler(TeamModel team, String id) {
    if (!team.players.any((player) => player.id == id)) {
      throw ArgumentError('Bowler must belong to the bowling team.');
    }
  }
}
