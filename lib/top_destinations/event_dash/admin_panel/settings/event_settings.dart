import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/components/templates.dart';

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
  String selectedLanguage = 'sw'; // 'sw' for Kiswahili, 'en' for English
  bool usePng = true; // PNG or PDF
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
        // Load other settings from event document if they exist
        // For now, using defaults
      });
    }
  }

  Future<void> _saveSettings() async {
    if (widget.event == null) return;
    setState(() {
      isLoading = true;
    });
    try {
      await firestore.collection(ecol).doc(widget.event!.id).set({
        'usepng': usePng,
        'language': selectedLanguage,
      }, SetOptions(merge: true));
      showToast(isGood: true, msg: "Mipangilio Imesasishwa");
    } catch (e) {
      showToast(isGood: false, msg: "Hitilafu: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Mipangilio ya Hafla",
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).pop(),
        ),
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              Padding(
                padding: EdgeInsets.all(psm),
                child: CupertinoActivityIndicator(),
              )
            else
              IconButton(
                icon: Icon(Icons.save_rounded),
                onPressed: _saveSettings,
              ),
          ],
        ),
      ),
      body: Ccafold(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spaceTiles),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Selection Section
              _buildSectionHeader(
                icon: Icons.language_rounded,
                title: "Lugha",
                subtitle: "Chagua lugha ya matumizi",
              ),
              SizedBox(height: spaceTiles),
              _buildLanguageSelector(),
              SizedBox(height: psm),

              // Card Format Section
              _buildSectionHeader(
                icon: Icons.picture_as_pdf_rounded,
                title: "Muundo wa Kadi",
                subtitle: "Chagua aina ya faili ya kushiriki",
              ),
              SizedBox(height: spaceTiles),
              _buildCardFormatSelector(),
              // SizedBox(height: psm * 2),

              // // Notifications Section
              // _buildSectionHeader(
              //   icon: Icons.notifications_active_rounded,
              //   title: "Arifa",
              //   subtitle: "Mipangilio ya arifa za kiotomatiki",
              // ),
              // SizedBox(height: spaceTiles),
              // _buildNotificationSettings(),
              // SizedBox(height: psm * 2),

              // // Access & Security Section
              // _buildSectionHeader(
              //   icon: Icons.security_rounded,
              //   title: "Usalama na Ufikiaji",
              //   subtitle: "Mipangilio ya usalama na ufikiaji",
              // ),
              // SizedBox(height: spaceTiles),
              // _buildSecuritySettings(),
              // SizedBox(height: psm * 2),

              // // Advanced Settings
              // _buildSectionHeader(
              //   icon: Icons.tune_rounded,
              //   title: "Mipangilio ya Juu",
              //   subtitle: "Mipangilio ya ziada",
              // ),
              // SizedBox(height: spaceTiles),
              // _buildAdvancedSettings(),
              // SizedBox(height: psm * 3),

              // Save Button
              // lqAssButton(
              //   label: "Hifadhi Mipangilio",
              //   onPressed: isLoading ? null : _saveSettings,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(psm),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(psm * 0.75),
            decoration: BoxDecoration(
              gradient: primaryGrad,
              borderRadius: BorderRadius.circular(bsm),
            ),
            child: Icon(icon, color: primaryWhite, size: 24),
          ),
          SizedBox(width: psm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fsm + 2,
                    fontWeight: FontWeight.bold,
                    color: primaryWhite,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: fsm - 2, color: mWhite),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: secscagrad,
        borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
            language: 'Kiswahili',
            locale: 'sw',
            flag: '🇹🇿',
            isSelected: selectedLanguage == 'sw',
            onTap: () {
              setState(() {
                selectedLanguage = 'sw';
              });
              _changeLanguage('sw');
            },
          ),
          Divider(height: 1, thickness: 0.5, color: lqassbdrColor),
          _buildLanguageOption(
            language: 'English',
            locale: 'en',
            flag: '🇬🇧',
            isSelected: selectedLanguage == 'en',
            onTap: () {
              setState(() {
                selectedLanguage = 'en';
              });
              _changeLanguage('en');
            },
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
      borderRadius: BorderRadius.circular(bsm),
      child: Container(
        padding: EdgeInsets.all(psm * 1.5),
        decoration: BoxDecoration(
          gradient: isSelected ? primaryGrad : null,
          borderRadius: BorderRadius.circular(bsm),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(bsm),
                border: Border.all(
                  color: isSelected ? primaryWhite : lqassbdrColor,
                  width: 1.5,
                ),
              ),
              child: Center(child: Text(flag, style: TextStyle(fontSize: 28))),
            ),
            SizedBox(width: psm * 1.5),
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: fsm + 1,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryWhite : mWhite,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(psm * 0.5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String locale) {
    // Simulate language change - in real app, you'd update the app locale
    showToast(
      isGood: true,
      msg:
          locale == 'sw'
              ? "Lugha imebadilishwa kuwa Kiswahili"
              : "Language changed to English",
    );
  }

  Widget _buildCardFormatSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: secscagrad,
        borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFormatOption(
              icon: Icons.image_rounded,
              label: 'PNG',
              isSelected: usePng,
              onTap: () => setState(() => usePng = true),
            ),
          ),
          Container(width: 1, height: 60, color: lqassbdrColor),
          Expanded(
            child: _buildFormatOption(
              icon: Icons.picture_as_pdf_rounded,
              label: 'PDF',
              isSelected: !usePng,
              onTap: () => setState(() => usePng = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: psm * 1.5),
        decoration: BoxDecoration(
          gradient: isSelected ? primaryGrad : null,
          borderRadius: BorderRadius.circular(bsm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primaryWhite : mWhite, size: 32),
            SizedBox(height: psm * 0.5),
            Text(
              label,
              style: TextStyle(
                fontSize: fsm,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryWhite : mWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: secscagrad,
        borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_active_rounded,
            title: "Arifa za Kiotomatiki",
            subtitle: "Tuma arifa za kukumbusha kiotomatiki",
            value: autoReminders,
            onChanged: (val) => setState(() => autoReminders = val),
          ),
          Divider(height: 1, thickness: 0.5, color: lqassbdrColor),
          _buildSwitchTile(
            icon: Icons.email_rounded,
            title: "Arifa za Barua Pepe",
            subtitle: "Tuma arifa kupitia barua pepe",
            value: emailNotifications,
            onChanged: (val) => setState(() => emailNotifications = val),
          ),
          if (autoReminders) ...[
            Divider(height: 1, thickness: 0.5, color: lqassbdrColor),
            _buildReminderHoursSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderHoursSelector() {
    return Padding(
      padding: EdgeInsets.all(psm * 1.5),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: mWhite, size: 20),
          SizedBox(width: psm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tuma Kumbusho Masaa",
                  style: TextStyle(
                    fontSize: fsm,
                    fontWeight: FontWeight.w600,
                    color: primaryWhite,
                  ),
                ),
                SizedBox(height: psm * 0.5),
                Row(
                  children: [
                    Expanded(child: _buildHourChip(12, "Masaa 12")),
                    SizedBox(width: spaceTiles),
                    Expanded(child: _buildHourChip(24, "Masaa 24")),
                    SizedBox(width: spaceTiles),
                    Expanded(child: _buildHourChip(48, "Masaa 48")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourChip(int hours, String label) {
    bool isSelected = reminderHoursBefore == hours;
    return InkWell(
      onTap: () => setState(() => reminderHoursBefore = hours),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: psm * 0.75, horizontal: psm),
        decoration: BoxDecoration(
          gradient: isSelected ? primaryGrad : null,
          borderRadius: BorderRadius.circular(bxsm),
          border: Border.all(
            color: isSelected ? primaryWhite : lqassbdrColor,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fsm - 1,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? primaryWhite : mWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: secscagrad,
        borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.qr_code_scanner_rounded,
            title: "Skani za QR Code",
            subtitle: "Ruhusu skani za kadi za QR",
            value: qrCodeScanning,
            onChanged: (val) => setState(() => qrCodeScanning = val),
          ),
          Divider(height: 1, thickness: 0.5, color: lqassbdrColor),
          _buildSwitchTile(
            icon: Icons.person_add_rounded,
            title: "Ruhusu Wageni",
            subtitle: "Ruhusu wageni kuwasili bila kadi",
            value: allowGuestCheckIns,
            onChanged: (val) => setState(() => allowGuestCheckIns = val),
          ),
          Divider(height: 1, thickness: 0.5, color: lqassbdrColor),
          _buildSwitchTile(
            icon: Icons.public_rounded,
            title: "Tukio la Umma",
            subtitle: "Fanya tukio liwe la umma",
            value: publicEvent,
            onChanged: (val) => setState(() => publicEvent = val),
          ),
          Divider(height: 1, thickness: 0.5, color: lqassbdrColor),
          _buildSwitchTile(
            icon: Icons.verified_user_rounded,
            title: "Inahitaji Idhini",
            subtitle: "Wageni wanahitaji idhini ya kujiunga",
            value: requireApproval,
            onChanged: (val) => setState(() => requireApproval = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: secscagrad,
        borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.info_outline_rounded,
            title: "Maelezo",
            subtitle: "Mipangilio hii itatumika kwa tukio hili peke yake",
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: psm * 1.5,
        vertical: psm * 0.5,
      ),
      leading: Container(
        padding: EdgeInsets.all(psm * 0.75),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(bsm),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fsm,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: fsm - 2, color: mWhite),
      ),
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: primaryColor,
          activeTrackColor: primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.all(psm * 1.5),
      leading: Container(
        padding: EdgeInsets.all(psm * 0.75),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(bsm),
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fsm,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: fsm - 2, color: mWhite),
      ),
    );
  }
}
