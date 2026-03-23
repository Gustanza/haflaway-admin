import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const primaryColor = CupertinoColors.systemBlue;
const primaryGreen = Colors.green;
const secondaryColor = Colors.blue;
const destructiveColor = Colors.red;
const scaback = const Color(0xFF1a1a2e);
const primaryWhite = Colors.white;
Color mWhite = Colors.white.withValues(alpha: 0.75);

LinearGradient primaryGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primaryColor.withOpacity(1.0), secondaryColor.withOpacity(0.85)],
);

const scagrad = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
);

var secscagrad = LinearGradient(
  colors: [
    Colors.white.withOpacity(0.2),
    Colors.white.withOpacity(0.1),
    Colors.white.withOpacity(0.05),
  ],
);

Color lqassgradBaseColor = Colors.white.withOpacity(0.15);

var lqassgrad = LinearGradient(
  colors: [
    Colors.white.withOpacity(0.2),
    Colors.white.withOpacity(0.1),
    Colors.white.withOpacity(0.05),
  ],
);
var lqassbdrColor = Colors.white.withOpacity(0.4);

var lqassbdr = Border.all(color: lqassbdrColor, width: 0.5);

class Teme {
  // Backgrounds
  static const bg = Color(0xFF0A0A0A); // near-black page
  static const card = Color(0xFF141414); // card surface
  static const card2 = Color(0xFF1A1A1A); // slightly lighter card

  // Accent — the lime/yellow from the screenshots
  static const lime = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF1E2800);

  // Text
  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);
  static const grey2 = Color(0xFF555555);
  static const grey3 = Color(0xFF333333);

  // ── Typography ─────────────────────────────────────────────────────────────

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
