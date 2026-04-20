import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark, not pitch-black
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg    = Color(0xFF111114);
  static const card  = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const card3 = Color(0xFF3A3A3C);
  static const sep   = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white = Color(0xFFFFFFFF);
  static const lbl1  = Color(0xFFEEEEF0);
  static const lbl2  = Color(0xFFAEAEB2);
  static const lbl3  = Color(0xFF8E8E93);
  static const lbl4  = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = lbl1,
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
  bool _isGeneratingReport = false;

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

  Future<void> _generateReport() async {
    if (widget.event == null) return;
    setState(() => _isGeneratingReport = true);
    try {
      final response = await http.post(
        Uri.parse(generateAttendeeReportUrl),
        headers: basicHeaders,
        body: jsonEncode({'eventId': widget.event!.id}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['error'] == false) {
        showToast(isGood: true, msg: "Report has been generated successfully");
      } else {
        showToast(
          isGood: false,
          msg: "Error: ${body['message'] ?? 'Failed to generate report'}",
        );
      }
    } catch (e) {
      showToast(isGood: false, msg: "Connection Error: $e");
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  Future<void> _deleteReport(String reportId, String? storagePath) async {
    if (widget.event == null) return;
    try {
      // 1. Delete Firestore Document
      await firestore
          .collection(ecol)
          .doc(widget.event!.id)
          .collection('reports')
          .doc(reportId)
          .delete();

      // 2. Delete Storage File (if path available)
      if (storagePath != null && storagePath.isNotEmpty) {
        await FirebaseStorage.instance.ref().child(storagePath).delete();
      }

      showToast(isGood: true, msg: "Report deleted successfully");
    } catch (e) {
      showToast(isGood: false, msg: "Error deleting report: $e");
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
                          const SizedBox(height: 8),
                          _titleBlock(),
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
                            icon: Icons.assessment_rounded,
                            title: "ATTENDEE REPORTS",
                            subtitle: "Generate and download event reports",
                          ),
                          const SizedBox(height: 12),
                          _buildReportsSection(),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, color: _T.lime, size: 13),
                  const SizedBox(width: 5),
                  Text('Back', style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1)),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (isLoading)
            const CupertinoActivityIndicator(color: _T.lime)
          else
            GestureDetector(
              onTap: _saveSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _T.limeDim,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _T.lime.withValues(alpha: 0.35), width: 0.8),
                ),
                child: Text('Save', style: _T.f(size: 13, weight: FontWeight.w700, color: _T.lime)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Settings',
            style: _T.f(size: 28, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.8, height: 1.12),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage language, card format and reports.',
            style: _T.f(size: 13, color: _T.lbl3, height: 1.5),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: _T.lime,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: _T.f(size: 11, weight: FontWeight.w700, color: _T.lbl3, letterSpacing: 1.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
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
            color: _T.sep,
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
                color: _T.sep,
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
            color: isSelected ? _T.lime.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: _T.f(
              size: 13,
              weight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? _T.lime : _T.lbl2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.add_chart_rounded,
          title: "Generate New Report",
          isLoading: _isGeneratingReport,
          onTap: _generateReport,
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream:
              firestore
                  .collection(ecol)
                  .doc(widget.event!.id)
                  .collection('reports')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CupertinoActivityIndicator(color: _T.lime),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return _buildPlaceholderSection("No reports generated yet");
            }

            return Container(
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder:
                    (context, index) => Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: _T.sep,
                    ),
                itemBuilder: (context, index) {
                  final report = docs[index].data() as Map<String, dynamic>;
                  final url = report['url'] ?? '';
                  final createdAt = report['createdAt'] ?? '';
                  DateTime? dt;
                  if (createdAt.isNotEmpty) {
                    dt = DateTime.tryParse(createdAt);
                  }

                  return InkWell(
                    onTap: () async {
                      if (url.isNotEmpty) {
                        final uri = Uri.parse(url);
                        try {
                          debugPrint("Abject: $uri");
                          await launchUrl(uri);
                        } catch (e) {
                          showToast(isGood: false, msg: "Could not launch URL");
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _T.lime.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              color: _T.lime,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Attendee Report",
                                  style: _T.f(
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                if (dt != null)
                                  Text(
                                    timeago.format(dt),
                                    style: _T.f(size: 12, color: _T.lbl2),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed:
                                () => _deleteReport(
                                  docs[index].id,
                                  report['storagePath'],
                                ),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.download_for_offline_rounded,
                            color: _T.lime,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isLoading
                    ? _T.lime.withValues(alpha: 0.3)
                    : _T.sep,
          ),
        ),
        child: Row(
          children: [
            if (isLoading)
              const CupertinoActivityIndicator(color: _T.lime)
            else
              Icon(icon, color: _T.lime, size: 20),
            const SizedBox(width: 12),
            Text(
              isLoading ? "Generating Report..." : title,
              style: _T.f(
                size: 15,
                weight: FontWeight.w600,
                color: isLoading ? _T.lime : _T.white,
              ),
            ),
            const Spacer(),
            if (!isLoading)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _T.lbl4,
                size: 14,
              ),
          ],
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
        border: Border.all(color: _T.sep),
      ),
      child: Center(
        child: Text(
          text,
          style: _T.f(size: 13, color: _T.lbl3, weight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GusOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
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
