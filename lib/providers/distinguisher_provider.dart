import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/vision_service.dart';

/// Represents the current classification workflow phase.
enum DistinguishPhase {
  idle,
  scanning,
  verdict,
}

/// Immutable state for the Fire Distinguisher classification flow.
class DistinguisherState {
  const DistinguisherState({
    this.phase = DistinguishPhase.idle,
    this.verdict,
  });

  final DistinguishPhase phase;
  final String? verdict;

  bool get isScanning => phase == DistinguishPhase.scanning;
  bool get hasVerdict => phase == DistinguishPhase.verdict && verdict != null;
  bool get isFire => verdict == 'FIRE';

  DistinguisherState copyWith({
    DistinguishPhase? phase,
    String? verdict,
    bool clearVerdict = false,
  }) {
    return DistinguisherState(
      phase: phase ?? this.phase,
      verdict: clearVerdict ? null : (verdict ?? this.verdict),
    );
  }
}

/// Riverpod Notifier that coordinates the "DISTINGUISH" trigger and verdict overlay.
class DistinguisherNotifier extends Notifier<DistinguisherState> {
  @override
  DistinguisherState build() {
    return const DistinguisherState();
  }

  /// Triggers the 1.5-second optical scan and resolves with the verdict.
  Future<void> distinguish() async {
    if (state.isScanning) return;

    state = const DistinguisherState(
      phase: DistinguishPhase.scanning,
    );

    final visionService = ref.read(visionServiceProvider);
    final result = await visionService.distinguish();

    state = DistinguisherState(
      phase: DistinguishPhase.verdict,
      verdict: result,
    );
  }

  /// Dismisses the current verdict overlay and returns to live targeting.
  void dismiss() {
    state = const DistinguisherState(
      phase: DistinguishPhase.idle,
    );
  }
}

/// Provider for [DistinguisherNotifier].
final distinguisherProvider =
    NotifierProvider<DistinguisherNotifier, DistinguisherState>(
  DistinguisherNotifier.new,
);

