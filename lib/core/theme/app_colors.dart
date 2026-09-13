import 'package:flutter/material.dart';

/// Central color palette for the Sankar Group brand identity: black/charcoal
/// (dark) or white/grey (light) surfaces with a brand red accent. Prefer
/// `Theme.of(context)` over referencing these directly, except where a
/// color needs to stay fixed regardless of brightness.
class AppColors {
  AppColors._();

  // Brand red family
  static const Color red = Color(0xFFC8102E);
  static const Color redStrong = Color(0xFFD71920);
  static const Color redBright = Color(0xFFEF233C);
  static const Color redDeep = Color(0xFF8F0015);
  static const Color wineRed = Color(0xFF4A050D);
  static const Color softRed = Color(0xFFFDE8EC);

  static const Color nearBlack = Color(0xFF151515);
  static const Color darkElevated = Color(0xFFE4E4E4);

  // Light surfaces
  static const Color background = Color(0xFFF7F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F1F1);
  static const Color softCard = Color(0xFFFAFAFA);

  // Light text
  static const Color textPrimary = Color(0xFF151515);
  static const Color textSecondary = Color(0xFF4B4B4B);
  static const Color textTertiary = Color(0xFF7A7A7A);

  static const Color border = Color(0xFFE5E5E5);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  static const Color online = success;
  static const Color offline = Color(0xFFB0B0B0);

  static const Color callIncoming = redStrong;
  static const Color callConnecting = redStrong;
  static const Color callMissed = error;
  static const Color callRejected = error;
  static const Color muted = darkElevated;
}

/// Dark-theme counterpart. Surfaces step up through layered near-black
/// tiers (background < surface < card < elevated) so cards and dialogs
/// stay readable, without ever using pure black.
class AppColorsDark {
  AppColorsDark._();

  static const Color red = Color(0xFFC8102E);
  static const Color redStrong = Color(0xFFD71920);
  static const Color redBright = Color(0xFFEF233C);
  static const Color redDeep = Color(0xFF8F0015);
  static const Color wineRed = Color(0xFF4A050D);

  static const Color background = Color(0xFF070707);
  static const Color backgroundSecondary = Color(0xFF101010);
  static const Color surface = Color(0xFF171717);
  static const Color surfaceMuted = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF1E1E1E);
  static const Color elevated = Color(0xFF252525);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textTertiary = Color(0xFF777777);

  static const Color border = Color(0xFF303030);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFF59E0B);

  static const Color online = success;
  static const Color offline = Color(0xFF54544F);

  static const Color callIncoming = redStrong;
  static const Color callConnecting = redStrong;
  static const Color callMissed = error;
  static const Color callRejected = error;
  static const Color muted = elevated;
}

/// Theme-correct "online" presence color, so call sites don't have to pick
/// between [AppColors.online] and [AppColorsDark.online] by hand.
extension AppColorsBrightness on BuildContext {
  Color get onlineColor => Theme.of(this).brightness == Brightness.dark
      ? AppColorsDark.online
      : AppColors.online;
}

/// Atmospheric gradients for the "featured" brand moments (Home call CTA,
/// Profile header, Login/Register hero, Splash logo). Subtle glow, not a
/// bold banner.
class AppGradients {
  AppGradients._();

  /// Dark-mode glow: near-black edges with a faint warm red core.
  /// [center] moves the focal point behind a logo, avatar, etc.
  static RadialGradient darkGlow({Alignment center = Alignment.topCenter}) {
    return RadialGradient(
      center: center,
      radius: 1.1,
      colors: const [
        Color(0x33C8102E),
        Color(0xFF570914),
        Color(0xFF26070B),
        Color(0xFF050505),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
  }

  /// Vertical fade variant of [darkGlow] for full-screen backdrops, where
  /// a radial glow would be too focal.
  static const LinearGradient darkGlowVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF26070B), Color(0xFF050505)],
  );

  /// Light-mode equivalent: soft white fading to a whisper of brand red.
  static const LinearGradient lightFeatured = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, AppColors.softRed],
  );
}
