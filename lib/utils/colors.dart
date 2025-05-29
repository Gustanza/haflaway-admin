import 'package:flutter/material.dart';

const primaryColor = Colors.indigo;
const secondaryColor = Colors.blue;
const destructiveColor = Colors.red;

LinearGradient primaryGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primaryColor.withOpacity(1.0), secondaryColor.withOpacity(0.85)],
);
