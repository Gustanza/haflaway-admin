import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:haflaway/utils/dimensions.dart';

Widget fabb({mini, heroTag, child, onPressed}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(bsm * 40),
      border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(bsm * 40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: FloatingActionButton(
          heroTag: heroTag,
          mini: mini ?? false,
          backgroundColor: Colors.transparent,
          child: child,
          onPressed: onPressed,
        ),
      ),
    ),
  );
}
