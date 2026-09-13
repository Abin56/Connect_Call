import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/call_model.dart';
import '../services/call_service.dart';
import 'auth_provider.dart';

final callServiceProvider = Provider<CallService>((ref) => CallService());

/// The signed-in user's call history, newest first.
final callHistoryProvider = StreamProvider<List<CallModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(<CallModel>[]);
  return ref.watch(callServiceProvider).watchCallHistory(uid);
});
