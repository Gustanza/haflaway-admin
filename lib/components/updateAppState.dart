import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/models/appState.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:url_launcher/url_launcher.dart';

class UpdateAppstate extends StatefulWidget {
  final HAppState hAppState;
  const UpdateAppstate({super.key, required this.hAppState});

  @override
  State<UpdateAppstate> createState() => _UpdateAppstateState();
}

class _UpdateAppstateState extends State<UpdateAppstate> {
  bool _isDownloading = false;

  Future<void> _launchDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final Uri url = Uri.parse(widget.hAppState.downloadUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Error launching download: $e');
    } finally {
      setState(() {
        _isDownloading = false;
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
                      // App Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: primaryGrad,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: psm),

                      // Update Message Card
                      buildGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(psm * 2),
                          child: Column(
                            children: [
                              Text(
                                "Update Required",
                                style: TextStyle(
                                  fontSize: fsm * 1.6,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: psm),

                              Text(
                                "Version ${widget.hAppState.versionName}",
                                style: TextStyle(
                                  fontSize: fsm * 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),

                              const SizedBox(height: psm),

                              Text(
                                "Please update to the latest version to continue using the app.",
                                style: TextStyle(
                                  fontSize: fsm,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: psm * 2),

                      // Download Button
                      buildPrimaryButton(
                        isLoading: _isDownloading,
                        label: "Download Update",
                        onTap: _isDownloading ? null : _launchDownload,
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
