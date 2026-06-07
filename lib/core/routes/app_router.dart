import 'package:cricket_scorer_pro/features/dashboard/presentation/dashboard_screen.dart';
import 'package:cricket_scorer_pro/features/live_match/presentation/live_match_screen.dart';
import 'package:cricket_scorer_pro/features/match_history/presentation/match_history_screen.dart';
import 'package:cricket_scorer_pro/features/match_setup/presentation/match_setup_screen.dart';
import 'package:cricket_scorer_pro/features/match_summary/presentation/match_summary_screen.dart';
import 'package:cricket_scorer_pro/features/spectator/presentation/spectator_scoreboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
    GoRoute(
      path: '/setup',
      pageBuilder: (_, state) => _page(state, const MatchSetupScreen()),
    ),
    GoRoute(
      path: '/live',
      pageBuilder: (_, state) => _page(state, const LiveMatchScreen()),
    ),
    GoRoute(
      path: '/summary',
      pageBuilder: (_, state) => _page(state, const MatchSummaryScreen()),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (_, state) => _page(state, const MatchHistoryScreen()),
    ),
    GoRoute(
      path: '/watch/:code',
      pageBuilder: (_, state) => _page(
        state,
        SpectatorScoreboardScreen(code: state.pathParameters['code']!),
      ),
    ),
  ],
);

CustomTransitionPage<void> _page(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
