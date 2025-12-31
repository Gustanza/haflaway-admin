import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

Widget buildAttendeeCard({
  required Attendee attendee,
  required KardType kardType,
  required Function() onEdit,
  required bool hasKey,
  required String campaignId,
  required String eventId,
  required Function() onSelected,
  required Function(String) onStatusChange,
}) {
  var fullname = attendee.fullName;
  var attrCrdMap = attendee.cards[kardType.name];
  AttributeCard? attributeCard;
  attributeCard =
      attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
  String crdnm =
      attributeCard != null ? attributeCard.name ?? "Not Set" : "Not Set";

  // Calculate message count if messages property exists
  int messageCount = 0;
  messageCount = (attendee.messageIndexes)?.length ?? 0;

  // stful builder
  return StatefulBuilder(
    builder: (context, setState) {
      return GestureDetector(
        onLongPress: onSelected,
        child: Container(
          margin: EdgeInsets.only(bottom: psm * 0.5),
          decoration: BoxDecoration(
            gradient: lqassgrad,
            border:
                !hasKey
                    ? lqassbdr
                    : Border.all(color: Colors.redAccent, width: bdrWidthGen),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(psm * 0.625),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Avatar, Name, Actions
                Row(
                  children: [
                    // Avatar with message badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Hero(
                          tag: "avatar-${attendee.id}",
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_circle,
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        if (messageCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: EdgeInsets.all(messageCount > 9 ? 3 : 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
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
                    SizedBox(width: psm * 0.5),
                    // Name and info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fullname,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fsm + 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: psm * 0.25),
                          // Card name and phone in compact row
                          Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              SizedBox(width: 4),
                              Text(
                                crdnm,
                                style: TextStyle(
                                  fontSize: fsm - 1,
                                  overflow: TextOverflow.ellipsis,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                              ),
                              SizedBox(width: psm),
                              Icon(
                                Clarity.mobile_phone_line,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  attendee.phone,
                                  style: TextStyle(
                                    fontSize: fsm - 1,
                                    overflow: TextOverflow.ellipsis,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: psm * 0.375),
                          // Delivery status indicators - SMS & WhatsApp
                          _buildDeliveryStatusIndicators(
                            attendee,
                            kardType,
                            campaignId,
                          ),
                        ],
                      ),
                    ),
                    // Action buttons - compact
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View card button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              var vcrd = attendee.cards[kardType.name];
                              if (vcrd != null) {
                                AttributeCard attrCrd = AttributeCard.fromMap(
                                  map: vcrd,
                                );
                                try {
                                  launchUrl(Uri.parse(attrCrd.url ?? ""));
                                } catch (e) {
                                  showToast(isGood: false, msg: "$e");
                                }
                              } else {
                                showToast(isGood: false, msg: "Unable to View");
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Clarity.eye_show_line,
                                size: icnsm + 2,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                        // Call button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => callNumber(attendee.phone),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.call,
                                size: icnsm + 2,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                        // Edit button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onEdit,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.edit,
                                size: icnsm + 2,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: psm * 0.5),
                // Attendance controls - compact
                _buildAttendanceControls(attendee, eventId, onStatusChange),
              ],
            ),
          ),
        ),
      );
    },
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
      // SMS Status Indicator
      _buildStatusChip(
        label: "SMS",
        status: smsStatus,
        brandData: Brands.wechat,
      ),
      SizedBox(width: psm * 0.5),
      // WhatsApp Status Indicator
      _buildStatusChip(
        label: "WhatsApp",
        status: whatsappStatus,
        brandData: Brands.whatsapp,
      ),
    ],
  );
}

// Build individual status chip
Widget _buildStatusChip({
  required String label,
  required String status,
  required String brandData,
}) {
  // Determine status color and styling based on status text
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
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: psm * 0.1),
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
          SizedBox(width: 5),
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

// Build attendance controls
Widget _buildAttendanceControls(
  Attendee attendee,
  String eventId,
  Function(String) onStatusChange,
) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: spaceTiles,
      vertical: psm * 0.375,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
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

// Build status button
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: psm * 0.375),
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
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
    // Perform the update
    await firestore
        .collection(ecol)
        .doc(eventId)
        .collection(atcol)
        .doc(attendee.id)
        .update({"attendanceStatus": status});
    // Show success message
    showToast(isGood: true, msg: "Attendance status updated to $status");
    onStatusChange(status);
  } catch (e) {
    showToast(isGood: false, msg: "Error updating attendance status: $e");
  }
}
