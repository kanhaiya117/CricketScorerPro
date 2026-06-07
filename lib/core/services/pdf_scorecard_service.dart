import 'dart:io';

import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfScorecardService {
  const PdfScorecardService();

  Future<File> generate(MatchModel match) async {
    final fallbackFonts = await Future.wait(
      _fontPaths.map((path) async => pw.Font.ttf(await rootBundle.load(path))),
    );
    final document = pw.Document(
      title: '${match.teamA.name} vs ${match.teamB.name}',
      author: 'Cric Score Pro - KK Bharat',
    );
    final firstId =
        match.firstInningsBattingTeamId ??
        (match.innings == 1 ? match.battingTeamId : match.bowlingTeamId);
    final first = match.teamA.id == firstId ? match.teamA : match.teamB;
    final second = match.teamA.id == firstId ? match.teamB : match.teamA;
    final firstBalls =
        match.firstInningsLegalBalls ??
        match.ballHistory
            .where((ball) => ball.innings == 1 && ball.isLegalBall)
            .length;
    final secondBalls = match.ballHistory
        .where((ball) => ball.innings == 2 && ball.isLegalBall)
        .length;

    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          fontFallback: fallbackFonts,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green700)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'CRIC SCORE PRO',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text('Match code: ${match.publicCode}'),
            ],
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Developed by K.K. & Co. | Powered by KK Bharat',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              '${match.teamA.name} vs ${match.teamB.name}',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if (match.result != null)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  match.result!,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ),
            ),
          _topPerformers(match),
          pw.SizedBox(height: 14),
          _innings('1st Innings', first, second, firstBalls),
          if (match.innings == 2) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'Target: ${match.target}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _innings('2nd Innings', second, first, secondBalls),
          ],
          if (match.status == MatchStatus.live) ...[
            pw.SizedBox(height: 14),
            _currentPlay(match),
          ],
          pw.SizedBox(height: 14),
          _overHistory(match),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final safeName =
        '${match.teamA.name}_vs_${match.teamB.name}_${match.publicCode}'
            .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${directory.path}/$safeName.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  pw.Widget _innings(
    String heading,
    TeamModel batting,
    TeamModel bowling,
    int legalBalls,
  ) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: double.infinity,
        color: PdfColors.green800,
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          '$heading - ${batting.name}  '
          '${batting.totalRuns}/${batting.wickets} '
          '(${_overs(legalBalls)} ov)',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Text('Batting', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(
        headers: const ['Batter', 'Dismissal', 'R', 'B', '4s', '6s', 'SR'],
        data: batting.players
            .where((player) => player.ballsFaced > 0 || player.isOut)
            .map(
              (player) => [
                player.name,
                player.dismissalText ?? 'not out',
                player.runs,
                player.ballsFaced,
                player.fours,
                player.sixes,
                player.strikeRate.toStringAsFixed(1),
              ],
            )
            .toList(),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        cellPadding: const pw.EdgeInsets.all(4),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Text(
          'Extras: ${batting.extras}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.Text('Bowling', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(
        headers: const ['Bowler', 'O', 'R', 'W', 'Eco'],
        data: bowling.players
            .where((player) => player.ballsBowled > 0)
            .map(
              (player) => [
                player.name,
                player.overs,
                player.runsConceded,
                player.wickets,
                player.economy.toStringAsFixed(1),
              ],
            )
            .toList(),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        cellPadding: const pw.EdgeInsets.all(4),
      ),
    ],
  );

  pw.Widget _topPerformers(MatchModel match) {
    final ranked = <({PlayerModel player, String team, int score})>[
      for (final player in match.teamA.players)
        (
          player: player,
          team: match.teamA.name,
          score: player.runs + player.wickets * 25,
        ),
      for (final player in match.teamB.players)
        (
          player: player,
          team: match.teamB.name,
          score: player.runs + player.wickets * 25,
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    final top = ranked.where((entry) => entry.score > 0).take(3).toList();
    if (top.isEmpty) return pw.SizedBox.shrink();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber700),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TOP 3 PERFORMERS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.SizedBox(height: 6),
          for (var index = 0; index < top.length; index++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${index + 1}. ${top[index].player.name} '
                '(${top[index].team}) - '
                '${top[index].player.runs} runs, '
                '${top[index].player.wickets} wickets, '
                '${top[index].player.fours} fours, '
                '${top[index].player.sixes} sixes',
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _currentPlay(MatchModel match) {
    String name(TeamModel team, String id) =>
        team.players.firstWhere((player) => player.id == id).name;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green700),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Current Play',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Striker: ${name(match.battingTeam, match.strikerId)}'),
          pw.Text(
            'Non-striker: ${name(match.battingTeam, match.nonStrikerId)}',
          ),
          pw.Text('Bowler: ${name(match.bowlingTeam, match.currentBowlerId)}'),
          if (match.innings == 2)
            pw.Text(
              'Need ${match.runsRequired} runs from '
              '${match.ballsRemaining} balls',
            ),
        ],
      ),
    );
  }

  pw.Widget _overHistory(MatchModel match) {
    final grouped = <String, List<BallModel>>{};
    for (final ball in match.ballHistory) {
      grouped
          .putIfAbsent('${ball.innings}-${ball.overNumber + 1}', () => [])
          .add(ball);
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Over-by-over',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        for (final entry in grouped.entries)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              'Innings ${entry.key.split('-').first}, '
              'Over ${entry.key.split('-').last}: '
              '${entry.value.map(_ballLabel).join('  ')}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
      ],
    );
  }

  String _ballLabel(BallModel ball) {
    if (ball.isWicket) return 'W';
    return switch (ball.ballType) {
      BallType.wide => 'Wd',
      BallType.noBall => 'Nb',
      BallType.deadBall => 'Db',
      BallType.normal => '${ball.runs}',
    };
  }

  String _overs(int balls) => '${balls ~/ 6}.${balls % 6}';

  static const _fontPaths = [
    'assets/fonts/NotoSansDevanagari-Regular.ttf',
    'assets/fonts/NotoSansTamil-Regular.ttf',
    'assets/fonts/NotoSansTelugu-Regular.ttf',
    'assets/fonts/NotoSansMalayalam-Regular.ttf',
    'assets/fonts/NotoSansKannada-Regular.ttf',
    'assets/fonts/NotoSansGurmukhi-Regular.ttf',
    'assets/fonts/NotoSansBengali-Regular.ttf',
    'assets/fonts/NotoSansOriya-Regular.ttf',
    'assets/fonts/NotoSansGujarati-Regular.ttf',
  ];
}
