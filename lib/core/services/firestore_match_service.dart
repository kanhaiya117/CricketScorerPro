import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cricket_scorer_pro/core/storage/hive_match_storage.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';

class FirestoreMatchService {
  FirestoreMatchService(this._firestore);

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  Future<void> createMatch(MatchModel match) => updateMatch(match);

  Future<void> updateMatch(MatchModel match) async {
    final ref = _matches.doc(match.id);
    final remote = await ref.get();
    if (remote.exists) {
      final remoteData = remote.data();
      final remoteUpdated = remoteData == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.parse(remoteData['updatedAt'] as String);
      if (remoteUpdated.isAfter(match.updatedAt)) return;
    }
    final data = match.copyWith(syncStatus: SyncStatus.synced).toJson();
    await ref.set(data, SetOptions(merge: true));
    final batch = _firestore.batch();
    for (final team in [match.teamA, match.teamB]) {
      batch.set(ref.collection('teams').doc(team.id), team.toJson());
    }
    await batch.commit();
  }

  Future<void> deleteMatch(String id) => _matches.doc(id).delete();

  Future<List<MatchModel>> fetchMatches() async {
    final snapshot = await _matches
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => MatchModel.fromJson(doc.data())).toList();
  }

  Future<MatchModel?> findByCode(String code) async {
    final snapshot = await _matches
        .where('matchCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    return snapshot.docs.isEmpty
        ? null
        : MatchModel.fromJson(snapshot.docs.first.data());
  }

  Stream<MatchModel?> watchByCode(String code) => _matches
      .where('matchCode', isEqualTo: code.trim().toUpperCase())
      .limit(1)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.isEmpty
            ? null
            : MatchModel.fromJson(snapshot.docs.first.data()),
      );

  Future<void> syncPendingMatches(HiveMatchStorage storage) async {
    for (final match in storage.getPendingSyncMatches()) {
      try {
        final remote = await _matches.doc(match.id).get();
        if (remote.exists && remote.data() != null) {
          final remoteMatch = MatchModel.fromJson(remote.data()!);
          if (remoteMatch.updatedAt.isAfter(match.updatedAt)) {
            await storage.updateMatch(
              remoteMatch.copyWith(syncStatus: SyncStatus.synced),
            );
            continue;
          }
        }
        await updateMatch(match);
        await storage.updateMatch(
          match.copyWith(syncStatus: SyncStatus.synced),
        );
      } catch (_) {
        await storage.updateMatch(
          match.copyWith(syncStatus: SyncStatus.failed),
        );
      }
    }
  }

  Future<void> syncMatch(MatchModel match, HiveMatchStorage storage) async {
    try {
      final remote = await _matches.doc(match.id).get();
      if (remote.exists && remote.data() != null) {
        final remoteMatch = MatchModel.fromJson(remote.data()!);
        if (remoteMatch.updatedAt.isAfter(match.updatedAt)) {
          await storage.updateMatch(
            remoteMatch.copyWith(syncStatus: SyncStatus.synced),
          );
          return;
        }
      }
      await updateMatch(match);
      await storage.updateMatch(match.copyWith(syncStatus: SyncStatus.synced));
    } catch (_) {
      await storage.updateMatch(match.copyWith(syncStatus: SyncStatus.failed));
    }
  }
}
