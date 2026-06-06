import 'dart:convert';

import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveMatchStorage {
  static const boxName = 'matches';
  late Box<String> _box;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(boxName);
  }

  Future<void> saveMatch(MatchModel match) =>
      _box.put(match.id, jsonEncode(match.toJson()));

  Future<void> updateMatch(MatchModel match) => saveMatch(match);

  Future<void> deleteMatch(String id) => _box.delete(id);

  MatchModel? getMatch(String id) {
    final value = _box.get(id);
    return value == null
        ? null
        : MatchModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          );
  }

  MatchModel? getCurrentMatch() {
    final live =
        getHistory()
            .where((match) => match.status != MatchStatus.completed)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return live.firstOrNull;
  }

  List<MatchModel> getHistory() {
    final matches = _box.values
        .map(
          (value) => MatchModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        )
        .toList();
    matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matches;
  }

  List<MatchModel> getPendingSyncMatches() => getHistory()
      .where((match) => match.syncStatus != SyncStatus.synced)
      .toList();
}
