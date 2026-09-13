import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Reusable text styles so screens don't redefine font sizes/weights ad hoc.
/// Built on Plus Jakarta Sans for a premium, confident type feel.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _jakarta({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Base styles intentionally omit `color` (left null) so that a bare
  // `Text(style: AppTextStyles.body)` resolves its color from the ambient
  // `DefaultTextStyle` (which MaterialApp/Scaffold derive from the active
  // ThemeData.textTheme -- see AppTheme) instead of a fixed dark-mode
  // color. This is what lets these same static styles work correctly in
  // both the light and dark theme without every call site needing to look
  // up Theme.of(context) itself. Use the "OnDark"/"OnLight" variants below
  // when a widget's background is a fixed color regardless of app theme
  // (e.g. the splash screen, which always shows on a near-black surface).
  static TextStyle heading1 = _jakarta(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static TextStyle heading2 = _jakarta(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static TextStyle heading3 = _jakarta(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle body = _jakarta(fontSize: 15, fontWeight: FontWeight.w500);

  static TextStyle bodyMuted = _jakarta(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle caption = _jakarta(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static TextStyle button = _jakarta(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle navLabel = _jakarta(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textPrimary,
  );

  /// Emphasized state text (call duration, connection status).
  static TextStyle statusEmphasis = _jakarta(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColorsDark.textPrimary,
  );

  // Dark-surface variants, for use on near-black backgrounds (splash,
  // hero cards) regardless of the active theme brightness.
  static TextStyle heading1OnDark = heading1.copyWith(color: Colors.white);
  static TextStyle heading2OnDark = heading2.copyWith(color: Colors.white);
  static TextStyle heading3OnDark = heading3.copyWith(color: Colors.white);
  static TextStyle bodyOnDark = body.copyWith(color: Colors.white);
  static TextStyle bodyMutedOnDark = bodyMuted.copyWith(
    color: AppColors.offline,
  );
}
