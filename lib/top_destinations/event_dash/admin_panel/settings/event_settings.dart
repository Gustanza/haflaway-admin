import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
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
  bool _isPublished = false;
  List<EventLocation> _locations = [];
  String? _scanPromo;

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
        _isPublished = (widget.event?.status ?? 'draft').toLowerCase() == 'published';
        _locations = List<EventLocation>.from(widget.event?.locations ?? []);
        _scanPromo = widget.event?.scanPromo;
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
      showToast(isGood: false, msg: "Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addLocation(EventLocation loc) async {
    final updated = [..._locations, loc];
    setState(() => _locations = updated);
    try {
      await firestore.collection(ecol).doc(widget.event!.id).update({
        'locations': updated.map((l) => l.toMap()).toList(),
      });
      showToast(isGood: true, msg: 'Location Added');
    } catch (e) {
      setState(() => _locations = _locations.where((l) => l.id != loc.id).toList());
      showToast(isGood: false, msg: 'Error: $e');
    }
  }

  Future<void> _removeLocation(EventLocation loc) async {
    final updated = _locations.where((l) => l.id != loc.id).toList();
    setState(() => _locations = updated);
    try {
      await firestore.collection(ecol).doc(widget.event!.id).update({
        'locations': updated.map((l) => l.toMap()).toList(),
      });
      showToast(isGood: true, msg: 'Location Removed');
    } catch (e) {
      setState(() => _locations = [..._locations, loc]);
      showToast(isGood: false, msg: 'Error: $e');
    }
  }

  void _showAddLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLocationSheet(onAdd: _addLocation),
    );
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

  Future<void> _saveScanPromo(String msg) async {
    if (widget.event == null) return;
    final trimmed = msg.trim();
    setState(() => _scanPromo = trimmed.isEmpty ? null : trimmed);
    try {
      if (trimmed.isEmpty) {
        await firestore.collection(ecol).doc(widget.event!.id).update({
          eScanPromo: FieldValue.delete(),
        });
      } else {
        await firestore.collection(ecol).doc(widget.event!.id).update({
          eScanPromo: trimmed,
        });
      }
      showToast(isGood: true, msg: trimmed.isEmpty ? 'Promo message removed' : 'Promo message saved');
    } catch (e) {
      showToast(isGood: false, msg: 'Error: $e');
    }
  }

  void _showScanPromoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScanPromoSheet(
        initial: _scanPromo,
        onSave: _saveScanPromo,
      ),
    );
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
                            icon: Icons.location_on_rounded,
                            title: "EVENT LOCATIONS",
                            subtitle: "Add map locations for this event",
                          ),
                          const SizedBox(height: 12),
                          _buildLocationsSection(),
                          const SizedBox(height: 24),

                          _sectionHeader(
                            icon: Icons.assessment_rounded,
                            title: "ATTENDEE REPORTS",
                            subtitle: "Generate and download event reports",
                          ),
                          const SizedBox(height: 12),
                          _buildReportsSection(),
                          const SizedBox(height: 24),

                          _sectionHeader(
                            icon: Icons.campaign_rounded,
                            title: "SCAN PROMO",
                            subtitle: "Post check-in promotional message",
                          ),
                          const SizedBox(height: 12),
                          _buildScanPromoSection(),
                          const SizedBox(height: 24),

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
                          const SizedBox(height: 32),

                          _sectionHeader(
                            icon: Icons.public_rounded,
                            title: "VISIBILITY",
                            subtitle: "Control who can see this event",
                          ),
                          const SizedBox(height: 12),
                          _buildActionTile(
                            icon: _isPublished ? Icons.public_off_rounded : Icons.public_rounded,
                            title: _isPublished ? "Published  ·  Tap to Unpublish" : "Draft  ·  Tap to Publish",
                            isLoading: false,
                            onTap: _showPublishDialog,
                          ),
                          const SizedBox(height: 32),

                          _sectionHeader(
                            icon: Icons.warning_amber_rounded,
                            title: "DANGER ZONE",
                            subtitle: "Irreversible actions",
                          ),
                          const SizedBox(height: 12),
                          _buildDangerTile(),
                          const SizedBox(height: 40),
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

  Widget _buildLocationsSection() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.add_location_alt_rounded,
          title: 'Add Map Location',
          isLoading: false,
          onTap: _showAddLocationSheet,
        ),
        const SizedBox(height: 12),
        if (_locations.isEmpty)
          _buildPlaceholderSection("No locations added yet")
        else
          Container(
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.sep),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _locations.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: _T.sep,
              ),
              itemBuilder: (_, i) => _buildLocationTile(_locations[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationTile(EventLocation loc) {
    const double iconColWidth = 38.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── label row ──
          Row(
            children: [
              Container(
                width: iconColWidth,
                height: iconColWidth,
                decoration: BoxDecoration(
                  color: _T.lime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded, color: _T.lime, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.label,
                  style: _T.f(size: 14, weight: FontWeight.w600),
                ),
              ),
              if (loc.mapsUrl != null)
                IconButton(
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse(loc.mapsUrl!), mode: LaunchMode.externalApplication);
                    } catch (_) {
                      showToast(isGood: false, msg: 'Cannot open maps');
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, color: _T.lbl3, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeLocation(loc),
                icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.7), size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          // ── thin divider ──
          Padding(
            padding: const EdgeInsets.only(left: iconColWidth + 12, top: 8, bottom: 8),
            child: Container(height: 0.6, color: _T.sep),
          ),
          // ── place name ──
          Padding(
            padding: const EdgeInsets.only(left: iconColWidth + 12),
            child: Text(loc.placeName, style: _T.f(size: 12, color: _T.lbl3)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPromoSection() {
    final hasMsg = _scanPromo != null && _scanPromo!.isNotEmpty;
    return Column(
      children: [
        _buildActionTile(
          icon: hasMsg ? Icons.edit_rounded : Icons.add_comment_rounded,
          title: hasMsg ? 'Edit Promo Message' : 'Set Promo Message',
          isLoading: false,
          onTap: _showScanPromoSheet,
        ),
        const SizedBox(height: 12),
        if (!hasMsg)
          _buildPlaceholderSection("No promo message set")
        else
          GestureDetector(
            onTap: _showScanPromoSheet,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _T.sep),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _T.lime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: _T.lime, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _scanPromo!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _T.f(size: 13, color: _T.lbl2, height: 1.55),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _saveScanPromo(''),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.7), size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
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

  // ── Publish Dialog ────────────────────────────────────────────────────────

  void _showPublishDialog() {
    if (widget.event == null) return;
    final isPublished = _isPublished;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: _T.card.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _T.sep.withValues(alpha: 0.6), width: 0.8),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _T.lime.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.public_rounded, color: _T.lime, size: 26),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPublished ? 'Unpublish Event?' : 'Publish Event?',
                      style: _T.f(size: 18, weight: FontWeight.w700, color: _T.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPublished
                          ? 'This will hide the event from end-users.'
                          : 'This will make the event visible to all users.',
                      textAlign: TextAlign.center,
                      style: _T.f(size: 13, color: _T.lbl2, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: _T.card2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _T.sep, width: 0.8),
                              ),
                              child: Center(
                                child: Text('Cancel', style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lbl2)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              final newStatus = isPublished ? 'Draft' : 'Published';
                              try {
                                await firestore.collection(ecol).doc(widget.event!.id).update({'status': newStatus});
                                if (mounted) setState(() => _isPublished = !isPublished);
                                showToast(isGood: true, msg: isPublished ? 'Event set as Draft' : 'Event Published');
                              } catch (e) {
                                showToast(isGood: false, msg: 'Error: $e');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: isPublished
                                    ? const Color(0xFFFF453A).withValues(alpha: 0.15)
                                    : _T.limeDim,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isPublished
                                      ? const Color(0xFFFF453A).withValues(alpha: 0.4)
                                      : _T.lime.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  isPublished ? 'Unpublish' : 'Publish',
                                  style: _T.f(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: isPublished ? const Color(0xFFFF453A) : _T.lime,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete Tile + Dialog ──────────────────────────────────────────────────

  Widget _buildDangerTile() {
    return GestureDetector(
      onTap: _showDeleteDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF453A).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF453A).withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.delete, color: Color(0xFFFF453A), size: 20),
            const SizedBox(width: 12),
            Text('Delete Event', style: _T.f(size: 15, weight: FontWeight.w600, color: Color(0xFFFF453A))),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: const Color(0xFFFF453A).withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    if (widget.event == null) return;
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: StatefulBuilder(
                builder: (ctx2, setDs) => Container(
                  decoration: BoxDecoration(
                    color: _T.card.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _T.sep.withValues(alpha: 0.6), width: 0.8),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF453A).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.delete, color: Color(0xFFFF453A), size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Delete Event',
                        style: _T.f(size: 18, weight: FontWeight.w700, color: _T.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is irreversible. Type "delete" below to confirm.',
                        textAlign: TextAlign.center,
                        style: _T.f(size: 13, color: _T.lbl2, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: _T.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _T.sep, width: 0.8),
                        ),
                        child: TextField(
                          controller: confirmCtrl,
                          style: _T.f(size: 14, color: _T.white),
                          onChanged: (_) => setDs(() {}),
                          decoration: InputDecoration(
                            hintText: 'delete',
                            hintStyle: _T.f(size: 14, color: _T.lbl4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx2).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: _T.card2,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _T.sep, width: 0.8),
                                ),
                                child: Center(
                                  child: Text('Cancel', style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lbl2)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: confirmCtrl.text.trim() == 'delete'
                                  ? () async {
                                      Navigator.of(ctx2).pop();
                                      try {
                                        await firestore.collection(ecol).doc(widget.event!.id).delete();
                                        if (mounted) Phoenix.rebirth(context);
                                      } catch (e) {
                                        showToast(isGood: false, msg: 'Error: $e');
                                      }
                                    }
                                  : null,
                              child: AnimatedOpacity(
                                opacity: confirmCtrl.text.trim() == 'delete' ? 1.0 : 0.35,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF453A).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFF453A).withValues(alpha: 0.4), width: 0.8),
                                  ),
                                  child: Center(
                                    child: Text('Delete', style: _T.f(size: 14, weight: FontWeight.w700, color: Color(0xFFFF453A))),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Add Location Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddLocationSheet extends StatefulWidget {
  final Function(EventLocation) onAdd;
  const _AddLocationSheet({required this.onAdd});

  @override
  State<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<_AddLocationSheet> {
  final _labelCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();
  int _tabIndex = 0;

  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _isFetchingDetails = false;
  Timer? _debounce;

  double? _selectedLat;
  double? _selectedLng;
  String? _selectedPlaceName;

  Timer? _resolveDebounce;
  bool _isResolvingUrl = false;
  double? _resolvedLat;
  double? _resolvedLng;
  String? _resolvedPlaceName;

  bool _isValidCoords(String input) {
    if (input.isEmpty || input.startsWith('http')) return false;
    final parts = input.split(RegExp(r'\s*,\s*'));
    if (parts.length != 2) return false;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    return lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180;
  }

  bool get _canAdd {
    if (_labelCtrl.text.trim().isEmpty) return false;
    if (_tabIndex == 0) return _selectedPlaceName != null;
    return _isValidCoords(_rawCtrl.text.trim()) && !_isResolvingUrl;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _resolveDebounce?.cancel();
    _labelCtrl.dispose();
    _searchCtrl.dispose();
    _rawCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    setState(() {
      _selectedPlaceName = null;
      _selectedLat = null;
      _selectedLng = null;
    });
    if (q.trim().isEmpty) {
      setState(() { _suggestions = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _fetchSuggestions(q.trim()),
    );
  }

  void _onRawChanged(String val) {
    setState(() {
      _resolvedPlaceName = null;
      _resolvedLat = null;
      _resolvedLng = null;
      _isResolvingUrl = false;
    });
    _resolveDebounce?.cancel();
    if (!_isValidCoords(val.trim())) return;
    setState(() => _isResolvingUrl = true);
    _resolveDebounce = Timer(
      const Duration(milliseconds: 600),
      () => _resolveRawInput(val.trim()),
    );
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    if (googleMapsApiKey.startsWith('YOUR_')) return null;
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=$googleMapsApiKey',
      );
      final resp = await http.get(uri);
      if (!mounted) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];
      if (results.isNotEmpty) {
        return results.first['formatted_address'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _resolveRawInput(String input) async {
    final parts = input.trim().split(RegExp(r'\s*,\s*'));
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) {
      if (mounted) setState(() => _isResolvingUrl = false);
      return;
    }
    final name = await _reverseGeocode(lat, lng);
    if (!mounted) return;
    setState(() {
      _resolvedLat = lat;
      _resolvedLng = lng;
      _resolvedPlaceName = name ?? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      _isResolvingUrl = false;
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (googleMapsApiKey.startsWith('YOUR_')) {
      if (mounted) setState(() => _isSearching = false);
      return;
    }
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}&key=$googleMapsApiKey&language=sw',
      );
      final resp = await http.get(uri);
      if (!mounted) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final preds = (data['predictions'] as List?) ?? [];
      setState(() {
        _suggestions = preds.take(5).map<Map<String, dynamic>>((p) {
          final sf = p['structured_formatting'] as Map<String, dynamic>? ?? {};
          return {
            'placeId': p['place_id'] ?? '',
            'name': sf['main_text'] ?? p['description'] ?? '',
            'secondary': sf['secondary_text'] ?? '',
          };
        }).toList();
        _isSearching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> s) async {
    setState(() {
      _searchCtrl.text = s['name'] as String;
      _suggestions = [];
      _isFetchingDetails = true;
    });
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${s['placeId']}&fields=geometry,name&key=$googleMapsApiKey',
      );
      final resp = await http.get(uri);
      if (!mounted) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final loc = (result?['geometry'] as Map<String, dynamic>?)?['location'];
      setState(() {
        _selectedLat = (loc?['lat'] as num?)?.toDouble();
        _selectedLng = (loc?['lng'] as num?)?.toDouble();
        _selectedPlaceName = (result?['name'] as String?) ?? s['name'] as String;
        _isFetchingDetails = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedPlaceName = s['name'] as String;
          _isFetchingDetails = false;
        });
      }
    }
  }

  void _submit() {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;
    EventLocation? loc;
    if (_tabIndex == 0 && _selectedPlaceName != null) {
      loc = EventLocation(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        placeName: _selectedPlaceName!,
        lat: _selectedLat,
        lng: _selectedLng,
        mapsUrl: _selectedLat != null
            ? 'https://www.google.com/maps?q=$_selectedLat,$_selectedLng'
            : null,
      );
    } else if (_tabIndex == 1 && _resolvedPlaceName != null) {
      loc = EventLocation(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        placeName: _resolvedPlaceName!,
        lat: _resolvedLat,
        lng: _resolvedLng,
        mapsUrl: 'https://www.google.com/maps?q=$_resolvedLat,$_resolvedLng',
      );
    }
    if (loc != null) {
      widget.onAdd(loc);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _T.lbl4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Location', style: _T.f(size: 18, weight: FontWeight.w700, color: _T.white)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: _T.card2, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: _T.lbl2, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('LOCATION LABEL', style: _T.f(size: 11, color: _T.lbl3, weight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            _sheetField(_labelCtrl, 'e.g. Directions to the Venue', onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
            _tabBar(),
            const SizedBox(height: 12),
            if (_tabIndex == 0) _searchTab() else _rawTab(),
            const SizedBox(height: 20),
            _addButton(),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint, {
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _T.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        maxLines: maxLines,
        style: _T.f(size: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _T.f(size: 14, color: _T.lbl4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _T.card2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _tabOption(0, Icons.search_rounded, 'Search'),
          _tabOption(1, Icons.pin_drop_rounded, 'Coordinates'),
        ],
      ),
    );
  }

  Widget _tabOption(int idx, IconData icon, String label) {
    final selected = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _tabIndex = idx; _suggestions = []; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _T.limeDim : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _T.lime.withValues(alpha: 0.35) : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? _T.lime : _T.lbl3),
              const SizedBox(width: 5),
              Text(
                label,
                style: _T.f(
                  size: 12,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _T.lime : _T.lbl3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _T.card2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.sep, width: 0.8),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: _T.f(size: 14),
            decoration: InputDecoration(
              hintText: 'Search for a place...',
              hintStyle: _T.f(size: 14, color: _T.lbl4),
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(color: _T.lbl3, radius: 8),
                      ),
                    )
                  : const Icon(Icons.search_rounded, color: _T.lbl3, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _T.card2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Container(height: 1, color: _T.sep),
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                BorderRadius br;
                if (_suggestions.length == 1) {
                  br = BorderRadius.circular(12);
                } else if (i == 0) {
                  br = const BorderRadius.vertical(top: Radius.circular(12));
                } else if (i == _suggestions.length - 1) {
                  br = const BorderRadius.vertical(bottom: Radius.circular(12));
                } else {
                  br = BorderRadius.zero;
                }
                return InkWell(
                  onTap: () => _selectSuggestion(s),
                  borderRadius: br,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: _T.lbl3, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name'] as String, style: _T.f(size: 13, weight: FontWeight.w500)),
                              if ((s['secondary'] as String).isNotEmpty)
                                Text(s['secondary'] as String, style: _T.f(size: 11, color: _T.lbl3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (_isFetchingDetails)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CupertinoActivityIndicator(color: _T.lime)),
          ),
        if (_selectedPlaceName != null && !_isFetchingDetails) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.lime.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: _T.lime, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlaceName!,
                        style: _T.f(size: 13, weight: FontWeight.w600, color: _T.lime),
                      ),
                      if (_selectedLat != null)
                        Text(
                          '${_selectedLat!.toStringAsFixed(5)}, ${_selectedLng!.toStringAsFixed(5)}',
                          style: _T.f(size: 11, color: _T.lime.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedPlaceName = null;
                    _selectedLat = null;
                    _selectedLng = null;
                    _searchCtrl.clear();
                  }),
                  child: const Icon(Icons.close, color: _T.lime, size: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _rawTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetField(
          _rawCtrl,
          'e.g. -6.8161, 39.2804',
          onChanged: _onRawChanged,
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final raw = _rawCtrl.text.trim();
          if (raw.isEmpty) {
            return Text(
              'Enter latitude and longitude separated by a comma.',
              style: _T.f(size: 12, color: _T.lbl3),
            );
          }
          if (raw.startsWith('http')) {
            return Text(
              'Links are not accepted here. Use the Search tab instead.',
              style: _T.f(size: 12, color: Colors.redAccent),
            );
          }
          if (!_isValidCoords(raw) && _resolvedPlaceName == null && !_isResolvingUrl) {
            return Text(
              'Invalid format. Expected: latitude, longitude (e.g. -6.8161, 39.2804)',
              style: _T.f(size: 12, color: Colors.redAccent),
            );
          }
          return const SizedBox.shrink();
        }),
        if (_isResolvingUrl) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              CupertinoActivityIndicator(color: _T.lime, radius: 8),
              SizedBox(width: 8),
              Text('Resolving location...', style: TextStyle(color: _T.lbl3, fontSize: 12)),
            ],
          ),
        ],
        if (_resolvedPlaceName != null && !_isResolvingUrl) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.lime.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: _T.lime, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resolvedPlaceName!,
                        style: _T.f(size: 13, weight: FontWeight.w600, color: _T.lime),
                      ),
                      if (_resolvedLat != null)
                        Text(
                          '${_resolvedLat!.toStringAsFixed(5)}, ${_resolvedLng!.toStringAsFixed(5)}',
                          style: _T.f(size: 11, color: _T.lime.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _resolvedPlaceName = null;
                    _resolvedLat = null;
                    _resolvedLng = null;
                    _rawCtrl.clear();
                  }),
                  child: const Icon(Icons.close, color: _T.lime, size: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _addButton() {
    final canAdd = _canAdd;
    return GestureDetector(
      onTap: canAdd ? _submit : null,
      child: AnimatedOpacity(
        opacity: canAdd ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _T.limeDim,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: canAdd ? _T.lime.withValues(alpha: 0.5) : _T.sep,
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              'Add Location',
              style: _T.f(size: 15, weight: FontWeight.w700, color: _T.lime),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan Promo Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ScanPromoSheet extends StatefulWidget {
  final String? initial;
  final Future<void> Function(String) onSave;
  const _ScanPromoSheet({required this.initial, required this.onSave});

  @override
  State<_ScanPromoSheet> createState() => _ScanPromoSheetState();
}

class _ScanPromoSheetState extends State<_ScanPromoSheet> {
  late final TextEditingController _ctrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await widget.onSave(_ctrl.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top:   BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
              left:  BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scan Promo Message', style: _T.f(size: 18, weight: FontWeight.w700, color: _T.white)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: const Icon(Icons.close, color: _T.lbl2, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'This message will be sent to attendees after a successful check-in scan.',
                style: _T.f(size: 12, color: _T.lbl3, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 6,
                  minLines: 4,
                  style: _T.f(size: 14, height: 1.55),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Write your promotional message here...',
                    hintStyle: _T.f(size: 14, color: _T.lbl4),
                    contentPadding: const EdgeInsets.all(14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _ctrl.text.trim().isNotEmpty && !_isSaving ? _submit : null,
                child: AnimatedOpacity(
                  opacity: _ctrl.text.trim().isNotEmpty && !_isSaving ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _T.limeDim,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _T.lime.withValues(alpha: 0.5), width: 0.8),
                    ),
                    child: Center(
                      child: _isSaving
                          ? const CupertinoActivityIndicator(color: _T.lime)
                          : Text('Save Message', style: _T.f(size: 15, weight: FontWeight.w700, color: _T.lime)),
                    ),
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
