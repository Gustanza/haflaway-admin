import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/resolver.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/unidenifyd.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const lime  = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const lbl1  = Color(0xFFEEEEF0);
  static const lbl2  = Color(0xFFAEAEB2);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
  }) => GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner
// ─────────────────────────────────────────────────────────────────────────────

class Scanner extends StatefulWidget {
  final List acIds;
  final String chckpntId;
  final String eId;

  const Scanner({
    super.key,
    required this.eId,
    required this.acIds,
    required this.chckpntId,
  });

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  late MobileScannerController controller;
  final ValueNotifier<String?> urlNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    urlNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera — base layer ──────────────────────────────────────────
            MobileScanner(
              controller: controller,
              placeholderBuilder: (_, __) => Container(
                color: Colors.black,
                child: const Center(
                  child: CupertinoActivityIndicator(color: _T.lime),
                ),
              ),
              onDetect: (capture) async {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode != null) {
                  urlNotifier.value = barcode.rawValue;
                  await controller.stop();
                }
              },
            ),

            // ── UI layer — overlaid on camera ────────────────────────────────
            ValueListenableBuilder<String?>(
              valueListenable: urlNotifier,
              builder: (context, value, _) {
                if (value == null) {
                  return _ScanOverlay(onBack: () => Navigator.of(context).pop());
                }
                if (_isHWay(value)) {
                  final parts = _parseHFrl(value);
                  if (parts != null) return _buildAttendeeView(parts.last);
                }
                return UnIndenifyd(
                  onTap: () async {
                    urlNotifier.value = null;
                    await controller.start();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isHWay(String s) => s.startsWith(hfweb);

  List? _parseHFrl(String url) {
    final parts = url.split('/lv0/');
    if (parts.length > 1) return parts.last.split('/');
    return null;
  }

  Widget _buildAttendeeView(dynamic attId) {
    return AttendeeCheckInView(
      attId: attId,
      chckpntId: widget.chckpntId,
      eId: widget.eId,
      onPressed: () async {
        urlNotifier.value = null;
        await controller.start();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan overlay — shown while camera is active
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final VoidCallback onBack;
  const _ScanOverlay({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
            ),
          ),
        ),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back pill
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _T.lime,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Back',
                          style: _T.f(
                            size: 13,
                            weight: FontWeight.w500,
                            color: _T.lbl1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Reticle
              const Center(child: _ScanReticle()),
              const SizedBox(height: 28),

              // Hint pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Point camera at attendee QR code',
                    style: _T.f(size: 13, color: _T.lbl2),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan reticle — four lime corner brackets
// ─────────────────────────────────────────────────────────────────────────────

class _ScanReticle extends StatelessWidget {
  const _ScanReticle();

  @override
  Widget build(BuildContext context) {
    const double size = 230;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
          Positioned(
            bottom: 0,
            right: 0,
            child: _Corner(top: false, left: false),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(painter: _CornerPainter(top: top, left: left)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = _T.lime
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    if (top && left) {
      canvas.drawLine(Offset(0, h), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
    } else if (top && !left) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(w, h), Offset(0, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
