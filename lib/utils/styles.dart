import 'package:flutter/material.dart';

const fsm = 15.00;
header1() {
  return const TextStyle(fontSize: fsm * 1.5, fontWeight: FontWeight.bold);
}

normal() {
  return const TextStyle(fontSize: fsm);
}

normalBold() {
  return const TextStyle(fontSize: fsm, fontWeight: FontWeight.bold);
}

filShape() {
  return RoundedRectangleBorder(
    borderRadius: BorderRadiusGeometry.circular(8),
    side: BorderSide(width: 0.5, color: Colors.white.withOpacity(0.3)),
  );
}
