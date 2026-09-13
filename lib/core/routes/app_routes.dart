/// Named route constants. Kept as plain strings + Navigator rather than a
/// routing package since this app's navigation is shallow (auth gate,
/// bottom nav, a couple of pushed screens for calls/profile).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
}
