import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/michango/michango_editor.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

// ── Warm palette ────────────────────────────────────────────
const _warmBg = Color(0xFF3A2D20);

// ═══════════════════════════════════════════════════════════
//  Simplified Apple-style attendee tile
// ═══════════════════════════════════════════════════════════

Widget buildAttendeeCard({
  required Attendee attendee,
  required KardType kardType,
  required Function() onEdit,
  required bool hasKey,
  required String campaignId,
  required String eventId,
  required List<AttendeeLabel> allLabels, // Added
  required Function() onSelected,
  required Function(String) onStatusChange,
}) {
  var fullname = attendee.fullName;

  // Derive initials for avatar
  final initials =
      fullname
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();

  // Warm avatar colors based on name hash
  final hue = (fullname.hashCode % 360).abs().toDouble();
  final avatarColor = HSLColor.fromAHSL(1, hue, 0.45, 0.55).toColor();

  int messageCount = (attendee.messageIndexes)?.length ?? 0;

  return StatefulBuilder(
    builder: (context, setState) {
      return GestureDetector(
        onLongPress: onSelected,
        onTap:
            () => _showDetailPopup(
              context: context,
              attendee: attendee,
              kardType: kardType,
              campaignId: campaignId,
              eventId: eventId,
              onEdit: onEdit,
              onStatusChange: onStatusChange,
            ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color:
                      hasKey
                          ? const Color(0xFF1E2800)
                          : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        hasKey
                            ? const Color(0xFFC9A84C).withValues(alpha: 0.45)
                            : const Color(0xFF1F1F1F), // Very subtle border
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // ── Avatar ──
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: avatarColor.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: avatarColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        if (messageCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              padding: EdgeInsets.all(messageCount > 9 ? 3 : 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: _warmBg, width: 2),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                messageCount > 99 ? "99+" : "$messageCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // ── Name + Phone ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fullname,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            attendee.phone,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (attendee.labelIds != null &&
                              attendee.labelIds!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  attendee.labelIds!.map((labelId) {
                                    final label = allLabels.firstWhere(
                                      (l) => l.id == labelId,
                                      orElse:
                                          () => AttendeeLabel(
                                            id: '',
                                            name: '?',
                                            colorValue: 0xFF555555,
                                          ),
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          label.colorValue,
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(40),
                                        border: Border.all(
                                          color: Color(
                                            label.colorValue,
                                          ).withOpacity(0.5),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        label.name,
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Color(label.colorValue),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // ── Attendance dot indicator ──
                    if (kardType == KardType.invitation)
                      _buildStatusDot(attendee.attendanceStatus),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ── Tiny colored dot showing attendance status ──
Widget _buildStatusDot(String? status) {
  Color dotColor;
  switch (status) {
    case atconfstate:
      dotColor = Colors.green;
      break;
    case atdeclstate:
      dotColor = Colors.red;
      break;
    case atcallstate:
      dotColor = Colors.teal;
      break;
    case atunreachablestate:
      dotColor = Colors.orange;
      break;
    default:
      dotColor = Colors.grey;
  }
  return Container(
    width: 10,
    height: 10,
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      color: dotColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: dotColor.withValues(alpha: 0.5),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Detail popup — shows everything on tap
// ═══════════════════════════════════════════════════════════

void _showDetailPopup({
  required BuildContext context,
  required Attendee attendee,
  required KardType kardType,
  required String campaignId,
  required String eventId,
  required Function() onEdit,
  required Function(String) onStatusChange,
}) {
  var attrCrdMap = attendee.cards[kardType.name];
  AttributeCard? attributeCard;
  attributeCard =
      attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
  String crdnm =
      attributeCard != null ? attributeCard.name ?? "Not Set" : "Not Set";

  final fullname = attendee.fullName;
  final hue = (fullname.hashCode % 360).abs().toDouble();
  final avatarColor = HSLColor.fromAHSL(1, hue, 0.45, 0.55).toColor();
  final initials =
      fullname
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, popupSetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Handle bar ──
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // ── Avatar + Name header ──
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarColor.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: avatarColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fullname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendee.phone,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // ── Card type badge ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _warmBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          crdnm,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Quick action buttons ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPopupAction(
                              icon: Icons.call,
                              label: "Call",
                              color: Colors.green,
                              onTap: () => callNumber(attendee.phone),
                            ),
                            if (kardType == KardType.invitation ||
                                kardType == KardType.contribution)
                              _buildPopupAction(
                                icon: Clarity.eye_show_line,
                                label: "Card",
                                color: Colors.blueAccent,
                                onTap: () {
                                  var vcrd = attendee.cards[kardType.name];
                                  if (vcrd != null) {
                                    AttributeCard attrCrd =
                                        AttributeCard.fromMap(map: vcrd);
                                    try {
                                      launchUrl(Uri.parse(attrCrd.url ?? ""));
                                    } catch (e) {
                                      showToast(isGood: false, msg: "$e");
                                    }
                                  } else {
                                    showToast(
                                      isGood: false,
                                      msg: "Unable to View",
                                    );
                                  }
                                },
                              ),
                            _buildPopupAction(
                              icon: Icons.edit,
                              label: "Edit",
                              color: Colors.orangeAccent,
                              onTap: () {
                                Navigator.of(ctx).pop();
                                onEdit();
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Delivery status section ──
                      _buildPopupSection(
                        title: "Message Status",
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildDeliveryStatusIndicators(
                            attendee,
                            kardType,
                            campaignId,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Attendance controls — for invitations ──
                      if (kardType == KardType.invitation)
                        _buildPopupSection(
                          title: "Attendance Status",
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildAttendanceControls(attendee, eventId, (
                              status,
                            ) {
                              onStatusChange(status);
                              popupSetState(() {});
                            }),
                          ),
                        ),

                      // ── Michango display — for contributions ──
                      if (kardType == KardType.contribution ||
                          kardType == KardType.contact)
                        _buildPopupSection(
                          title: "Contribution Details",
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: buildMichangoDisplay(
                              context,
                              attendee,
                              eventId,
                              onStatusChange,
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Popup circular action button ──
Widget _buildPopupAction({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ── Section header inside popup ──
Widget _buildPopupSection({required String title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 28, bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.35),
            letterSpacing: 1.2,
          ),
        ),
      ),
      child,
    ],
  );
}

// ═══════════════════════════════════════════════════════════
//  Existing logic widgets (unchanged functionality)
// ═══════════════════════════════════════════════════════════

Widget buildMichangoDisplay(context, attendee, eventId, onStatusChange) {
  return Container(
    width: double.maxFinite,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pledged: Tsh ${attendee.pledgedAmount}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              "Paid: Tsh ${attendee.paidAmount}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        TextButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text("Edit"),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return MichangoEditor(attendee: attendee, eventId: eventId);
                },
              ),
            );
            onStatusChange("str");
          },
        ),
      ],
    ),
  );
}

Widget _buildDeliveryStatusIndicators(
  Attendee attendee,
  KardType kardType,
  String campaignId,
) {
  String smsStatus = "unsent";
  String whatsappStatus = "unsent";
  try {
    var msgIndexes = attendee.messageIndexes ?? [];
    for (var msgIndex in msgIndexes) {
      var parts = msgIndex.split("_");
      if (parts[0] == "sms" && parts[1] == campaignId) {
        smsStatus = parts[2];
      }
      if (parts[0] == "whatsapp" && parts[1] == campaignId) {
        whatsappStatus = parts[2];
      }
    }
  } catch (e) {}
  return Row(
    children: [
      _buildStatusChip(
        label: "SMS",
        status: smsStatus,
        brandData: Brands.wechat,
      ),
      const SizedBox(width: 10),
      _buildStatusChip(
        label: "WhatsApp",
        status: whatsappStatus,
        brandData: Brands.whatsapp,
      ),
    ],
  );
}

Widget _buildStatusChip({
  required String label,
  required String status,
  required String brandData,
}) {
  Color statusColor;
  Color backgroundColor;

  switch (status.toLowerCase()) {
    case "delivered":
    case "read":
      statusColor = Colors.greenAccent;
      backgroundColor = Colors.green.withValues(alpha: 0.2);
      break;
    case "sent":
      statusColor = Colors.lightBlueAccent;
      backgroundColor = Colors.blue.withValues(alpha: 0.2);
      break;
    case "pending":
    case "queued":
      statusColor = Colors.orangeAccent;
      backgroundColor = Colors.orange.withValues(alpha: 0.2);
      break;
    case "failed":
    case "undelivered":
      statusColor = Colors.redAccent;
      backgroundColor = Colors.red.withValues(alpha: 0.2);
      break;
    default:
      statusColor = Colors.grey.shade400;
      backgroundColor = Colors.grey.withValues(alpha: 0.2);
  }
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Brand(brandData, size: 14),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.5,
              height: 1,
            ),
            maxLines: 1,
          ),
        ],
      ),
    ),
  );
}

Widget _buildAttendanceControls(
  Attendee attendee,
  String eventId,
  Function(String) onStatusChange,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusButton(
          eventId,
          attendee,
          atconfstate,
          Icons.check_circle,
          Colors.green,
          attendee.attendanceStatus == atconfstate,
          onStatusChange,
        ),
        _buildStatusButton(
          eventId,
          attendee,
          atnotconfstate,
          Icons.schedule,
          Colors.grey,
          attendee.attendanceStatus == atnotconfstate ||
              attendee.attendanceStatus == null,
          onStatusChange,
        ),
        _buildStatusButton(
          eventId,
          attendee,
          atdeclstate,
          Icons.cancel,
          Colors.red,
          attendee.attendanceStatus == atdeclstate,
          onStatusChange,
        ),
        _buildStatusButton(
          eventId,
          attendee,
          atcallstate,
          Icons.call_made,
          Colors.teal,
          attendee.attendanceStatus == atcallstate,
          onStatusChange,
        ),
        _buildStatusButton(
          eventId,
          attendee,
          atunreachablestate,
          Icons.cloud_off_outlined,
          Colors.orange,
          attendee.attendanceStatus == atunreachablestate,
          onStatusChange,
        ),
      ],
    ),
  );
}

Widget _buildStatusButton(
  String eventId,
  Attendee attendee,
  String status,
  IconData icon,
  Color color,
  bool isActive,
  Function(String) onStatusChange,
) {
  return Expanded(
    child: InkWell(
      onTap: () {
        _updateAttendanceStatus(attendee, status, eventId, onStatusChange);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : color.withValues(alpha: 0.7),
        ),
      ),
    ),
  );
}

Future<void> _updateAttendanceStatus(
  Attendee attendee,
  String status,
  String eventId,
  Function(String) onStatusChange,
) async {
  try {
    await firestore
        .collection(ecol)
        .doc(eventId)
        .collection(atcol)
        .doc(attendee.id)
        .update({"attendanceStatus": status});
    showToast(isGood: true, msg: "Attendance status updated to $status");
    onStatusChange(status);
  } catch (e) {
    showToast(isGood: false, msg: "Error updating attendance status: $e");
  }
}
