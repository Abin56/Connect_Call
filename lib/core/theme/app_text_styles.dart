import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Reusable text styles so screens don't each redefine their own font
/// sizes and weights. Built on Plus Jakarta Sans for a clean, confident look.
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

  // No color set here on purpose -- these pick up the color from the
  // active theme, so the same style works in both light and dark mode.
  // Use the OnDark variants below for surfaces that are always dark no
  // matter the app's theme.
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

  /// Bolder text for things like call duration or connection status.
  static TextStyle statusEmphasis = _jakarta(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColorsDark.textPrimary,
  );

  // Variants for dark surfaces, like splash and hero cards, that stay
  // near-black no matter which theme is active.
  static TextStyle heading1OnDark = heading1.copyWith(color: Colors.white);
  static TextStyle heading2OnDark = heading2.copyWith(color: Colors.white);
  static TextStyle heading3OnDark = heading3.copyWith(color: Colors.white);
  static TextStyle bodyOnDark = body.copyWith(color: Colors.white);
  static TextStyle bodyMutedOnDark = bodyMuted.copyWith(
    color: AppColors.offline,
  );
}
