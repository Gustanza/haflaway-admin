import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class OnSplashScreenError extends StatefulWidget {
  const OnSplashScreenError({super.key});

  @override
  State<OnSplashScreenError> createState() => _OnSplashScreenErrorState();
}

class _OnSplashScreenErrorState extends State<OnSplashScreenError> {
  bool _isRestarting = false;

  Future<void> _restartApp() async {
    setState(() {
      _isRestarting = true;
    });

    try {
      // Add a small delay to show the loading state
      await Future.delayed(const Duration(milliseconds: 500));

      // Phoenix rebirth - restart the entire app
      Phoenix.rebirth(context);
    } catch (e) {
      _showErrorSnackBar('Error restarting app: $e');
      setState(() {
        _isRestarting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: destructiveColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(bmd)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(title: "Loading Error"),
      body: Container(
        decoration: const BoxDecoration(gradient: scagrad),
        child: SafeArea(
          child: Column(
            children: [
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(p20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Error Message Card with Enhanced Design
                      buildGlassCard(
                        child: Container(
                          padding: const EdgeInsets.all(psm * 2),
                          decoration: BoxDecoration(
                            gradient: secscagrad,
                            borderRadius: BorderRadius.circular(bmd),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Loading Failed",
                                style: TextStyle(
                                  fontSize: fsm * 1.8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: psm),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: psm,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.withOpacity(0.3),
                                      Colors.red.withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.4),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  "Splash Error",
                                  style: TextStyle(
                                    fontSize: fsm * 0.9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade300,
                                  ),
                                ),
                              ),

                              const SizedBox(height: psm * 1.5),

                              Text(
                                "Something went wrong while loading the app. Don't worry, this happens sometimes!",
                                style: TextStyle(
                                  fontSize: fsm,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: psm * 2),

                              // Solution Cards
                              _buildSolutionCard(
                                icon: Icons.refresh_rounded,
                                title: "Quick Fix",
                                subtitle:
                                    "Restart the app to resolve the issue",
                                gradient: [
                                  Colors.green.withOpacity(0.3),
                                  Colors.blue.withOpacity(0.2),
                                ],
                              ),

                              const SizedBox(height: psm),

                              _buildSolutionCard(
                                icon: Icons.auto_awesome_rounded,
                                title: "Phoenix Rebirth",
                                subtitle:
                                    "Complete app restart with fresh state",
                                gradient: [
                                  Colors.purple.withOpacity(0.3),
                                  Colors.pink.withOpacity(0.2),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: psm * 2),

                      // Restart Button with Enhanced Design
                      buildPrimaryButton(
                        isLoading: _isRestarting,
                        label: "Restart App",
                        onTap: _isRestarting ? null : _restartApp,
                      ),

                      const SizedBox(height: psm),

                      // Magical Message
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: psm,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withOpacity(0.2),
                              Colors.blue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.purple.shade300,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Rising from the ashes like a Phoenix!",
                              style: TextStyle(
                                color: Colors.purple.shade300,
                                fontSize: fsm * 0.85,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolutionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(psm),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(bmd),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: psm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
