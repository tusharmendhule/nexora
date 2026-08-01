import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/age_verification_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/create_post/presentation/create_post_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/feed/presentation/home_screen.dart';
import '../../features/moderator/presentation/moderator_dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reels/presentation/reels_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/trust_center/presentation/trust_center_screen.dart';
import '../../navigation/main_shell.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Nexora's navigation graph.
///
/// * `/splash` is the entry; it routes to onboarding / login / home based on
///   the real auth state from the API-backed auth provider.
/// * `/home`, `/explore`, `/create`, `/reels` and `/profile` live inside a
///   [StatefulShellRoute.indexedStack] so each tab keeps its scroll position.
/// * Everything else is a full-screen destination pushed on the root navigator.
final appRouter = GoRouter(
  initialLocation: Routes.splash,
  navigatorKey: _rootNavigatorKey,
  routes: [
    // ---- Auth flow -----------------------------------------------------
    GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
    GoRoute(path: Routes.verifyAge, builder: (_, __) => const AgeVerificationScreen()),

    // ---- Bottom-nav shell ---------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.explore, builder: (_, __) => const ExploreScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.create, builder: (_, __) => const CreatePostScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.reels, builder: (_, __) => const ReelsScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen())],
        ),
      ],
    ),

    // ---- Full-screen destinations --------------------------------------
    GoRoute(
      path: Routes.profileDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) =>
          ProfileScreen(userId: state.pathParameters['id']),
    ),
    GoRoute(
      path: Routes.search,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SearchScreen(),
    ),
    GoRoute(
      path: Routes.notifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(
      path: Routes.chat,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ChatListScreen(),
    ),
    GoRoute(
      path: Routes.chatDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) =>
          ChatDetailScreen(chatId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: Routes.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.trustCenter,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const TrustCenterScreen(),
    ),
    GoRoute(
      path: Routes.moderator,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ModeratorDashboardScreen(),
    ),
    GoRoute(
      path: Routes.admin,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: Routes.editProfile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const EditProfileScreen(),
    ),
  ],
);
