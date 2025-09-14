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

Widget buildPrimaryButton({onTap, isLoading, label}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: kToolbarHeight * 1.1,
      decoration: BoxDecoration(
        gradient:
            isLoading
                ? LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.2),
                  ],
                )
                : primaryGrad,
        borderRadius: BorderRadius.circular(bmd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(bmd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(bmd),
            ),
            child: Center(
              child:
                  isLoading
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: psm),
                          Text(
                            "Please Wait...",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: fsm + 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: psm),
                          Text(
                            "$label",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fsm + 1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    ),
  );
}
