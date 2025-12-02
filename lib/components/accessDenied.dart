import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class AccessDenied extends StatefulWidget {
  const AccessDenied({super.key});

  @override
  State<AccessDenied> createState() => _AccessDeniedState();
}

class _AccessDeniedState extends State<AccessDenied> {
  bool _isEmailLoading = false;

  Future<void> _launchEmail() async {
    setState(() {
      _isEmailLoading = true;
    });

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'haflaway@gmail.com',
        query:
            'subject=Access Request&body=Hello, I would like to request access to the Haflaway app. Please provide me with the necessary permissions.',
      );

      await launchUrl(emailUri);
    } catch (e) {
      _showErrorSnackBar('Error opening email: $e');
    } finally {
      setState(() {
        _isEmailLoading = false;
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
      appBar: appBar(title: "Security Clearance"),
      body: Container(
        decoration: const BoxDecoration(gradient: scagrad),
        child: SafeArea(
          child: Column(
            children: [
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: p20, right: p20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Access Denied Message Card
                      buildGlassCard(
                        child: Container(
                          padding: const EdgeInsets.all(psm * 2),
                          decoration: BoxDecoration(
                            gradient: secscagrad,
                            borderRadius: BorderRadius.circular(bmd),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Access Restricted",
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
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  "Account Frozen",
                                  style: TextStyle(
                                    fontSize: fsm * 0.9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade300,
                                  ),
                                ),
                              ),

                              const SizedBox(height: psm * 1.5),

                              Text(
                                "Your account access has been restricted. Please contact our support team to resolve this issue.",
                                style: TextStyle(
                                  fontSize: fsm,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: psm * 2),

                              // Contact Info Card
                              Container(
                                padding: const EdgeInsets.all(psm),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withOpacity(0.2),
                                      primaryColor.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(bmd),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: primaryGrad,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.email_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: psm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Contact Support",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "haflaway@gmail.com",
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: psm * 2),

                      // Email Button
                      buildPrimaryButton(
                        iconData: Icons.phone,
                        isLoading: _isEmailLoading,
                        label: "Contact Support",
                        onTap: _isEmailLoading ? null : _launchEmail,
                      ),
                      const SizedBox(height: psm),

                      // Additional Info
                      Text(
                        "We'll get back to you within 24 hours",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: fsm * 0.9,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
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
}
