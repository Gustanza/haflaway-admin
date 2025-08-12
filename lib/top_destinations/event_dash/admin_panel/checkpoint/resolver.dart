import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'dart:ui';
import 'package:haflaway/utils/globalwids.dart';

class AttendeeCheckInView extends StatefulWidget {
  final bool showAppBar;
  final String attId;
  final String eId;
  final String chckpntId;
  final Function() onPressed;
  // Add other required parameters as needed

  const AttendeeCheckInView({
    Key? key,
    required this.attId,
    required this.eId,
    this.showAppBar = false,
    required this.onPressed,
    required this.chckpntId,
  }) : super(key: key);

  @override
  State<AttendeeCheckInView> createState() => _AttendeeCheckInViewState();
}

class _AttendeeCheckInViewState extends State<AttendeeCheckInView>
    with SingleTickerProviderStateMixin {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Widget buildGlassCard({required Widget child, double? height}) {
    return Container(
      height: height,
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(bmd),
        gradient: lqassgrad,
        border: Border.all(color: lqassbdrColor, width: 0.5),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );
  }

  Widget buildAttendeeCard(Attendee attendee) {
    var source = attendee.cards[KardType.invitation.name];
    AttributeCard? attrCard =
        source != null ? AttributeCard.fromMap(map: source) : null;
    return buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Section with Glow Effect
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lqassgradBaseColor,
              ),
              child: const Icon(
                CupertinoIcons.checkmark_seal_fill,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            // Name with gradient text
            ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    colors: [Colors.white, Colors.white70],
                  ).createShader(bounds),
              child: Text(
                attendee.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            // Cards info with glass pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: lqassgrad,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.creditcard,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Card Designation: ${attrCard?.name}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
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

  Widget buildCheckInItem(
    Map<String, dynamic> atSts,
    int idx,
    Attendee attendee,
    dynamic docRef,
  ) {
    bool actlStatus = atSts[crdChkpns][widget.chckpntId] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: actlStatus ? Colors.green : Colors.grey,
                  boxShadow:
                      actlStatus
                          ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                          : [],
                ),
              ),

              const SizedBox(width: 16),

              // Name and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${atSts[cattendeename]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          actlStatus
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 14,
                          color:
                              actlStatus
                                  ? Colors.green.shade400
                                  : Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          actlStatus ? "Checked In" : "Not Checked In",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                actlStatus
                                    ? Colors.green.shade400
                                    : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      if (!actlStatus) {
                        attendee.checkinStatus[idx][crdChkpns][widget
                                .chckpntId] =
                            true;
                        docRef.update({
                          "checkinStatus": attendee.checkinStatus,
                        });
                      } else {
                        await showCheckout(
                          idx: idx,
                          attendee: attendee,
                          docRef: docRef,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        !actlStatus ? "Check In" : "Checked",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
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

  showCheckout({idx, docRef, attendee}) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Checkout"),
          content: const Text("Are you sure you want to checkout?"),
          actions: [
            CupertinoButton(
              borderRadius: BorderRadius.zero,
              color: primaryColor,
              onPressed: () {
                attendee.checkinStatus[idx][crdChkpns][widget.chckpntId] =
                    false;
                docRef.update({"checkinStatus": attendee.checkinStatus});
                Navigator.pop(context);
              },
              child: const Text(
                "Checkout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var docRef = firestore
        .collection(ecol)
        .doc(widget.eId)
        .collection(atcol)
        .doc(widget.attId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar:
          widget.showAppBar
              ? appBar(
                title: "",
                leading: buildActionButton(
                  icon: Icons.arrow_back,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              )
              : null,
      body: Container(
        height: double.maxFinite,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder(
            stream: docRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var data = (snapshot.data as dynamic).data();
                if (data != null) {
                  Attendee attendee = Attendee.fromMap(widget.attId, data);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Attendee Card
                        buildAttendeeCard(attendee),
                        const SizedBox(height: p20),
                        // Check-in List Title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Check-in Status",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Check-in Items
                        ...List.generate(
                          attendee.checkinStatus.length,
                          (idx) => buildCheckInItem(
                            attendee.checkinStatus[idx],
                            idx,
                            attendee,
                            docRef,
                          ),
                        ),
                        const SizedBox(height: p20),
                        if (!widget.showAppBar)
                          SizedBox(
                            width: double.maxFinite,
                            child: MaterialButton(
                              color: primaryColor,
                              height: kToolbarHeight * 0.9,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(
                                  bmd,
                                ),
                              ),
                              onPressed: widget.onPressed,
                              child: Text(
                                "SCAN NEXT",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return buildErr();
                }
              } else if (snapshot.hasError) {
                return buildErr();
              } else {
                return buildLoader();
              }
            },
          ),
        ),
      ),
    );
  }
}
