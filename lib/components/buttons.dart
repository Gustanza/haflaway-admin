import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';

buildLqAssButton({onPressed, label}) {
  return GestureDetector(
    onTap: onPressed ?? () {},
    child: Container(
      width: double.maxFinite,
      height: kToolbarHeight * 0.85,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(bxsm),
        gradient: lqassgrad,
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Text(
        "$label",
        style: TextStyle(fontSize: fsm + 2, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
