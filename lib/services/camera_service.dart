import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents the current lifecycle and readiness state of the device camera.
enum CameraStatus {
  initial,
  requestingPermission,
  permissionDenied,
  initializing,
  ready,
  error,
}

/// Immutable state managed by [CameraService].
class CameraState {
  const CameraState({
    this.status = CameraStatus.initial,
    this.controller,
    this.errorMessage,
  });

  final CameraStatus status;
  final CameraController? controller;
  final String? errorMessage;

  bool get isReady =>
      status == CameraStatus.ready &&
      controller != null &&
      controller!.value.isInitialized;

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    String? errorMessage,
    bool clearController = false,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: clearController ? null : (controller ?? this.controller),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Service that manages [CameraController] initialization, camera permissions,
/// and lifecycle disposal via Riverpod.
class CameraService extends Notifier<CameraState> {
  List<CameraDescription> _cameras = const [];
  bool _isDisposed = false;

  @override
  CameraState build() {
    _isDisposed = false;
    ref.onDispose(_disposeController);
    return const CameraState();
  }

  /// Requests camera permission and initializes the primary back camera.
  Future<void> initializeCamera() async {
    if (state.status == CameraStatus.initializing ||
        state.status == CameraStatus.requestingPermission) {
      return;
    }

    state = state.copyWith(
      status: CameraStatus.requestingPermission,
      errorMessage: null,
    );

    try {
      final permissionStatus = await Permission.camera.request();
      if (_isDisposed) return;

      if (!permissionStatus.isGranted) {
        state = state.copyWith(
          status: CameraStatus.permissionDenied,
          errorMessage: 'CAMERA PERMISSION REQUIRED FOR OPTICAL FIRE ANALYSIS.',
        );
        return;
      }

      state = state.copyWith(status: CameraStatus.initializing);

      _cameras = await availableCameras();
      if (_isDisposed) return;

      if (_cameras.isEmpty) {
        state = state.copyWith(
          status: CameraStatus.error,
          errorMessage: 'NO OPTICAL SENSOR DETECTED ON THIS UNIT.',
        );
        return;
      }

      // Prefer the rear-facing camera, falling back to the first available sensor.
      final selectedCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      await _initControllerForCamera(selectedCamera);
    } catch (e, stackTrace) {
      debugPrint('CameraService initialization error: $e\n$stackTrace');
      if (!_isDisposed) {
        state = state.copyWith(
          status: CameraStatus.error,
          errorMessage: 'OPTICAL SENSOR INITIALIZATION FAILURE: $e',
        );
      }
    }
  }

  Future<void> _initControllerForCamera(CameraDescription description) async {
    final previousController = state.controller;
    if (previousController != null) {
      state = state.copyWith(clearController: true);
      await previousController.dispose();
    }

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (_isDisposed) {
        await controller.dispose();
        return;
      }
      state = CameraState(
        status: CameraStatus.ready,
        controller: controller,
      );
    } catch (e) {
      await controller.dispose();
      if (!_isDisposed) {
        state = state.copyWith(
          status: CameraStatus.error,
          errorMessage: 'FAILED TO INITIALIZE CAMERA STREAM: $e',
          clearController: true,
        );
      }
    }
  }

  /// Handles Android/iOS app lifecycle transitions cleanly.
  Future<void> handleAppLifecycleState(AppLifecycleState lifecycleState) async {
    final controller = state.controller;
    if (lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.paused) {
      if (controller != null && controller.value.isInitialized) {
        state = state.copyWith(
          status: CameraStatus.initial,
          clearController: true,
        );
        await controller.dispose();
      }
    } else if (lifecycleState == AppLifecycleState.resumed) {
      if (state.controller == null &&
          state.status != CameraStatus.permissionDenied) {
        await initializeCamera();
      }
    }
  }

  void _disposeController() {
    _isDisposed = true;
    final controller = state.controller;
    if (controller != null) {
      controller.dispose();
    }
  }
}

/// Riverpod provider exposing [CameraService] and its [CameraState].
final cameraServiceProvider =
    NotifierProvider<CameraService, CameraState>(CameraService.new);

