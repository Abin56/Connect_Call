import 'package:flutter/material.dart';

/// Central color palette for the Sankar Group brand identity -- premium,
/// minimal black/charcoal (dark) or white/grey (light) surfaces with a
/// corporate brand red (#C8102E family) reserved as an accent for primary
/// actions, active states, and destructive/missed-call indicators. Widgets
/// should read colors from `Theme.of(context)` (which these feed into)
/// rather than referencing [AppColors]/[AppColorsDark] directly, except in a
/// few places that intentionally want a fixed brand color regardless of
/// brightness (e.g. a red call-accept button).
class AppColors {
  AppColors._();

  // Brand red family
  static const Color red = Color(0xFFC8102E); // Primary brand red
  static const Color redStrong = Color(0xFFD71920); // Strong red
  static const Color redBright = Color(0xFFEF233C); // Bright red
  static const Color redDeep = Color(0xFF8F0015); // Deep red
  static const Color wineRed = Color(0xFF4A050D); // Dark wine red
  static const Color softRed = Color(0xFFFDE8EC); // Soft red tint

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

/// Dark-theme counterpart. Not a naive inversion of [AppColors] -- dark
/// surfaces step up in layered near-black tiers (background < backgroundSecondary
/// < surface < card < elevated) so cards and dialogs stay readable against
/// the base background, without ever using pure black.
class AppColorsDark {
  AppColorsDark._();

  static const Color red = Color(0xFFC8102E); // Primary brand red
  static const Color redStrong = Color(0xFFD71920); // Strong red
  static const Color redBright = Color(0xFFEF233C); // Bright accent
  static const Color redDeep = Color(0xFF8F0015); // Deep accent
  static const Color wineRed = Color(0xFF4A050D); // Dark wine red

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

/// Reads the theme-correct "online" presence color, since [AppColors.online]
/// and [AppColorsDark.online] otherwise have to be picked by hand at every
/// call site based on `Theme.of(context).brightness`.
extension AppColorsBrightness on BuildContext {
  Color get onlineColor => Theme.of(this).brightness == Brightness.dark
      ? AppColorsDark.online
      : AppColors.online;
}

/// Small, centralized set of atmospheric gradient treatments for the
/// handful of "featured" brand moments in the app (Home call CTA, Profile
/// header, Login/Register hero, Splash logo). These are intentionally
/// subtle -- a soft glow/vignette, not a bold visible banner -- and are
/// layered *under* content rather than replacing a surface color outright.
///
/// Dark-mode treatment: a black -> dark wine -> deep red -> brand red glow,
/// meant to emanate from a point (e.g. behind a logo/avatar) and fade to
/// near-black at the edges. Light-mode treatment: a much gentler white ->
/// soft-red tint for the same "featured" spots, since a black->red glow
/// reads as a dark-mode-only effect.
class AppGradients {
  AppGradients._();

  /// Dark-mode atmospheric glow: near-black centre/edges with a faint warm
  /// red core. Use as a [BoxDecoration.gradient] behind logos/avatars/CTAs
  /// on dark surfaces. [center] lets call sites move the glow's focal point
  /// (e.g. top-center behind a logo vs. centered behind an avatar).
  static RadialGradient darkGlow({Alignment center = Alignment.topCenter}) {
    return RadialGradient(
      center: center,
      radius: 1.1,
      colors: const [
        Color(0x33C8102E), // brand red, low opacity
        Color(0xFF570914), // deep red
        Color(0xFF26070B), // dark wine
        Color(0xFF050505), // deep black
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
  }

  /// Very gentle vertical fade variant of [darkGlow], for backgrounds where
  /// a radial glow would be too focal (e.g. a full-screen hero backdrop).
  static const LinearGradient darkGlowVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF26070B), Color(0xFF050505)],
  );

  /// Light-mode equivalent "featured" tint: soft white fading to a whisper
  /// of brand-red-tinted white. Subtle -- not a visible diagonal gradient.
  static const LinearGradient lightFeatured = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, AppColors.softRed],
  );
}
