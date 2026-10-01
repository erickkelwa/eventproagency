import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  _ScanResult? _lastResult;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  Future<void> _handleScan(String qrCode) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      final response = await DioClient.instance.dio.post(
        ApiConstants.adminCheckIn,
        data: {'qr_code': qrCode},
      );

      final data = response.data;
      setState(() {
        _lastResult = _ScanResult(
          success: true,
          attendeeName: data['attendee_name'] as String? ?? 'Attendee',
          eventTitle: data['event_title'] as String? ?? 'Event',
          ticketId: qrCode,
          message: data['message'] as String? ?? 'Check-in successful!',
        );
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _lastResult = _ScanResult(
          success: false,
          attendeeName: '',
          eventTitle: '',
          ticketId: qrCode,
          message: 'Invalid or already used ticket.',
        );
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera View ──────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final code = barcodes.first.rawValue;
                if (code != null) _handleScan(code);
              }
            },
          ),

          // ── Dark Overlay with Scan Window ─────────────
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ScanOverlayPainter(),
          ),

          // ── Top Bar ─────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'QR Check-In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _torchOn = !_torchOn);
                      _controller?.toggleTorch();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _torchOn
                            ? AppColors.primary.withValues(alpha: 0.8)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _torchOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scan Instruction ─────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: 0,
            right: 0,
            child: const Column(
              children: [
                Text(
                  'Point camera at ticket QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ── Animated Scanner Line ─────────────────────────
          if (_isProcessing)
            Center(
              child: Container(
                width: 260,
                height: 260,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),

          // ── Result Card ────────────────────────────────────
          if (_lastResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: Offset.zero,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _ResultCard(
                  result: _lastResult!,
                  onDismiss: () =>
                      setState(() => _lastResult = null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Result Card ────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final _ScanResult result;
  final VoidCallback onDismiss;

  const _ResultCard({required this.result, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = result.success ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.success
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: color,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.success ? 'Check-In Successful!' : 'Invalid Ticket',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (result.success) ...[
            Text(
              result.attendeeName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.eventTitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ] else
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Scan Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Scan Overlay Painter ───────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const windowSize = 260.0;
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;

    final window = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: windowSize,
      height: windowSize,
    );

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);

    // Draw overlay around the scan window
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(window, const Radius.circular(20)),
          ),
      ),
      bgPaint,
    );

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const r = 20.0;

    // Top-left
    canvas.drawLine(Offset(window.left + r, window.top),
        Offset(window.left + r + cornerLength, window.top), cornerPaint);
    canvas.drawLine(Offset(window.left, window.top + r),
        Offset(window.left, window.top + r + cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(window.right - r, window.top),
        Offset(window.right - r - cornerLength, window.top), cornerPaint);
    canvas.drawLine(Offset(window.right, window.top + r),
        Offset(window.right, window.top + r + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(window.left + r, window.bottom),
        Offset(window.left + r + cornerLength, window.bottom), cornerPaint);
    canvas.drawLine(Offset(window.left, window.bottom - r),
        Offset(window.left, window.bottom - r - cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(window.right - r, window.bottom),
        Offset(window.right - r - cornerLength, window.bottom), cornerPaint);
    canvas.drawLine(Offset(window.right, window.bottom - r),
        Offset(window.right, window.bottom - r - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Scan Result Data ───────────────────────────────────────
class _ScanResult {
  final bool success;
  final String attendeeName;
  final String eventTitle;
  final String ticketId;
  final String message;

  const _ScanResult({
    required this.success,
    required this.attendeeName,
    required this.eventTitle,
    required this.ticketId,
    required this.message,
  });
}