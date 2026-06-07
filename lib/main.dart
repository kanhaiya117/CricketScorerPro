import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cricket_scorer_pro/core/routes/app_router.dart';
import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/core/localization/locale_provider.dart';
import 'package:cricket_scorer_pro/core/services/firestore_match_service.dart';
import 'package:cricket_scorer_pro/core/storage/hive_match_storage.dart';
import 'package:cricket_scorer_pro/core/theme/app_theme.dart';
import 'package:cricket_scorer_pro/features/live_match/providers/match_provider.dart';
import 'package:cricket_scorer_pro/features/language/presentation/language_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_scorer_pro/shared/widgets/responsive_content.dart';

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
    title: 'Cric Score Pro',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ref.watch(themeModeProvider),
    locale: ref.watch(localeProvider),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => _FirstLaunchGate(
      child: Column(
        children: [
          Expanded(child: child ?? const SizedBox.shrink()),
          const AppFooter(),
        ],
      ),
    ),
    routerConfig: appRouter,
  );
}

class _FirstLaunchGate extends StatefulWidget {
  const _FirstLaunchGate({required this.child});

  final Widget child;

  @override
  State<_FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<_FirstLaunchGate> {
  bool? chosen;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      if (mounted) {
        setState(() => chosen = preferences.containsKey('app_language'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (chosen == null) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!chosen!) {
      return LanguageSelectionScreen(
        onComplete: () => setState(() => chosen = true),
      );
    }
    return widget.child;
  }
}
