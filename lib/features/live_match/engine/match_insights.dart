import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';

class MatchInsights {
  const MatchInsights();

  String forMatch(MatchModel match) {
    if (match.ballHistory.length < 6) {
      return 'The innings is settling in. Build a partnership.';
    }
    final lastSix = match.ballHistory.reversed.take(6).toList();
    final runs = lastSix.fold<int>(0, (sum, ball) => sum + ball.totalRuns);
    if (lastSix.where((ball) => ball.isWicket).length >= 2) {
      return 'Wickets are falling quickly. Rotate the strike and rebuild.';
    }
    if (runs <= 3) return 'Run rate is slowing. Look for safe scoring options.';
    if (runs >= 12) return 'Momentum is with the batting side.';
    if (match.currentWickets == 0 && match.legalBalls >= 12) {
      return 'Partnership building nicely.';
    }
    final bowler = match.bowlingTeam.players
        .where((player) => player.id == match.currentBowlerId)
        .first;
    if (bowler.ballsBowled >= 6 && bowler.economy < 5) {
      return '${bowler.name} is bowling an economical spell.';
    }
    return 'Keep rotating strike and target one boundary each over.';
  }
}
