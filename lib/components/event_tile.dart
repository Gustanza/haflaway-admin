import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/providers/package_provider.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:provider/provider.dart';

class EventTile extends StatefulWidget {
  final Event eventData;
  final VoidCallback? onRefresh;
  const EventTile({super.key, required this.eventData, this.onRefresh});

  @override
  State<EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<EventTile> with TickerProviderStateMixin {
  final DateFormat tformtr = DateFormat('HH:mm');
  final DateFormat dformtr = DateFormat('MMM d');
  final DateFormat dayformtr = DateFormat('EEEE');
  bool isPressed = false;
  String uid = FirebaseAuth.instance.currentUser?.uid ?? "_";

  @override
  Widget build(BuildContext context) {
    var dt = widget.eventData.startDate;
    var eventDate = dformtr.format(DateTime.parse(dt!));
    var eventfDt = formatDate(dtime: DateTime.parse(dt));
    var prov = context.read<PackageProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Teme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: buildImage(url: widget.eventData.eventThumbnail),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      // gradient: LinearGradient(
                      //   begin: Alignment.topCenter,
                      //   end: Alignment.bottomCenter,
                      //   colors: [Colors.transparent, Colors.black54],
                      // ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            eventDate.split(' ')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            eventDate.split(' ')[1],
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventData.title ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          eventfDt,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_pin,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.eventData.location}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (prov.isSuperAdmin) {
                            await showPublish(
                              eventId: widget.eventData.id ?? "_",
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'STATUS: ${widget.eventData.status?.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (prov.isSuperAdmin) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await showDeleteConfirm(
                              eventId: widget.eventData.id ?? "_",
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: destructiveColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: destructiveColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.delete,
                              color: destructiveColor,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  showDeleteConfirm({eventId}) {
    TextEditingController confirmCon = TextEditingController();
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text("Delete Event"),
              content: Column(
                children: [
                  const Text(
                    "This action is IRREVERSIBLE and will delete all event data. Type \"delete permanently\" to confirm.",
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: confirmCon,
                    placeholder: "delete permanently",
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) {
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text("Cancel"),
                  onPressed: () => popper(),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed:
                      confirmCon.text == "delete permanently"
                          ? () {
                            FirebaseFirestore.instance
                                .collection(ecol)
                                .doc(eventId)
                                .delete()
                                .then((e) {
                                  showToast(isGood: true, msg: "Event Deleted");
                                  widget.onRefresh?.call();
                                })
                                .catchError((e) {
                                  showToast(isGood: false, msg: "$e");
                                });
                            popper();
                          }
                          : null,
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  showPublish({eventId}) {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Event Status"),
          content: Text(
            "Beware that this action will impact visibility of this Event to the end-users",
          ),
          actions: [
            CupertinoButton(
              color: destructiveColor,
              child: Text("Unpublish", style: TextStyle(color: primaryWhite)),
              borderRadius: BorderRadius.zero,
              onPressed: () {
                FirebaseFirestore.instance
                    .collection(ecol)
                    .doc(eventId)
                    .update({"status": "Draft"})
                    .then((e) {
                      showToast(isGood: true, msg: "Event set as Draft");
                      widget.onRefresh?.call();
                    })
                    .catchError((e) {
                      showToast(isGood: false, msg: "$e");
                    });
                popper();
              },
            ),
            CupertinoButton(
              child: Text("Publish", style: TextStyle(color: primaryWhite)),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection(ecol)
                    .doc(eventId)
                    .update({"status": "Published"})
                    .then((e) {
                      showToast(isGood: true, msg: "Event has been published");
                      widget.onRefresh?.call();
                    })
                    .catchError((e) {
                      showToast(isGood: false, msg: "$e");
                    });
                popper();
              },
            ),
          ],
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}
