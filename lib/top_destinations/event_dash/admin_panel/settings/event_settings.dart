import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/globalfns.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens (Matching AdminPane)
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF0A0A0A);
  static const card = Color(0xFF141414);
  static const lime = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF1E2800);
  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);
  static const grey2 = Color(0xFF555555);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

class EventSettings extends StatefulWidget {
  final Event? event;
  const EventSettings({super.key, required this.event});

  @override
  State<EventSettings> createState() => _EventSettingsState();
}

class _EventSettingsState extends State<EventSettings> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  // Settings state
  String selectedLanguage = 'sw';
  bool usePng = true;
  bool autoReminders = true;
  bool allowGuestCheckIns = false;
  bool emailNotifications = true;
  bool qrCodeScanning = true;
  bool publicEvent = false;
  bool requireApproval = false;
  int reminderHoursBefore = 24;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    if (widget.event != null) {
      setState(() {
        usePng = widget.event?.usepng ?? true;
        selectedLanguage = widget.event?.language ?? 'sw';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (widget.event == null) return;
    setState(() => isLoading = true);
    try {
      await firestore.collection(ecol).doc(widget.event!.id).set({
        'usepng': usePng,
        'language': selectedLanguage,
      }, SetOptions(merge: true));
      showToast(isGood: true, msg: "Mipangilio Imesasishwa");
    } catch (e) {
      showToast(isGood: false, msg: "Hitilafu: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            // Ambient Orbs
            const Positioned(
              top: -100,
              right: -100,
              child: _GusOrb(size: 300, color: _T.lime, opacity: 0.08),
            ),
            const Positioned(
              bottom: -50,
              left: -100,
              child: _GusOrb(size: 250, color: _T.lime, opacity: 0.05),
            ),

            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _sectionHeader(
                            icon: Icons.language_rounded,
                            title: "LANGUAGE",
                            subtitle: "Choose your preferred language",
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageSelector(),
                          const SizedBox(height: 24),

                          _sectionHeader(
                            icon: Icons.picture_as_pdf_rounded,
                            title: "CARD FORMAT",
                            subtitle: "Select file type for sharing",
                          ),
                          const SizedBox(height: 12),
                          _buildCardFormatSelector(),
                          const SizedBox(height: 24),

                          // Future sections placeholder
                          _sectionHeader(
                            icon: Icons.notifications_active_rounded,
                            title: "NOTIFICATIONS",
                            subtitle: "Automatic reminders & alerts",
                          ),
                          const SizedBox(height: 12),
                          _buildPlaceholderSection(
                            "Coming soon in next update",
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _T.lime,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text('Back', style: _T.f(size: 15, weight: FontWeight.w500)),
              ],
            ),
          ),
          const Spacer(),
          if (isLoading)
            const CupertinoActivityIndicator(color: _T.lime)
          else
            GestureDetector(
              onTap: _saveSettings,
              child: Text(
                'Save Settings',
                style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lime),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _T.lime, size: 14),
            const SizedBox(width: 8),
            Text(
              title,
              style: _T.f(
                size: 11,
                weight: FontWeight.w700,
                color: _T.grey2,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: _T.f(size: 13, color: _T.grey1)),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
            language: 'Kiswahili',
            locale: 'sw',
            flag: '🇹🇿',
            isSelected: selectedLanguage == 'sw',
            onTap: () => setState(() => selectedLanguage = 'sw'),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: _T.white.withOpacity(0.05),
          ),
          _buildLanguageOption(
            language: 'English',
            locale: 'en',
            flag: '🇬🇧',
            isSelected: selectedLanguage == 'en',
            onTap: () => setState(() => selectedLanguage = 'en'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String language,
    required String locale,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              language,
              style: _T.f(
                size: 15,
                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _T.lime : _T.white,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _T.lime, size: 20)
            else
              Icon(
                Icons.circle_outlined,
                color: _T.white.withOpacity(0.1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFormatSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFormatOption(
              label: 'PNG Image',
              isSelected: usePng,
              onTap: () => setState(() => usePng = true),
            ),
          ),
          Expanded(
            child: _buildFormatOption(
              label: 'PDF Document',
              isSelected: !usePng,
              onTap: () => setState(() => usePng = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _T.limeDim : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _T.lime.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: _T.f(
              size: 13,
              weight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? _T.lime : _T.grey1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderSection(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(
          text,
          style: _T.f(size: 13, color: _T.grey2, weight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GusOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}
