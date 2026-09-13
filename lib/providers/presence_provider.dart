import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/presence_service.dart';
import 'user_provider.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService(userService: ref.read(userServiceProvider));
  ref.onDispose(service.stop);
  return service;
});
