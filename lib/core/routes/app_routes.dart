/// Names for all the app's routes. We use plain strings with Navigator
/// instead of a routing package since navigation here is simple (an auth
/// gate, a bottom nav, and a couple of pushed screens for calls/profile).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
}
