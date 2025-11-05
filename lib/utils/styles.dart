import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';

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
    borderRadius: BorderRadiusGeometry.circular(bsm * 2),
    side: BorderSide(width: bdrWidthGen, color: lqassgradBaseColor),
  );
}
