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

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens  ·  mirrors admin_pane.dart / attendees.dart
// ─────────────────────────────────────────────────────────────────────────────

abstract class _C {
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const card3   = Color(0xFF3A3A3C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white   = Color(0xFFFFFFFF);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl2    = Color(0xFFAEAEB2);
  static const lbl3    = Color(0xFF8E8E93);
  static const lbl4    = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}

// ═══════════════════════════════════════════════════════════
//  Attendee list tile
// ═══════════════════════════════════════════════════════════

Widget buildAttendeeCard({
  required Attendee attendee,
  required KardType kardType,
  required Function() onEdit,
  required bool hasKey,
  required String campaignId,
  required String eventId,
  required List<AttendeeLabel> allLabels,
  required Function() onSelected,
  required Function(String) onStatusChange,
  bool showMessageStatus = true,
}) {
  final fullname = attendee.fullName;

  // Initials
  final initials = fullname
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  // Consistent per-name hue, kept in the 40–60 % lightness band so it's
  // always visible against the card background.
  final hue = (fullname.hashCode % 360).abs().toDouble();
  final avatarColor = HSLColor.fromAHSL(1, hue, 0.55, 0.60).toColor();

  final int messageCount = attendee.messages.length;

  return StatefulBuilder(
    builder: (context, setState) {
      return GestureDetector(
        onLongPress: onSelected,
        onTap: () => _showDetailPopup(
          context: context,
          attendee: attendee,
          kardType: kardType,
          campaignId: campaignId,
          eventId: eventId,
          onEdit: onEdit,
          onStatusChange: onStatusChange,
          showMessageStatus: showMessageStatus,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Builder(builder: (context) {
            final isPending = attendee.isCardPending(kardType);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: hasKey ? _C.limeDim : _C.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPending
                      ? Colors.orange.withValues(alpha: 0.35)
                      : hasKey
                          ? _C.lime.withValues(alpha: 0.45)
                          : _C.sep,
                  width: isPending || hasKey ? 1.2 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  // ── Avatar ──────────────────────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarColor.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: _C.f(
                              size: 16,
                              weight: FontWeight.w700,
                              color: avatarColor,
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
                            padding: EdgeInsets.all(messageCount > 9 ? 2 : 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: _C.card, width: 2),
                            ),
                            constraints:
                                const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              messageCount > 99 ? "99+" : "$messageCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // ── Name + Phone + Labels ────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullname,
                          style: _C.f(
                            size: 15,
                            weight: FontWeight.w600,
                            color: _C.lbl1,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                attendee.phone,
                                style: _C.f(size: 13, color: _C.lbl3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPending)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.orange.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.30),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.hourglass_empty_rounded,
                                      color: Colors.orange,
                                      size: 9,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "PENDING",
                                      style: _C.f(
                                        size: 9,
                                        weight: FontWeight.w800,
                                        color: Colors.orange,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // Labels
                        if (attendee.labelIds != null &&
                            attendee.labelIds!.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: attendee.labelIds!.map((labelId) {
                              final label = allLabels.firstWhere(
                                (l) => l.id == labelId,
                                orElse: () => AttendeeLabel(
                                  id: '',
                                  name: '?',
                                  colorValue: 0xFF8E8E93,
                                ),
                              );
                              final c = Color(label.colorValue);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: c.withValues(alpha: 0.4),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  label.name,
                                  style: _C.f(
                                    size: 9,
                                    weight: FontWeight.w700,
                                    color: c,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Status dot ──────────────────────────────────────
                  if (kardType == KardType.invitation)
                    _buildStatusDot(attendee.attendanceStatus),
                ],
              ),
            );
          }),
        ),
      );
    },
  );
}

// ── Attendance status dot ────────────────────────────────────────────────────

Widget _buildStatusDot(String? status) {
  Color dotColor;
  switch (status) {
    case atconfstate:
      dotColor = const Color(0xFF30D158); // Apple green
      break;
    case atdeclstate:
      dotColor = const Color(0xFFFF453A); // Apple red
      break;
    case atcallstate:
      dotColor = const Color(0xFF64D2FF); // Apple teal
      break;
    case atunreachablestate:
      dotColor = const Color(0xFFFF9F0A); // Apple orange
      break;
    default:
      dotColor = _C.lbl4;
  }
  return Container(
    width: 9,
    height: 9,
    margin: const EdgeInsets.only(left: 10),
    decoration: BoxDecoration(
      color: dotColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: dotColor.withValues(alpha: 0.45),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Detail popup — glassmorphic bottom sheet
// ═══════════════════════════════════════════════════════════

void _showDetailPopup({
  required BuildContext context,
  required Attendee attendee,
  required KardType kardType,
  required String campaignId,
  required String eventId,
  required Function() onEdit,
  required Function(String) onStatusChange,
  bool showMessageStatus = true,
}) {
  final attrCrdMap = attendee.cards[kardType.name];
  final attributeCard =
      attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
  final crdnm = attributeCard?.name ?? "Not Set";

  final fullname = attendee.fullName;
  final hue = (fullname.hashCode % 360).abs().toDouble();
  final avatarColor = HSLColor.fromAHSL(1, hue, 0.55, 0.60).toColor();
  final initials = fullname
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
          return ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Handle ────────────────────────────────────
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 24),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _C.card3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // ── Avatar + identity ─────────────────────────
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarColor.withValues(alpha: 0.45),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: _C.f(
                              size: 28,
                              weight: FontWeight.w800,
                              color: avatarColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        fullname,
                        style: _C.f(
                          size: 22,
                          weight: FontWeight.w800,
                          color: _C.white,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendee.phone,
                        style: _C.f(size: 14, color: _C.lbl3),
                      ),
                      const SizedBox(height: 10),

                      // ── Card-type badge ───────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _C.limeDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _C.lime.withValues(alpha: 0.35),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          crdnm,
                          style: _C.f(
                            size: 11,
                            weight: FontWeight.w700,
                            color: _C.lime,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Quick actions ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: _C.card2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _C.sep, width: 0.8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildPopupAction(
                                icon: Icons.call_rounded,
                                label: "Call",
                                color: const Color(0xFF30D158),
                                onTap: () => callNumber(attendee.phone),
                              ),
                              if (kardType == KardType.invitation ||
                                  kardType == KardType.contribution)
                                _buildPopupAction(
                                  icon: Clarity.eye_show_line,
                                  label: "Card",
                                  color: const Color(0xFF0A84FF),
                                  onTap: () {
                                    final vcrd =
                                        attendee.cards[kardType.name];
                                    if (vcrd != null) {
                                      final attrCrd =
                                          AttributeCard.fromMap(map: vcrd);
                                      try {
                                        launchUrl(
                                            Uri.parse(attrCrd.url ?? ""));
                                      } catch (e) {
                                        showToast(
                                            isGood: false, msg: "$e");
                                      }
                                    } else {
                                      showToast(
                                          isGood: false,
                                          msg: "Unable to View");
                                    }
                                  },
                                ),
                              _buildPopupAction(
                                icon: Icons.edit_rounded,
                                label: "Edit",
                                color: const Color(0xFFFF9F0A),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  onEdit();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Message status ─────────────────────────────
                      if (showMessageStatus)
                        _buildPopupSection(
                          title: "Message Status",
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildDeliveryStatusIndicators(
                                attendee, kardType, campaignId),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ── Attendance controls ────────────────────────
                      if (kardType == KardType.invitation)
                        _buildPopupSection(
                          title: "Attendance Status",
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildAttendanceControls(
                              attendee,
                              eventId,
                              (status) {
                                onStatusChange(status);
                                popupSetState(() {});
                              },
                            ),
                          ),
                        ),

                      // ── Contribution details ───────────────────────
                      if (kardType == KardType.contribution ||
                          kardType == KardType.contact)
                        _buildPopupSection(
                          title: "Contribution Details",
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: buildMichangoDisplay(
                                context, attendee, eventId, onStatusChange),
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

// ── Circular quick-action button ─────────────────────────────────────────────

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
            color: color.withValues(alpha: 0.13),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: _C.f(size: 11, weight: FontWeight.w600, color: _C.lbl3),
        ),
      ],
    ),
  );
}

// ── Section header inside popup ──────────────────────────────────────────────

Widget _buildPopupSection({required String title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 24, bottom: 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: _C.lime,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: _C.f(
                size: 10,
                weight: FontWeight.w700,
                color: _C.lbl3,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
      child,
    ],
  );
}

// ═══════════════════════════════════════════════════════════
//  Logic widgets — functionality unchanged, surfaces updated
// ═══════════════════════════════════════════════════════════

Widget buildMichangoDisplay(
    context, Attendee attendee, String eventId, Function(String) onStatusChange) {
  return Container(
    width: double.maxFinite,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _C.card2,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.sep, width: 0.8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pledged: Tsh ${attendee.pledgedAmount}",
              style: _C.f(size: 13, weight: FontWeight.w600, color: _C.lbl1),
            ),
            const SizedBox(height: 3),
            Text(
              "Paid: Tsh ${attendee.paidAmount}",
              style: _C.f(size: 13, weight: FontWeight.w600, color: _C.lbl2),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    MichangoEditor(attendee: attendee, eventId: eventId),
              ),
            );
            onStatusChange("str");
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _C.limeDim,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: _C.lime.withValues(alpha: 0.35), width: 0.7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, color: _C.lime, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Edit",
                  style: _C.f(
                      size: 13, weight: FontWeight.w700, color: _C.lime),
                ),
              ],
            ),
          ),
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
    final msgIndexes = attendee.messageIndexes ?? [];
    for (final msgIndex in msgIndexes) {
      final parts = msgIndex.split("_");
      if (parts[0] == "sms" && parts[1] == campaignId) smsStatus = parts[2];
      if (parts[0] == "whatsapp" && parts[1] == campaignId)
        whatsappStatus = parts[2];
    }
  } catch (_) {}

  return Row(
    children: [
      _buildStatusChip(label: "SMS", status: smsStatus, brandData: Brands.wechat),
      const SizedBox(width: 10),
      _buildStatusChip(
          label: "WhatsApp",
          status: whatsappStatus,
          brandData: Brands.whatsapp),
    ],
  );
}

