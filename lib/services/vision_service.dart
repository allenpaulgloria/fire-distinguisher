import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock vision classification service for Fire Distinguisher.
///
/// Simulates heavy neural-network processing with a 1.5-second delay and
/// returns `"NOT FIRE"` most of the time and `"FIRE DETECTED"` ~25% of the time
/// (or on demand when `forceFire` is true).
class VisionService {
  VisionService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const String fireVerdict = 'FIRE DETECTED';
  static const String notFireVerdict = 'NOT FIRE';

  /// Triggers a simulated classification pass.
  ///
  /// Delays for 1.5 seconds and returns `"FIRE DETECTED"` (25% probability,
  /// or 100% if [forceFire] is true) or `"NOT FIRE"` (75% probability).
  Future<String> distinguish({bool forceFire = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (forceFire) {
      return fireVerdict;
    }
    final roll = _random.nextDouble();
    if (roll < 0.25) {
      return fireVerdict;
    }
    return notFireVerdict;
  }
}

/// Riverpod provider for [VisionService].
final visionServiceProvider = Provider<VisionService>((ref) {
  return VisionService();
});
