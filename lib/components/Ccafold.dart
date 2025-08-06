import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';

class Ccafold extends StatelessWidget {
  final Widget child;
  const Ccafold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.maxFinite,
      decoration: BoxDecoration(gradient: scagrad),
      child: child,
    );
  }
}
