import 'package:flutter/material.dart';

const primaryColor = Colors.indigo;
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

Color lqassgradBaseColor = Colors.white.withOpacity(0.15);

var lqassgrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    lqassgradBaseColor,
    Colors.white.withOpacity(0.1),
    Colors.white.withOpacity(0.08),
  ],
);
var lqassbdrColor = Colors.white.withOpacity(0.4);

var lqassbdr = Border.all(color: lqassbdrColor, width: 0.5);
