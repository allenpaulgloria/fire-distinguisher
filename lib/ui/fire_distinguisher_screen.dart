import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/distinguisher_provider.dart';
import '../services/camera_service.dart';

/// Industrial color palette constants.
class IndustrialColors {
  static const Color backgroundDark = Color(0xFF111315);
  static const Color panelGrey = Color(0xFF1B1F23);
  static const Color steelBorder = Color(0xFF333940);
  static const Color safetyOrange = Color(0xFFFF5500);
  static const Color hazardAmber = Color(0xFFFFB300);
  static const Color fireRed = Color(0xFFFF2A00);
  static const Color readoutWhite = Color(0xFFF2F4F7);
  static const Color mutedSteel = Color(0xFF8C96A2);
}

/// Main screen of the Fire Distinguisher satirical gag app.
class FireDistinguisherScreen extends ConsumerStatefulWidget {
  const FireDistinguisherScreen({super.key});

  @override
  ConsumerState<FireDistinguisherScreen> createState() =>
      _FireDistinguisherScreenState();
}

class _FireDistinguisherScreenState
    extends ConsumerState<FireDistinguisherScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraServiceProvider.notifier).initializeCamera();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(cameraServiceProvider.notifier).handleAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraServiceProvider);
    final distinguishState = ref.watch(distinguisherProvider);

    return Scaffold(
      backgroundColor: IndustrialColors.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen live camera preview (or industrial fallback/status view)
          _buildCameraViewport(cameraState),

          // 2. Subtle vignette & industrial HUD grid framing
          const IgnorePointer(
            child: _IndustrialViewportVignette(),
          ),

          // 3. Minimalist crosshair overlay in the center of the camera view
          Center(
            child: IgnorePointer(
              child: _MinimalistCrosshair(
                isScanning: distinguishState.isScanning,
              ),
            ),
          ),

          // 4. Top industrial header bar
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildTopHudBar(cameraState, distinguishState),
            ),
          ),

          // 5. Scanning animation & progress indicator overlay when triggered
          if (distinguishState.isScanning)
            _ScanningOverlay(animation: _scanAnimationController),

          // 6. Bottom industrial "DISTINGUISH" button control deck
          if (!distinguishState.hasVerdict)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomControlDeck(distinguishState),
              ),
            ),

          // 7. Massive, bold text overlay showing the verdict + "Dismiss" button
          if (distinguishState.hasVerdict)
            _VerdictOverlay(
              verdict: distinguishState.verdict!,
              isFire: distinguishState.isFire,
              onDismiss: () {
                HapticFeedback.lightImpact();
                ref.read(distinguisherProvider.notifier).dismiss();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCameraViewport(CameraState cameraState) {
    if (cameraState.isReady && cameraState.controller != null) {
      final controller = cameraState.controller!;
      final previewSize = controller.value.previewSize;

      if (previewSize != null) {
        return ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      }
      return SizedBox.expand(
        child: CameraPreview(controller),
      );
    }

    // Status / permission / loading fallback inside the viewport
    return Container(
      color: IndustrialColors.backgroundDark,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cameraState.status == CameraStatus.initializing ||
                cameraState.status == CameraStatus.requestingPermission ||
                cameraState.status == CameraStatus.initial) ...[
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: IndustrialColors.safetyOrange,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'CALIBRATING OPTICAL SENSOR...',
                textAlign: TextAlign.center,
                style: GoogleFonts.shareTechMono(
                  color: IndustrialColors.mutedSteel,
                  fontSize: 14,
                  letterSpacing: 2.0,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.warning_amber_rounded,
                color: IndustrialColors.safetyOrange,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                cameraState.errorMessage ?? 'OPTICAL FEED OFFLINE',
                textAlign: TextAlign.center,
                style: GoogleFonts.shareTechMono(
                  color: IndustrialColors.readoutWhite,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  if (cameraState.status == CameraStatus.permissionDenied) {
                    await openAppSettings();
                  }
                  await ref
                      .read(cameraServiceProvider.notifier)
                      .initializeCamera();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: IndustrialColors.safetyOrange,
                  side: const BorderSide(
                    color: IndustrialColors.safetyOrange,
                    width: 1.5,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'REINITIALIZE SENSOR',
                  style: GoogleFonts.shareTechMono(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopHudBar(
    CameraState cameraState,
    DistinguisherState distinguishState,
  ) {
    final bool sensorOnline = cameraState.isReady;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: IndustrialColors.panelGrey.withValues(alpha: 0.88),
        border: Border.all(
          color: IndustrialColors.steelBorder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: distinguishState.isScanning
                  ? IndustrialColors.hazardAmber
                  : (sensorOnline
                        ? IndustrialColors.safetyOrange
                        : Colors.redAccent),
              boxShadow: [
                BoxShadow(
                  color: IndustrialColors.safetyOrange.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FIRE DISTINGUISHER // MK-IV',
                  style: GoogleFonts.oswald(
                    color: IndustrialColors.readoutWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  distinguishState.isScanning
                      ? 'STATUS: THERMAL-OPTICAL ANALYSIS IN PROGRESS'
                      : 'STATUS: READY FOR TARGET ACQUISITION',
                  style: GoogleFonts.shareTechMono(
                    color: IndustrialColors.mutedSteel,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: IndustrialColors.backgroundDark,
              border: Border.all(color: IndustrialColors.steelBorder),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              'REV 1.0',
              style: GoogleFonts.shareTechMono(
                color: IndustrialColors.safetyOrange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlDeck(DistinguisherState distinguishState) {
    final bool isScanning = distinguishState.isScanning;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialColors.panelGrey.withValues(alpha: 0.92),
        border: Border.all(
          color: IndustrialColors.steelBorder,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTUATION MODULE // PRIMARY TRIGGER',
                style: GoogleFonts.shareTechMono(
                  color: IndustrialColors.mutedSteel,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                isScanning ? 'BUSY' : 'ARMED',
                style: GoogleFonts.shareTechMono(
                  color: isScanning
                      ? IndustrialColors.hazardAmber
                      : IndustrialColors.safetyOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ElevatedButton(
              onPressed: isScanning
                  ? null
                  : () {
                      HapticFeedback.heavyImpact();
                      ref.read(distinguisherProvider.notifier).distinguish();
                    },
              onLongPress: isScanning
                  ? null
                  : () {
                      HapticFeedback.heavyImpact();
                      ref
                          .read(distinguisherProvider.notifier)
                          .distinguish(forceFire: true);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: IndustrialColors.safetyOrange,
                disabledBackgroundColor:
                    IndustrialColors.safetyOrange.withValues(alpha: 0.35),
                foregroundColor: IndustrialColors.backgroundDark,
                disabledForegroundColor:
                    IndustrialColors.readoutWhite.withValues(alpha: 0.6),
                elevation: isScanning ? 0 : 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(
                    color: isScanning
                        ? IndustrialColors.steelBorder
                        : const Color(0xFFFF8547),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isScanning
                        ? Icons.radar_rounded
                        : Icons.local_fire_department_rounded,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isScanning ? 'DISTINGUISHING...' : 'DISTINGUISH',
                    style: GoogleFonts.oswald(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimalist industrial crosshair overlay in the center of the camera view.
class _MinimalistCrosshair extends StatelessWidget {
  const _MinimalistCrosshair({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final Color reticleColor = isScanning
        ? IndustrialColors.safetyOrange
        : IndustrialColors.readoutWhite.withValues(alpha: 0.78);

    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _CrosshairPainter(
          color: reticleColor,
          accentColor: IndustrialColors.safetyOrange,
          isScanning: isScanning,
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({
    required this.color,
    required this.accentColor,
    required this.isScanning,
  });

  final Color color;
  final Color accentColor;
  final bool isScanning;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final mainPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Center minimalist crosshair lines with a small gap around the bullseye
    const double gap = 12.0;
    const double armLength = 34.0;

    // Horizontal ticks
    canvas.drawLine(
      Offset(center.dx - gap - armLength, center.dy),
      Offset(center.dx - gap, center.dy),
      mainPaint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + gap + armLength, center.dy),
      mainPaint,
    );

    // Vertical ticks
    canvas.drawLine(
      Offset(center.dx, center.dy - gap - armLength),
      Offset(center.dx, center.dy - gap),
      mainPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + gap + armLength),
      mainPaint,
    );

    // Center precision dot
    canvas.drawCircle(
      center,
      2.5,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    // Outer corner brackets
    const double bracketLen = 22.0;
    final double w = size.width;
    final double h = size.height;

    final bracketPaint = isScanning ? accentPaint : mainPaint;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(bracketLen, 0), bracketPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, bracketLen), bracketPaint);

    // Top-right
    canvas.drawLine(Offset(w - bracketLen, 0), Offset(w, 0), bracketPaint);
    canvas.drawLine(Offset(w, 0), Offset(w, bracketLen), bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(0, h - bracketLen), Offset(0, h), bracketPaint);
    canvas.drawLine(Offset(0, h), Offset(bracketLen, h), bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(w - bracketLen, h), Offset(w, h), bracketPaint);
    canvas.drawLine(Offset(w, h - bracketLen), Offset(w, h), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isScanning != isScanning;
  }
}

/// Scanning animation and progress indicator overlay over the camera view.
class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated horizontal laser sweep inside the target zone
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, (animation.value * 2) - 1),
                    child: Container(
                      height: 3,
                      width: 216,
                      decoration: BoxDecoration(
                        color: IndustrialColors.safetyOrange,
                        boxShadow: [
                          BoxShadow(
                            color: IndustrialColors.safetyOrange
                                .withValues(alpha: 0.85),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Center-bottom telemetry & progress readout
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 290),
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: IndustrialColors.panelGrey.withValues(alpha: 0.95),
                  border: Border.all(
                    color: IndustrialColors.safetyOrange,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LinearProgressIndicator(
                      color: IndustrialColors.safetyOrange,
                      backgroundColor: IndustrialColors.backgroundDark,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ANALYZING THERMAL SIGNATURE...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        color: IndustrialColors.readoutWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'COMPARING AGAINST COMBUSTION DATABASE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        color: IndustrialColors.mutedSteel,
                        fontSize: 10,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Massive, bold text overlay showing the verdict ("NOT FIRE" or "FIRE")
/// in a stark, deadpan font with a "Dismiss" button to reset.
class _VerdictOverlay extends StatelessWidget {
  const _VerdictOverlay({
    required this.verdict,
    required this.isFire,
    required this.onDismiss,
  });

  final String verdict;
  final bool isFire;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        isFire ? IndustrialColors.fireRed : IndustrialColors.safetyOrange;

    return Container(
      color: Colors.black.withValues(alpha: 0.84),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 36,
              ),
              decoration: BoxDecoration(
                color: IndustrialColors.panelGrey,
                border: Border.all(
                  color: accentColor,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      border: Border.all(color: accentColor, width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'OFFICIAL CLASSIFICATION VERDICT',
                      style: GoogleFonts.shareTechMono(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      verdict,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.oswald(
                        color: isFire
                            ? IndustrialColors.fireRed
                            : IndustrialColors.readoutWhite,
                        fontSize: 88,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    color: IndustrialColors.steelBorder,
                    thickness: 1.5,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFire
                        ? 'COMBUSTION EVENT CONFIRMED. EVACUATE OR MARSHMALLOW.'
                        : 'NO ACTIVE COMBUSTION DETECTED IN TARGET SECTOR.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      color: IndustrialColors.mutedSteel,
                      fontSize: 12,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: IndustrialColors.panelGrey,
                  foregroundColor: IndustrialColors.readoutWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(
                      color: IndustrialColors.safetyOrange,
                      width: 2,
                    ),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(
                  Icons.replay_rounded,
                  color: IndustrialColors.safetyOrange,
                ),
                label: Text(
                  'DISMISS',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle industrial vignette around the camera edges.
class _IndustrialViewportVignette extends StatelessWidget {
  const _IndustrialViewportVignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
          ],
          stops: const [0.6, 1.0],
        ),
      ),
    );
  }
}
