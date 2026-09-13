import 'package:flutter/widgets.dart';

/// The app's single [Navigator], shared outside the widget tree.
///
/// Split out from `main.dart` so [CallingService] can grab a [BuildContext]
/// for its own fallback hang-up without importing `main.dart` (which
/// already imports the calling provider -- that would be a cycle).
final navigatorKey = GlobalKey<NavigatorState>();
