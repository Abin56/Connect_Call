import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/calling_service.dart';
import 'call_history_provider.dart';

final callingServiceProvider = Provider<CallingService>((ref) {
  return CallingService(callService: ref.read(callServiceProvider));
});
