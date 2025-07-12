import 'package:flutter/material.dart';

const primaryColor = Colors.indigo;
const secondaryColor = Colors.blue;
const destructiveColor = Colors.red;
const scaback = const Color(0xFF1a1a2e);

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
