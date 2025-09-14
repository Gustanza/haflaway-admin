import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/utils/colors.dart';

class AccessDenied extends StatefulWidget {
  const AccessDenied({super.key});

  @override
  State<AccessDenied> createState() => _AccessDeniedState();
}

class _AccessDeniedState extends State<AccessDenied> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(title: "Haflaway Info"),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(gradient: scagrad),
        child: Center(child: Text("Access Limited")),
      ),
    );
  }
}
