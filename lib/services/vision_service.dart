import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock vision classification service for Fire Distinguisher.
///
/// Simulates heavy neural-network processing with a 1.5-second delay and
/// returns `"NOT FIRE"` 95% of the time and `"FIRE"` 5% of the time.
class VisionService {
  VisionService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Triggers a simulated classification pass.
  ///
  /// Delays for 1.5 seconds and returns `"FIRE"` (5% probability) or
  /// `"NOT FIRE"` (95% probability).
  Future<String> distinguish() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final roll = _random.nextDouble();
    if (roll < 0.05) {
      return 'FIRE';
    }
    return 'NOT FIRE';
  }
}

/// Riverpod provider for [VisionService].
final visionServiceProvider = Provider<VisionService>((ref) {
  return VisionService();
});

