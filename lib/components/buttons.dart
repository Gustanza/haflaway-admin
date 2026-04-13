import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';

lqAssButton({onPressed, label}) {
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

Widget buildPrimaryButton({onTap, isLoading = false, label, iconData}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isLoading ? Colors.grey.withOpacity(0.5) : Color(0xFFC9A84C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Please Wait...",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    iconData ?? Icons.download_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$label",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
