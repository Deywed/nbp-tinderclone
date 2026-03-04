import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/core/bottom_nav_bar.dart';
import 'package:tinderclone/features/auth/login/screens/login_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/interests_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/orientation_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/profile_creation_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/registration_screen.dart';
import 'package:tinderclone/features/discovery/home/discovery_screen.dart';
import 'package:tinderclone/features/matches/screens/matches_screen.dart';
import 'package:tinderclone/features/profile/screens/profile_screen.dart';
import 'package:tinderclone/features/matches/screens/user_profile_view_screen.dart';
import 'package:tinderclone/features/profile/screens/edit_profile_screen.dart';
import 'package:tinderclone/features/stats/screens/stats_screen.dart';
import 'package:tinderclone/features/top_picks/screens/top_picks_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login-screen',
    routes: [
      GoRoute(
        path: '/login-screen',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/registration-screen',
        builder: (context, state) => RegistrationScreen(),
      ),
      GoRoute(
        path: '/profile-creation-screen',
        builder: (context, state) {
          final user = state.extra as UserModel?;
          return ProfileCreationScreen(user: user);
        },
      ),

      GoRoute(
        path: '/orientation-screen',
        builder: (context, state) {
          final user = state.extra as UserModel?;
          return OrientationScreen(user: user);
        },
      ),
      GoRoute(
        path: '/interest-screen',
        builder: (context, state) {
          final user = state.extra as UserModel?;
          return InterestsScreen(user: user);
        },
      ),
      GoRoute(
        path: '/top-picks-screen',
        builder: (context, state) => const TopPicksScreen(),
      ),
      GoRoute(
        path: '/user-profile-screen',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return UserProfileViewScreen(user: user);
        },
      ),
      GoRoute(
        path: '/edit-profile-screen',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: '/stats-screen',
        builder: (context, state) => const StatsScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) => Scaffold(
              body: navigationShell,
              bottomNavigationBar: BottomNavBar(
                customPage: navigationShell.currentIndex,
              ),
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discovery-screen',
                builder: (context, state) => DiscoveryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/matches-screen',
                builder: (context, state) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile-screen',
                builder: (context, state) => ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
