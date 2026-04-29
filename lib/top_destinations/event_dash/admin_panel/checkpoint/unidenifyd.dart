import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg   = Color(0xFF111114);
  static const card = Color(0xFF1C1C1E);
  static const sep  = Color(0xFF2C2C2E);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const lbl1 = Color(0xFFEEEEF0);
  static const lbl3 = Color(0xFF8E8E93);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// UnIndenifyd
// ─────────────────────────────────────────────────────────────────────────────

class UnIndenifyd extends StatelessWidget {
  final Function() onTap;
  const UnIndenifyd({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            // Ambient orb
            const Positioned(
              top: -80,
              right: -80,
              child: _GusOrb(size: 280, color: _T.lime, opacity: 0.08),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back pill
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _T.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _T.sep, width: 0.8),
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

                  // Centered content
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Warning icon badge
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _T.lime.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _T.lime.withValues(alpha: 0.22),
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: _T.lime,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Unrecognized QR Code',
                              style: _T.f(
                                size: 20,
                                weight: FontWeight.w700,
                                color: _T.lbl1,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "This QR code isn't linked to a Haflaway attendee.",
                              style: _T.f(size: 14, color: _T.lbl3, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            // Keep scanning button
                            GestureDetector(
                              onTap: onTap,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: _T.lime,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _T.lime.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Keep Scanning',
                                      style: _T.f(
                                        size: 15,
                                        weight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient orb
// ─────────────────────────────────────────────────────────────────────────────

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({required this.size, required this.color, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
