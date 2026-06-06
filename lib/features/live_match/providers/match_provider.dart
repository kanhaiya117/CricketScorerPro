import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cricket_scorer_pro/core/services/firestore_match_service.dart';
import 'package:cricket_scorer_pro/core/storage/hive_match_storage.dart';
import 'package:cricket_scorer_pro/features/live_match/engine/match_engine.dart';
import 'package:cricket_scorer_pro/shared/models/cricket_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageProvider = Provider<HiveMatchStorage>(
  (ref) => throw UnimplementedError(),
);
final firestoreServiceProvider = Provider<FirestoreMatchService?>(
  (ref) => null,
);
final matchEngineProvider = Provider((ref) => const MatchEngine());

final historyProvider = NotifierProvider<HistoryNotifier, List<MatchModel>>(
  HistoryNotifier.new,
);

class HistoryNotifier extends Notifier<List<MatchModel>> {
  @override
  List<MatchModel> build() => ref.read(storageProvider).getHistory();

  void refresh() => state = ref.read(storageProvider).getHistory();

  Future<void> delete(String id) async {
    await ref.read(storageProvider).deleteMatch(id);
    state = state.where((match) => match.id != id).toList();
    try {
      await ref.read(firestoreServiceProvider)?.deleteMatch(id);
    } catch (_) {
      // Local deletion remains authoritative while offline.
    }
  }
}

final currentMatchProvider = NotifierProvider<MatchNotifier, MatchModel?>(
  MatchNotifier.new,
);

class MatchNotifier extends Notifier<MatchModel?> {
  @override
  MatchModel? build() => ref.read(storageProvider).getCurrentMatch();

  Future<void> start(MatchModel match) async {
    state = match;
    await _persist(match);
  }

  Future<void> load(String id) async {
    state = ref.read(storageProvider).getMatch(id);
  }

  Future<MatchModel?> score({
    required int runs,
    BallType ballType = BallType.normal,
    WicketType wicketType = WicketType.none,
    String? dismissedBatsmanId,
    String? nextBatsmanId,
  }) async {
    final current = state;
    if (current == null) return null;
    final updated = ref
        .read(matchEngineProvider)
        .recordBall(
          current,
          runs: runs,
          ballType: ballType,
          wicketType: wicketType,
          dismissedBatsmanId: dismissedBatsmanId,
          nextBatsmanId: nextBatsmanId,
        );
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<void> undo() async {
    final current = state;
    if (current == null) return;
    final updated = ref.read(matchEngineProvider).undo(current);
    state = updated;
    await _persist(updated);
  }

  Future<void> changeBowler(String id) async {
    final current = state;
    if (current == null) return;
    final updated = ref.read(matchEngineProvider).changeBowler(current, id);
    state = updated;
    await _persist(updated);
  }

  Future<void> endMatch() async {
    final current = state;
    if (current == null) return;
    final updated = ref.read(matchEngineProvider).endMatch(current);
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(MatchModel match) async {
    await ref.read(storageProvider).saveMatch(match);
    ref.read(historyProvider.notifier).refresh();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

class SyncState {
  const SyncState({
    this.isOnline = false,
    this.isSyncing = false,
    this.lastSynced,
  });

  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSynced;

  SyncState copyWith({bool? isOnline, bool? isSyncing, DateTime? lastSynced}) =>
      SyncState(
        isOnline: isOnline ?? this.isOnline,
        isSyncing: isSyncing ?? this.isSyncing,
        lastSynced: lastSynced ?? this.lastSynced,
      );
}

class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  SyncState build() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
    ref.onDispose(() => _subscription?.cancel());
    unawaited(Connectivity().checkConnectivity().then(_onChanged));
    return const SyncState();
  }

  Future<void> _onChanged(List<ConnectivityResult> results) async {
    final online = !results.contains(ConnectivityResult.none);
    state = state.copyWith(isOnline: online);
    if (online) await sync();
  }

  Future<void> sync() async {
    final service = ref.read(firestoreServiceProvider);
    if (service == null || state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    await service.syncPendingMatches(ref.read(storageProvider));
    ref.read(historyProvider.notifier).refresh();
    state = state.copyWith(isSyncing: false, lastSynced: DateTime.now());
  }
}
