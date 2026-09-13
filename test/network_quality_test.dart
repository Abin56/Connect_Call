import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/core/utils/network_quality.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

void main() {
  group('NetworkQualityFromZego', () {
    test('maps Excellent and Good to good', () {
      expect(
        ZegoStreamQualityLevel.Excellent.toNetworkQuality(),
        NetworkQuality.good,
      );
      expect(
        ZegoStreamQualityLevel.Good.toNetworkQuality(),
        NetworkQuality.good,
      );
    });

    test('maps Medium to fair', () {
      expect(
        ZegoStreamQualityLevel.Medium.toNetworkQuality(),
        NetworkQuality.fair,
      );
    });

    test('maps Bad, Die and Unknown to poor', () {
      expect(
        ZegoStreamQualityLevel.Bad.toNetworkQuality(),
        NetworkQuality.poor,
      );
      expect(
        ZegoStreamQualityLevel.Die.toNetworkQuality(),
        NetworkQuality.poor,
      );
      expect(
        ZegoStreamQualityLevel.Unknown.toNetworkQuality(),
        NetworkQuality.poor,
      );
    });
  });

  group('NetworkQualityDisplay', () {
    test('every level has a non-empty label', () {
      for (final level in NetworkQuality.values) {
        expect(level.label, isNotEmpty);
      }
    });
  });
}
