/// App-wide constant values that aren't secrets (spacing, Firestore
/// collection names, etc). Real secrets live in [ZegoConstants].
class AppConstants {
  AppConstants._();

  static const String appName = 'ConnectCall';

  // Firestore collection names, kept in one place so a rename doesn't
  // require hunting through every service file.
  static const String usersCollection = 'users';
  static const String callsCollection = 'calls';
}

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}
