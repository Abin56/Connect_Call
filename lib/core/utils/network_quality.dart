import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../theme/app_colors.dart';

/// Simplifies ZEGOCLOUD's own [ZegoStreamQualityLevel] down to just
/// Good/Fair/Poor, so the call screen doesn't need to know about
/// ZEGOCLOUD's five-level scale directly.
enum NetworkQuality { good, fair, poor }

extension NetworkQualityFromZego on ZegoStreamQualityLevel {
  NetworkQuality toNetworkQuality() {
    switch (this) {
      case ZegoStreamQualityLevel.Excellent:
      case ZegoStreamQualityLevel.Good:
        return NetworkQuality.good;
      case ZegoStreamQualityLevel.Medium:
        return NetworkQuality.fair;
      case ZegoStreamQualityLevel.Bad:
      case ZegoStreamQualityLevel.Die:
      case ZegoStreamQualityLevel.Unknown:
        return NetworkQuality.poor;
    }
  }
}

extension NetworkQualityDisplay on NetworkQuality {
  String get label {
    switch (this) {
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.poor:
        return 'Poor';
    }
  }

  Color get color {
    switch (this) {
      case NetworkQuality.good:
        return AppColors.success;
      case NetworkQuality.fair:
        return AppColors.warning;
      case NetworkQuality.poor:
        return AppColors.error;
    }
  }
}
