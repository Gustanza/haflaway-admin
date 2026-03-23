import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/components/accessDenied.dart';
import 'package:haflaway/components/moving_gradient_border.dart';
import 'package:haflaway/components/splash_affiliates.dart';
import 'package:haflaway/components/updateAppState.dart';
import 'package:haflaway/models/appState.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/providers/package_provider.dart';
import 'package:haflaway/top_destinations/eventz/navhost.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/gus_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    _initializeAnimations();
    _initializeApp();
    super.initState();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  void _initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 4));
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
      var conte = context.read<PackageProvider>();
      await conte.getAppInfo();
      String bno = conte.buildNumber;
      int buildNumber = int.tryParse(bno) ?? 0;

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

      if (!userSnapshot.exists) {
        if (mounted) {
          navnReplace(context: context, widget: const AccessDenied());
        }
        return;
      }

      if (appStateSnapshot.docs.isEmpty) {
        if (mounted) {
          navnReplace(context: context, widget: const AccessDenied());
        }
        return;
      }

      var appStateDoc = appStateSnapshot.docs.last;
      HAppState hAppState = HAppState.fromMap(
        id: appStateDoc.id,
        map: appStateDoc.data(),
      );

      if (buildNumber < hAppState.buildNumber) {
        if (mounted) {
          navnReplace(
            context: context,
            widget: UpdateAppstate(hAppState: hAppState),
          );
        }
        return;
      }

      Userr userr = Userr.fromMap(userSnapshot.id, userSnapshot.data()!);

      if (!(userr.isActive ?? false)) {
        if (mounted) {
          navnReplace(context: context, widget: const AccessDenied());
        }
        return;
      }

      if (mounted) {
        navnReplace(context: context, widget: const NavHost());
      }
    } catch (e) {
      debugPrint('GateKeeper Error: $e');
      if (mounted) {
        navnReplace(context: context, widget: const OnSplashScreenError());
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GusTheme.obsidian,
      body: Stack(
        children: [
          // ── ambient orbs ───────────────────────────────────────────────────
          Positioned(
            top: -100,
            right: -60,
            child: const _GusOrb(size: 300, color: GusTheme.gold),
          ),
          Positioned(
            bottom: -50,
            left: -60,
            child: const _GusOrb(size: 250, color: Color(0xFF4A6CF7)),
          ),

          // ── main content ───────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MovingGradientBorder(
                      borderRadius: 24,
                      borderWidth: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 60,
                              color: GusTheme.gold.withOpacity(0.9),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "HAFLAWAY",
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: GusTheme.textPrimary,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "PREMIUM EVENT MANAGEMENT",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: GusTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({required this.size, required this.color, this.opacity = 0.08});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
