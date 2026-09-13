import 'package:flutter/material.dart';

/// One step in the coach-mark tour: the widget to spotlight ([key]) plus
/// the text shown in its tooltip. [tabIndex] is the Home bottom-nav tab
/// that needs to be active for [key]'s widget to exist on screen (Home,
/// Contacts, Calls, and Profile all live in the same [IndexedStack], so
/// the controller switches tabs itself before measuring the target).
class TourStep {
  final GlobalKey key;
  final String title;
  final String description;
  final int tabIndex;
  final IconData icon;

  /// Extra padding around the widget when drawing the spotlight, so the
  /// highlight isn't hugging the widget too tightly.
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
