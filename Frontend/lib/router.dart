import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/core/bottom_nav_bar.dart';
import 'package:tinderclone/features/auth/login/screens/login_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/interests_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/orientation_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/profile_creation_screen.dart';
import 'package:tinderclone/features/auth/registration/screens/registration_screen.dart';
import 'package:tinderclone/features/chats/screens/chats_screen.dart';
import 'package:tinderclone/features/discovery/home/discovery_screen.dart';
import 'package:tinderclone/features/profile/screens/profile_screen.dart';

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
        builder: (context, state) => OrientationScreen(),
      ),
      GoRoute(
        path: '/interest-screen',
        builder: (context, state) => InterestsScreen(),
      ),
      GoRoute(
        path: '/orientation-screen',
        builder: (context, state) => OrientationScreen(),
      ),
      // GoRoute(path: '/registration-screen', builder: (context, state) => RegistrationScreen()),

      // ---- primer za bottom nav bar
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
                path: '/chats-screen',
                builder: (context, state) => ChatsScreen(),
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
