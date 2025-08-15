import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';

modalBtmSheet({required Widget child, required double bdrdm}) {
  return ClipRRect(
    borderRadius: BorderRadiusGeometry.only(
      topLeft: Radius.circular(bdrdm),
      topRight: Radius.circular(bdrdm),
    ),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
            left: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
            right: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
          ),
          borderRadius: BorderRadiusGeometry.only(
            topLeft: Radius.circular(bdrdm),
            topRight: Radius.circular(bdrdm),
          ),
        ),
        padding: EdgeInsets.all(psm),
        child: child,
      ),
    ),
  );
}

glassDialog({required Widget child}) {
  return Dialog(
    elevation: 32,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusGeometry.circular(bmd),
      side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
    ),
    child: ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(bmd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: child,
      ),
    ),
  );
}
