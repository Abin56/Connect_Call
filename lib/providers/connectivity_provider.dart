import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the device has some kind of network connection (wifi,
/// mobile, ethernet), false when there's [ConnectivityResult.none]. This
/// doesn't confirm the internet is actually reachable, just that a
/// network is active -- good enough to warn the user and stop new calls.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);

  yield* connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});
