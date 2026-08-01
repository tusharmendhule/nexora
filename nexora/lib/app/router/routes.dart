/// Central route path registry. Screens navigate with [Routes.x] constants so
/// renaming a path only touches one file.
abstract final class Routes {
  // Auth flow
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyAge = '/verify-age';

  // Shell tabs
  static const String home = '/home';
  static const String explore = '/explore';
  static const String create = '/create';
  static const String reels = '/reels';
  static const String profile = '/profile';

  // Full-screen destinations
  static const String profileDetail = '/profile/:id';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:id';
  static const String settings = '/settings';
  static const String trustCenter = '/trust-center';
  static const String moderator = '/moderator';
  static const String admin = '/admin';
  static const String editProfile = '/edit-profile';

  static String chatDetailPath(String id) => '/chat/$id';
  static String profilePath(String id) => '/profile/$id';
}
