import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tour_service.dart';

final tourServiceProvider = Provider<TourService>((ref) => TourService());
