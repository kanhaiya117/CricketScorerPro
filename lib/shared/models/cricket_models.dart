import 'package:equatable/equatable.dart';

enum BallType { normal, wide, noBall, bye, legBye, deadBall }

enum WicketType { none, bowled, caught, lbw, runOut }

enum MatchStatus { setup, live, inningsBreak, completed }

enum SyncStatus { synced, pending, failed }

class PlayerModel extends Equatable {
  const PlayerModel({
    required this.id,
    required this.name,
    this.runs = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.outType = WicketType.none,
    this.ballsBowled = 0,
    this.maidens = 0,
    this.wickets = 0,
    this.runsConceded = 0,
    this.dismissalText,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    runs: json['runs'] as int? ?? 0,
    ballsFaced: json['ballsFaced'] as int? ?? 0,
    fours: json['fours'] as int? ?? 0,
    sixes: json['sixes'] as int? ?? 0,
    isOut: json['isOut'] as bool? ?? false,
    outType: WicketType.values.byName(
      json['outType'] as String? ?? WicketType.none.name,
    ),
    ballsBowled: json['ballsBowled'] as int? ?? 0,
    maidens: json['maidens'] as int? ?? 0,
    wickets: json['wickets'] as int? ?? 0,
    runsConceded: json['runsConceded'] as int? ?? 0,
    dismissalText: json['dismissalText'] as String?,
  );

  final String id;
  final String name;
  final int runs;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final bool isOut;
  final WicketType outType;
  final int ballsBowled;
  final int maidens;
  final int wickets;
  final int runsConceded;
  final String? dismissalText;

  double get strikeRate => ballsFaced == 0 ? 0 : runs * 100 / ballsFaced;
  String get overs => '${ballsBowled ~/ 6}.${ballsBowled % 6}';
  double get economy => ballsBowled == 0 ? 0 : runsConceded * 6 / ballsBowled;

  PlayerModel copyWith({
    String? id,
    String? name,
    int? runs,
    int? ballsFaced,
    int? fours,
    int? sixes,
    bool? isOut,
    WicketType? outType,
    int? ballsBowled,
    int? maidens,
    int? wickets,
    int? runsConceded,
    String? dismissalText,
  }) => PlayerModel(
    id: id ?? this.id,
    name: name ?? this.name,
    runs: runs ?? this.runs,
    ballsFaced: ballsFaced ?? this.ballsFaced,
    fours: fours ?? this.fours,
    sixes: sixes ?? this.sixes,
    isOut: isOut ?? this.isOut,
    outType: outType ?? this.outType,
    ballsBowled: ballsBowled ?? this.ballsBowled,
    maidens: maidens ?? this.maidens,
    wickets: wickets ?? this.wickets,
    runsConceded: runsConceded ?? this.runsConceded,
    dismissalText: dismissalText ?? this.dismissalText,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'runs': runs,
    'ballsFaced': ballsFaced,
    'fours': fours,
    'sixes': sixes,
    'strikeRate': strikeRate,
    'isOut': isOut,
    'outType': outType.name,
    'ballsBowled': ballsBowled,
    'overs': overs,
    'maidens': maidens,
    'wickets': wickets,
    'runsConceded': runsConceded,
    'economy': economy,
    'dismissalText': dismissalText,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    runs,
    ballsFaced,
    fours,
    sixes,
    isOut,
    outType,
    ballsBowled,
    maidens,
    wickets,
    runsConceded,
    dismissalText,
  ];
}

class TeamModel extends Equatable {
  const TeamModel({
    required this.id,
    required this.name,
    required this.players,
    this.totalRuns = 0,
    this.wickets = 0,
    this.extras = 0,
    this.wideExtras = 0,
    this.noBallExtras = 0,
    this.byeExtras = 0,
    this.legByeExtras = 0,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
    id: json['id'] as String,
    name: json['name'] as String,
    players: (json['players'] as List<dynamic>? ?? [])
        .map((e) => PlayerModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    totalRuns: json['totalRuns'] as int? ?? 0,
    wickets: json['wickets'] as int? ?? 0,
    extras: json['extras'] as int? ?? 0,
    wideExtras: json['wideExtras'] as int? ?? 0,
    noBallExtras: json['noBallExtras'] as int? ?? 0,
    byeExtras: json['byeExtras'] as int? ?? 0,
    legByeExtras: json['legByeExtras'] as int? ?? 0,
  );

  final String id;
  final String name;
  final List<PlayerModel> players;
  final int totalRuns;
  final int wickets;
  final int extras;
  final int wideExtras;
  final int noBallExtras;
  final int byeExtras;
  final int legByeExtras;

  TeamModel copyWith({
    String? id,
    String? name,
    List<PlayerModel>? players,
    int? totalRuns,
    int? wickets,
    int? extras,
    int? wideExtras,
    int? noBallExtras,
    int? byeExtras,
    int? legByeExtras,
  }) => TeamModel(
    id: id ?? this.id,
    name: name ?? this.name,
    players: players ?? this.players,
    totalRuns: totalRuns ?? this.totalRuns,
    wickets: wickets ?? this.wickets,
    extras: extras ?? this.extras,
    wideExtras: wideExtras ?? this.wideExtras,
    noBallExtras: noBallExtras ?? this.noBallExtras,
    byeExtras: byeExtras ?? this.byeExtras,
    legByeExtras: legByeExtras ?? this.legByeExtras,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'players': players.map((e) => e.toJson()).toList(),
    'totalRuns': totalRuns,
    'wickets': wickets,
    'extras': extras,
    'wideExtras': wideExtras,
    'noBallExtras': noBallExtras,
    'byeExtras': byeExtras,
    'legByeExtras': legByeExtras,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    players,
    totalRuns,
    wickets,
    extras,
    wideExtras,
    noBallExtras,
    byeExtras,
    legByeExtras,
  ];
}

class BallModel extends Equatable {
  const BallModel({
    required this.id,
    required this.overNumber,
    required this.ballNumber,
    required this.runs,
    required this.extraRuns,
    required this.ballType,
    required this.wicketType,
    required this.batsmanId,
    required this.bowlerId,
    required this.isLegalBall,
    required this.timestamp,
    this.dismissedBatsmanId,
    this.fielderId,
    this.innings = 1,
    this.previousStrikerId,
    this.previousNonStrikerId,
  });

  factory BallModel.fromJson(Map<String, dynamic> json) => BallModel(
    id: json['id'] as String,
    overNumber: json['overNumber'] as int,
    ballNumber: json['ballNumber'] as int,
    runs: json['runs'] as int,
    extraRuns: json['extraRuns'] as int? ?? 0,
    ballType: BallType.values.byName(json['ballType'] as String),
    wicketType: WicketType.values.byName(
      json['wicketType'] as String? ?? WicketType.none.name,
    ),
    batsmanId: json['batsmanId'] as String,
    bowlerId: json['bowlerId'] as String,
    isLegalBall: json['isLegalBall'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    dismissedBatsmanId: json['dismissedBatsmanId'] as String?,
    fielderId: json['fielderId'] as String?,
    innings: json['innings'] as int? ?? 1,
    previousStrikerId: json['previousStrikerId'] as String?,
    previousNonStrikerId: json['previousNonStrikerId'] as String?,
  );

  final String id;
  final int overNumber;
  final int ballNumber;
  final int runs;
  final int extraRuns;
  final BallType ballType;
  final WicketType wicketType;
  final String batsmanId;
  final String bowlerId;
  final bool isLegalBall;
  final DateTime timestamp;
  final String? dismissedBatsmanId;
  final String? fielderId;
  final int innings;
  final String? previousStrikerId;
  final String? previousNonStrikerId;

  int get totalRuns => runs + extraRuns;
  bool get isWicket => wicketType != WicketType.none;
  int get bowlerRunsConceded => switch (ballType) {
    BallType.bye || BallType.legBye || BallType.deadBall => 0,
    _ => totalRuns,
  };

  BallModel copyWith({
    String? id,
    int? overNumber,
    int? ballNumber,
    int? runs,
    int? extraRuns,
    BallType? ballType,
    WicketType? wicketType,
    String? batsmanId,
    String? bowlerId,
    bool? isLegalBall,
    DateTime? timestamp,
    String? dismissedBatsmanId,
    String? fielderId,
    int? innings,
    String? previousStrikerId,
    String? previousNonStrikerId,
  }) => BallModel(
    id: id ?? this.id,
    overNumber: overNumber ?? this.overNumber,
    ballNumber: ballNumber ?? this.ballNumber,
    runs: runs ?? this.runs,
    extraRuns: extraRuns ?? this.extraRuns,
    ballType: ballType ?? this.ballType,
    wicketType: wicketType ?? this.wicketType,
    batsmanId: batsmanId ?? this.batsmanId,
    bowlerId: bowlerId ?? this.bowlerId,
    isLegalBall: isLegalBall ?? this.isLegalBall,
    timestamp: timestamp ?? this.timestamp,
    dismissedBatsmanId: dismissedBatsmanId ?? this.dismissedBatsmanId,
    fielderId: fielderId ?? this.fielderId,
    innings: innings ?? this.innings,
    previousStrikerId: previousStrikerId ?? this.previousStrikerId,
    previousNonStrikerId: previousNonStrikerId ?? this.previousNonStrikerId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'overNumber': overNumber,
    'ballNumber': ballNumber,
    'runs': runs,
    'extraRuns': extraRuns,
    'ballType': ballType.name,
    'wicketType': wicketType.name,
    'batsmanId': batsmanId,
    'bowlerId': bowlerId,
    'isLegalBall': isLegalBall,
    'timestamp': timestamp.toIso8601String(),
    'dismissedBatsmanId': dismissedBatsmanId,
    'fielderId': fielderId,
    'innings': innings,
    'previousStrikerId': previousStrikerId,
    'previousNonStrikerId': previousNonStrikerId,
  };

  @override
  List<Object?> get props => [
    id,
    overNumber,
    ballNumber,
    runs,
    extraRuns,
    ballType,
    wicketType,
    batsmanId,
    bowlerId,
    isLegalBall,
    timestamp,
    dismissedBatsmanId,
    fielderId,
    innings,
    previousStrikerId,
    previousNonStrikerId,
  ];
}

class OverModel extends Equatable {
  const OverModel({
    required this.overNumber,
    required this.balls,
    required this.bowlerId,
  });

  factory OverModel.fromJson(Map<String, dynamic> json) => OverModel(
    overNumber: json['overNumber'] as int,
    balls: (json['balls'] as List<dynamic>)
        .map((e) => BallModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    bowlerId: json['bowlerId'] as String,
  );

  final int overNumber;
  final List<BallModel> balls;
  final String bowlerId;
  int get runs => balls.fold(0, (sum, ball) => sum + ball.totalRuns);
  int get wickets => balls.where((ball) => ball.isWicket).length;

  OverModel copyWith({
    int? overNumber,
    List<BallModel>? balls,
    String? bowlerId,
  }) => OverModel(
    overNumber: overNumber ?? this.overNumber,
    balls: balls ?? this.balls,
    bowlerId: bowlerId ?? this.bowlerId,
  );

  Map<String, dynamic> toJson() => {
    'overNumber': overNumber,
    'balls': balls.map((e) => e.toJson()).toList(),
    'bowlerId': bowlerId,
    'runs': runs,
    'wickets': wickets,
  };

  @override
  List<Object?> get props => [overNumber, balls, bowlerId];
}

class MatchModel extends Equatable {
  const MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.currentBowlerId,
    required this.totalOvers,
    required this.createdAt,
    required this.updatedAt,
    this.matchCode,
    this.currentRuns = 0,
    this.currentWickets = 0,
    this.legalBalls = 0,
    this.innings = 1,
    this.ballHistory = const [],
    this.status = MatchStatus.live,
    this.syncStatus = SyncStatus.pending,
    this.result,
    this.firstInningsBattingTeamId,
    this.firstInningsRuns,
    this.firstInningsWickets,
    this.firstInningsLegalBalls,
    this.previousBowlerId,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
    id: json['id'] as String,
    teamA: TeamModel.fromJson(Map<String, dynamic>.from(json['teamA'] as Map)),
    teamB: TeamModel.fromJson(Map<String, dynamic>.from(json['teamB'] as Map)),
    battingTeamId: json['battingTeamId'] as String,
    bowlingTeamId: json['bowlingTeamId'] as String,
    strikerId: json['strikerId'] as String,
    nonStrikerId: json['nonStrikerId'] as String,
    currentBowlerId: json['currentBowlerId'] as String,
    currentRuns: json['currentRuns'] as int? ?? 0,
    currentWickets: json['currentWickets'] as int? ?? 0,
    totalOvers: json['totalOvers'] as int,
    legalBalls: json['legalBalls'] as int? ?? 0,
    innings: json['innings'] as int? ?? 1,
    ballHistory: (json['ballHistory'] as List<dynamic>? ?? [])
        .map((e) => BallModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    matchCode: json['matchCode'] as String?,
    status: MatchStatus.values.byName(json['status'] as String),
    syncStatus: SyncStatus.values.byName(
      json['syncStatus'] as String? ?? SyncStatus.pending.name,
    ),
    result: json['result'] as String?,
    firstInningsBattingTeamId: json['firstInningsBattingTeamId'] as String?,
    firstInningsRuns: json['firstInningsRuns'] as int?,
    firstInningsWickets: json['firstInningsWickets'] as int?,
    firstInningsLegalBalls: json['firstInningsLegalBalls'] as int?,
    previousBowlerId: json['previousBowlerId'] as String?,
  );

  final String id;
  final TeamModel teamA;
  final TeamModel teamB;
  final String battingTeamId;
  final String bowlingTeamId;
  final String strikerId;
  final String nonStrikerId;
  final String currentBowlerId;
  final int currentRuns;
  final int currentWickets;
  final int totalOvers;
  final int legalBalls;
  final int innings;
  final List<BallModel> ballHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? matchCode;
  final MatchStatus status;
  final SyncStatus syncStatus;
  final String? result;
  final String? firstInningsBattingTeamId;
  final int? firstInningsRuns;
  final int? firstInningsWickets;
  final int? firstInningsLegalBalls;
  final String? previousBowlerId;

  TeamModel get battingTeam => teamA.id == battingTeamId ? teamA : teamB;
  TeamModel get bowlingTeam => teamA.id == bowlingTeamId ? teamA : teamB;
  String get overs => '${legalBalls ~/ 6}.${legalBalls % 6}';
  double get currentRunRate =>
      legalBalls == 0 ? 0 : currentRuns * 6 / legalBalls;
  bool get overComplete => legalBalls > 0 && legalBalls % 6 == 0;
  int get maxWickets => battingTeam.players.length - 1;
  int? get target => firstInningsRuns == null ? null : firstInningsRuns! + 1;
  int? get runsRequired =>
      target == null ? null : (target! - currentRuns).clamp(0, target!);
  int get ballsRemaining => totalOvers * 6 - legalBalls;
  String get publicCode {
    final compact = id.replaceAll('-', '').toUpperCase();
    return matchCode ??
        (compact.length >= 6
            ? compact.substring(0, 6)
            : compact.padRight(6, 'X'));
  }

  double get requiredRunRate => innings != 2 || runsRequired == null
      ? 0
      : ballsRemaining <= 0
      ? runsRequired!.toDouble()
      : runsRequired! * 6 / ballsRemaining;

  MatchModel copyWith({
    String? id,
    TeamModel? teamA,
    TeamModel? teamB,
    String? battingTeamId,
    String? bowlingTeamId,
    String? strikerId,
    String? nonStrikerId,
    String? currentBowlerId,
    int? currentRuns,
    int? currentWickets,
    int? totalOvers,
    int? legalBalls,
    int? innings,
    List<BallModel>? ballHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? matchCode,
    MatchStatus? status,
    SyncStatus? syncStatus,
    String? result,
    bool clearResult = false,
    String? firstInningsBattingTeamId,
    int? firstInningsRuns,
    int? firstInningsWickets,
    int? firstInningsLegalBalls,
    String? previousBowlerId,
    bool clearPreviousBowler = false,
    bool clearFirstInnings = false,
  }) => MatchModel(
    id: id ?? this.id,
    teamA: teamA ?? this.teamA,
    teamB: teamB ?? this.teamB,
    battingTeamId: battingTeamId ?? this.battingTeamId,
    bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
    strikerId: strikerId ?? this.strikerId,
    nonStrikerId: nonStrikerId ?? this.nonStrikerId,
    currentBowlerId: currentBowlerId ?? this.currentBowlerId,
    currentRuns: currentRuns ?? this.currentRuns,
    currentWickets: currentWickets ?? this.currentWickets,
    totalOvers: totalOvers ?? this.totalOvers,
    legalBalls: legalBalls ?? this.legalBalls,
    innings: innings ?? this.innings,
    ballHistory: ballHistory ?? this.ballHistory,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    matchCode: matchCode ?? this.matchCode,
    status: status ?? this.status,
    syncStatus: syncStatus ?? this.syncStatus,
    result: clearResult ? null : result ?? this.result,
    firstInningsBattingTeamId: clearFirstInnings
        ? null
        : firstInningsBattingTeamId ?? this.firstInningsBattingTeamId,
    firstInningsRuns: clearFirstInnings
        ? null
        : firstInningsRuns ?? this.firstInningsRuns,
    firstInningsWickets: clearFirstInnings
        ? null
        : firstInningsWickets ?? this.firstInningsWickets,
    firstInningsLegalBalls: clearFirstInnings
        ? null
        : firstInningsLegalBalls ?? this.firstInningsLegalBalls,
    previousBowlerId: clearPreviousBowler
        ? null
        : previousBowlerId ?? this.previousBowlerId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamA': teamA.toJson(),
    'teamB': teamB.toJson(),
    'battingTeamId': battingTeamId,
    'bowlingTeamId': bowlingTeamId,
    'strikerId': strikerId,
    'nonStrikerId': nonStrikerId,
    'currentBowlerId': currentBowlerId,
    'currentRuns': currentRuns,
    'currentWickets': currentWickets,
    'totalOvers': totalOvers,
    'legalBalls': legalBalls,
    'innings': innings,
    'ballHistory': ballHistory.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'matchCode': publicCode,
    'status': status.name,
    'syncStatus': syncStatus.name,
    'result': result,
    'firstInningsBattingTeamId': firstInningsBattingTeamId,
    'firstInningsRuns': firstInningsRuns,
    'firstInningsWickets': firstInningsWickets,
    'firstInningsLegalBalls': firstInningsLegalBalls,
    'previousBowlerId': previousBowlerId,
  };

  @override
  List<Object?> get props => [
    id,
    teamA,
    teamB,
    battingTeamId,
    bowlingTeamId,
    strikerId,
    nonStrikerId,
    currentBowlerId,
    currentRuns,
    currentWickets,
    totalOvers,
    legalBalls,
    innings,
    ballHistory,
    createdAt,
    updatedAt,
    matchCode,
    status,
    syncStatus,
    result,
    firstInningsBattingTeamId,
    firstInningsRuns,
    firstInningsWickets,
    firstInningsLegalBalls,
    previousBowlerId,
  ];
}