Widget _buildStatusChip({
  required String label,
  required String status,
  required String brandData,
}) {
  Color statusColor;
  Color bgColor;

  switch (status.toLowerCase()) {
    case "delivered":
    case "read":
      statusColor = const Color(0xFF30D158);
      bgColor = const Color(0xFF30D158);
      break;
    case "sent":
      statusColor = const Color(0xFF64D2FF);
      bgColor = const Color(0xFF64D2FF);
      break;
    case "pending":
    case "queued":
      statusColor = const Color(0xFFFF9F0A);
      bgColor = const Color(0xFFFF9F0A);
      break;
    case "failed":
    case "undelivered":
      statusColor = const Color(0xFFFF453A);
      bgColor = const Color(0xFFFF453A);
      break;
    default:
      statusColor = _C.lbl4;
      bgColor = _C.lbl4;
  }

  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(50),
        border:
            Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Brand(brandData, size: 13),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: _C.f(
              size: 8,
              weight: FontWeight.w800,
              color: statusColor,
              letterSpacing: 0.6,
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
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: _C.card2,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.sep, width: 0.8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusButton(eventId, attendee, atconfstate,
            Icons.check_circle_rounded, const Color(0xFF30D158),
            attendee.attendanceStatus == atconfstate, onStatusChange),
        _buildStatusButton(eventId, attendee, atnotconfstate,
            Icons.schedule_rounded, _C.lbl4,
            attendee.attendanceStatus == atnotconfstate ||
                attendee.attendanceStatus == null,
            onStatusChange),
        _buildStatusButton(eventId, attendee, atdeclstate,
            Icons.cancel_rounded, const Color(0xFFFF453A),
            attendee.attendanceStatus == atdeclstate, onStatusChange),
        _buildStatusButton(eventId, attendee, atcallstate,
            Icons.call_made_rounded, const Color(0xFF64D2FF),
            attendee.attendanceStatus == atcallstate, onStatusChange),
        _buildStatusButton(eventId, attendee, atunreachablestate,
            Icons.cloud_off_rounded, const Color(0xFFFF9F0A),
            attendee.attendanceStatus == atunreachablestate, onStatusChange),
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
    child: GestureDetector(
      onTap: () =>
          _updateAttendanceStatus(attendee, status, eventId, onStatusChange),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isActive ? color : color.withValues(alpha: 0.25),
            width: isActive ? 1.2 : 0.8,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? color : color.withValues(alpha: 0.5),
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
