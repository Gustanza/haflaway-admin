import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/globalwids.dart';

class EventTile extends StatefulWidget {
  final Event eventData;
  const EventTile({super.key, required this.eventData});

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
    var dt = widget.eventData.calendar?.first.eventDate;
    var eventDate = dformtr.format(dt!);
    var eventfDt = formatDate(dtime: dt);

    return Container(
      margin: const EdgeInsets.only(bottom: psm - 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: secscagrad,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
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
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: buildImage(url: widget.eventData.eventThumbnail),
                    ),
                  ),
                  // Gradient overlay for better text readability
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ),
                  // Date Badge
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
                              eventDate.split(' ')[0].toUpperCase(), // Month
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              eventDate.split(' ')[1], // Day
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
                        Text(
                          '${eventfDt}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status indicator
                    GestureDetector(
                      onTap: () async {},
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
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
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
                      showToast(isGood: false, msg: "Event set as Draft");
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
                      showToast(isGood: false, msg: "Event has been published");
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
