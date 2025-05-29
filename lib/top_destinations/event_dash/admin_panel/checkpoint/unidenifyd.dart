import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:haflaway/utils/styles.dart';

class UnIndenifyd extends StatelessWidget {
  final Function() onTap;
  const UnIndenifyd({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(size: icnmd * 3, Clarity.warning_line),
            const SizedBox(height: psm * 0.5),
            const Text(
              unidenify,
              style: TextStyle(fontSize: fsm, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: psm),
            ElevatedButton.icon(
              onPressed: () {
                onTap();
              },
              label: const Text("Keep Scanning"),
              icon: const Icon(Clarity.repeat_line),
            ),
          ],
        ),
      ),
    );
  }
}
