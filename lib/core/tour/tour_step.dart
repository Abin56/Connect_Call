import 'package:flutter/material.dart';

/// One stop in the coach-mark feature tour: the real widget to spotlight
/// (via [key]) plus the copy shown in its tooltip. [tabIndex] is the Home
/// bottom-nav tab that must be active for [key]'s widget to be mounted
/// (Home/Contacts/Calls/Profile all live in the same [IndexedStack], so the
/// controller switches tabs itself before measuring the target).
class TourStep {
  final GlobalKey key;
  final String title;
  final String description;
  final int tabIndex;
  final IconData icon;

  /// Extra padding added around the widget's bounds when drawing the
  /// spotlight cutout, so the highlight doesn't hug the widget too tightly.
  final double padding;

  const TourStep({
    required this.key,
    required this.title,
    required this.description,
    required this.tabIndex,
    this.icon = Icons.lightbulb_outline,
    this.padding = 8,
  });
}
