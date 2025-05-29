import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/top_destinations/navhost.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';

class SpScr extends StatefulWidget {
  const SpScr({super.key});

  @override
  State<SpScr> createState() => _SpScrState();
}

class _SpScrState extends State<SpScr> {
  @override
  void initState() {
    inInit();
    super.initState();
  }

  inInit() async {
    Future.delayed(const Duration(seconds: 6)).whenComplete(() async {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        navnReplace(context: context, widget: const NavHost());
      } else {
        navnReplace(context: context, widget: const Login());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: psm * 2),
            Text(
              "HAFLAWAY LOADING...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
