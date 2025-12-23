import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/components/accessDenied.dart';
import 'package:haflaway/components/splash_affiliates.dart';
import 'package:haflaway/components/updateAppState.dart';
import 'package:haflaway/models/appState.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/top_destinations/eventz/navhost.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    _initializeAnimations();
    _initializeApp();
    super.initState();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  void _initializeApp() async {
    try {
      await Future.delayed(Duration(seconds: 5));
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        await _gateKeeper(userId: userId);
      } else {
        if (mounted) {
          navnReplace(context: context, widget: const Login());
        }
      }
    } catch (e) {
      if (mounted) {
        navnReplace(context: context, widget: const OnSplashScreenError());
      }
    }
  }

  Future<void> _gateKeeper({required String userId}) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Parallel execution for better performance
      final futures = await Future.wait([
        firestore.collection(ucol).doc(userId).get(),
        firestore
            .collection(hAppStateCol)
            .orderBy("createdAt", descending: true)
            .limitToLast(1)
            .get(),
      ]);

      final userSnapshot = futures[0] as DocumentSnapshot<Map<String, dynamic>>;
      final appStateSnapshot =
          futures[1] as QuerySnapshot<Map<String, dynamic>>;

      // Check if user exists
      if (!userSnapshot.exists) {
        if (mounted) {
          navnReplace(context: context, widget: const AccessDenied());
        }
        return;
      }

      // Check if app state exists
      if (appStateSnapshot.docs.isEmpty) {
        if (mounted) {
          navnReplace(context: context, widget: const AccessDenied());
        }
        return;
      }

      // Parse app state
      var appStateDoc = appStateSnapshot.docs.last;
      HAppState hAppState = HAppState.fromMap(
        id: appStateDoc.id,
        map: appStateDoc.data(),
      );

      // Check app version
      if (buildNumber < hAppState.buildNumber) {
        if (mounted) {
          navnReplace(
            context: context,
            widget: UpdateAppstate(hAppState: hAppState),
          );
        }
        return;
      }

      // Parse user data
      Userr userr = Userr.fromMap(userSnapshot.id, userSnapshot.data()!);

      // Check user status
      if (!(userr.isActive ?? false)) {
        if (mounted) {
          navnReplace(context: context, widget: const AccessDenied());
        }
        return;
      }

      // All checks passed - navigate to main app
      if (mounted) {
        navnReplace(context: context, widget: const NavHost());
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('GateKeeper Error: $e');
      if (mounted) {
        navnReplace(context: context, widget: const OnSplashScreenError());
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: scagrad),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Logo Container with Multiple Effects
                  // AnimatedBuilder(
                  //   animation: _pulseAnimation,
                  //   builder: (context, child) {
                  //     return Transform.scale(
                  //       scale: _pulseAnimation.value,
                  //       child: Container(
                  //         width: 160,
                  //         height: 160,
                  //         decoration: BoxDecoration(
                  //           gradient: LinearGradient(
                  //             colors: [
                  //               primaryColor.withOpacity(0.9),
                  //               secondaryColor.withOpacity(0.8),
                  //               Colors.purple.withOpacity(0.6),
                  //             ],
                  //           ),
                  //           borderRadius: BorderRadius.circular(40),
                  //         ),
                  //         child: ClipRRect(
                  //           borderRadius: BorderRadius.circular(40),
                  //           child: BackdropFilter(
                  //             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  //             child: Container(
                  //               decoration: BoxDecoration(
                  //                 border: Border.all(
                  //                   color: Colors.white.withOpacity(0.3),
                  //                   width: 1,
                  //                 ),
                  //                 borderRadius: BorderRadius.circular(40),
                  //               ),
                  //               child: Center(
                  //                 child: AnimatedBuilder(
                  //                   animation: _rotateAnimation,
                  //                   builder: (context, child) {
                  //                     return Transform.rotate(
                  //                       angle:
                  //                           _rotateAnimation.value *
                  //                           2 *
                  //                           3.14159,
                  //                       child: Icon(
                  //                         size: 80,
                  //                         Icons.qr_code_scanner,
                  //                         color: Colors.white,
                  //                       ),
                  //                     );
                  //                   },
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),

                  // const SizedBox(height: psm * 3),

                  // App Name with Glassmorphism
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: psm * 2,
                      vertical: psm,
                    ),
                    decoration: BoxDecoration(
                      gradient: secscagrad,
                      borderRadius: BorderRadius.circular(bmd),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      "HAFLAWAY",
                      style: TextStyle(
                        fontSize: fsm * 2.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
