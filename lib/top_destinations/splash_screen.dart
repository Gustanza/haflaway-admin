import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/components/accessDenied.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/updateAppState.dart';
import 'package:haflaway/models/appState.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/top_destinations/eventz/navhost.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    inInit();
    super.initState();
  }

  inInit() async {
    Future.delayed(const Duration(seconds: 6)).whenComplete(() async {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        gateKeep(userId: userId);
      } else {
        navnReplace(context: context, widget: const Login());
      }
    });
  }

  gateKeep({userId}) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await firestore.collection(ucol).doc(userId).get();
      QuerySnapshot<Map<String, dynamic>> appStateSnapshot =
          await firestore
              .collection(hAppStateCol)
              .orderBy("createdAt", descending: true)
              .limitToLast(1)
              .get();
      if (userSnapshot.exists && appStateSnapshot.docs.isNotEmpty) {
        var appStateDoc = appStateSnapshot.docs.last;
        HAppState hAppState = HAppState.fromMap(
          id: appStateDoc.id,
          map: appStateDoc.data(),
        );
        if (buildNumber >= hAppState.buildNumber) {
          Userr userr = Userr.fromMap(userSnapshot.id, userSnapshot.data()!);
          if (userr.isActive) {
            navnReplace(context: context, widget: const NavHost());
          } else {
            navnReplace(context: context, widget: const AccessDenied());
          }
        } else {
          navnReplace(
            context: context,
            widget: UpdateAppstate(hAppState: hAppState),
          );
        }
      } else {
        navnReplace(context: context, widget: const AccessDenied());
      }
    } catch (e) {
      navnReplace(context: context, widget: const OnSplashScreenError());
    }
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

class OnSplashScreenError extends StatelessWidget {
  const OnSplashScreenError({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(title: "Haflaway Info"),
      body: Center(
        child: TextButton(onPressed: () {}, child: Text("Restart App")),
      ),
    );
  }
}
