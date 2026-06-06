import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cricket_scorer_pro/core/routes/app_router.dart';
import 'package:cricket_scorer_pro/core/services/firestore_match_service.dart';
import 'package:cricket_scorer_pro/core/storage/hive_match_storage.dart';
import 'package:cricket_scorer_pro/core/theme/app_theme.dart';
import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = HiveMatchStorage();
  await storage.initialize();
  FirestoreMatchService? firestore;
  try {
    await Firebase.initializeApp();
    firestore = FirestoreMatchService(FirebaseFirestore.instance);
  } catch (_) {
    // Firebase is optional until google-services.json is configured.
  }
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        firestoreServiceProvider.overrideWithValue(firestore),
      ],
      child: const CricketScorerApp(),
    ),
  );
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

class CricketScorerApp extends ConsumerWidget {
  const CricketScorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Cricket Scorer Pro',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ref.watch(themeModeProvider),
    routerConfig: appRouter,
  );
}
