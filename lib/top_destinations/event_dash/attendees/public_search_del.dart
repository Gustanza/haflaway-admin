import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PubSearchDelegate extends SearchDelegate {
  String selType = '';
  final String eventId;
  final KardType kardType;

  PubSearchDelegate({required this.eventId, required this.kardType});

  @override
  String? get searchFieldLabel => "Search";

  @override
  TextStyle? get searchFieldStyle =>
      TextStyle(fontSize: fsm + 3, fontWeight: FontWeight.w500);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
          } else {
            query = '';
          }
        },
        icon: Icon(Clarity.close_line),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return BuildResultsList(query: query, eventId: eventId, kardType: kardType);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return BuildResultsList(query: query, eventId: eventId, kardType: kardType);
  }
}

class BuildResultsList extends StatefulWidget {
  final String query;
  final String eventId;
  final KardType kardType;
  const BuildResultsList({
    super.key,
    required this.query,
    required this.eventId,
    required this.kardType,
  });

  @override
  State<BuildResultsList> createState() => _BuildResultsListState();
}

class _BuildResultsListState extends State<BuildResultsList> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Attendee> atList = [];
  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: scagrad),
        child: Text("Type Something to Search"),
      );
    }
    return Container(
      decoration: BoxDecoration(gradient: scagrad),
      child: FutureBuilder(
        future: http.get(
          Uri.parse(
            "${getAttsUrl}/?eventId=${widget.eventId}&searchKey=${widget.query}",
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            try {
              var source = snapshot.data;
              var body = jsonDecode(source!.body);
              bool status = body['status'];
              if (status) {
                List data = body['data'];
                atList =
                    data.map((e) {
                      var item = e['item'];
                      return Attendee.fromMap(item['id'] ?? "", item);
                    }).toList();
                return ListView.builder(
                  itemCount: atList.length,
                  padding: EdgeInsets.only(top: psm, bottom: psm),
                  itemBuilder: (context, index) {
                    return buildAttendeeCard(atList[index]);
                  },
                );
              } else {
                return buildErrorView();
              }
            } catch (e) {
              debugPrint("Abject: ${e}");
              return buildErrorView();
            }
          } else if (snapshot.hasError) {
            return buildErrorView();
          } else
            return Center(child: CupertinoActivityIndicator());
        },
      ),
    );
  }

  deleteTargAtt({atId}) async {
    return await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text("Destructive Action"),
          message: Text(
            "You are about to delete an attendee, keep in mind this action is ireversible",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: fsm),
          ),
          actions: [
            CupertinoActionSheetAction(
              isDefaultAction: true,
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                firestore
                    .collection(ecol)
                    .doc(widget.eventId)
                    .collection(atcol)
                    .doc(atId)
                    .delete()
                    .then((onValue) {
                      showToast(isGood: true, msg: "Succesful deletion");
                      if (mounted) {
                        setState(() {});
                      }
                    })
                    .catchError((onError) {
                      showToast(isGood: false, msg: "Deletion failed");
                    });
                popper();
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("Cancel"),
            onPressed: popper,
          ),
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }

  Widget buildAttendeeCard(Attendee attendee) {
    var fullname = attendee.fullName;
    var attrCrdMap = attendee.cards[widget.kardType.name];
    AttributeCard? attributeCard;
    attributeCard =
        attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
    String crdnm =
        attributeCard != null ? attributeCard.name ?? "Not Set" : "Not Set";

    // var hasKey = selectList.any((test) {
    //   return test.id == attendee.id;
    // });

    // Calculate message count if messages property exists
    int messageCount = 0;
    messageCount = (attendee.messages).length;

    return GestureDetector(
      onTap: () {
        // Toggle selection on tap
        // if (hasKey) {
        //   var tmp =
        //       selectList.where((test) {
        //         return test.id != attendee.id;
        //       }).toList();
        //   selectList = tmp;
        // } else {
        //   selectList.add(attendee);
        // }
        // setState(() {});
      },
      child: Container(
        margin: EdgeInsets.only(left: psm, right: psm, bottom: psm * 0.5),
        decoration: BoxDecoration(
          gradient: lqassgrad,
          border: lqassbdr,

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
                        // _buildDeliveryStatusIndicators(attendee),
                      ],
                    ),
                  ),
                  // Action buttons - compact
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View card button
                      Material(
                        color: lqassgradBaseColor,
                        borderRadius: BorderRadius.circular(bsm),
                        child: InkWell(
                          onTap: () {
                            var vcrd = attendee.cards[widget.kardType.name];
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
                            child: Text("Tazama"),
                          ),
                        ),
                      ),

                      // Call button
                    ],
                  ),
                ],
              ),
              SizedBox(height: psm * 0.5),
              // Attendance controls - compact
              _buildAttendanceControls(attendee),
            ],
          ),
        ),
      ),
    );
  }

  // Build attendance controls
  Widget _buildAttendanceControls(Attendee attendee) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: psm * 0.5,
        vertical: psm * 0.375,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusButton(
            attendee,
            atconfstate,
            Icons.check_circle,
            Colors.green,
            attendee.attendanceStatus == atconfstate,
          ),
          _buildStatusButton(
            attendee,
            atnotconfstate,
            Icons.schedule,
            Colors.grey,
            attendee.attendanceStatus == atnotconfstate ||
                attendee.attendanceStatus == null,
          ),
          _buildStatusButton(
            attendee,
            atdeclstate,
            Icons.cancel,
            Colors.red,
            attendee.attendanceStatus == atdeclstate,
          ),
          _buildStatusButton(
            attendee,
            atcallstate,
            Icons.call_made,
            Colors.teal,
            attendee.attendanceStatus == atcallstate,
          ),
          _buildStatusButton(
            attendee,
            atunreachablestate,
            Icons.cloud_off_outlined,
            Colors.orange,
            attendee.attendanceStatus == atunreachablestate,
          ),
        ],
      ),
    );
  }

  // Build status button
  Widget _buildStatusButton(
    Attendee attendee,
    String status,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          updateAttendanceStatus(attendee, status);
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

  Future<void> updateAttendanceStatus(Attendee attendee, String status) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Perform the update
      await firestore
          .collection(ecol)
          .doc(widget.eventId)
          .collection(atcol)
          .doc(attendee.id)
          .update({"attendanceStatus": status});

      // Update local state
      int index = atList.indexWhere((element) => element.id == attendee.id);
      if (index != -1) {
        atList[index].attendanceStatus = status;
      }

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      showToast(isGood: true, msg: "Attendance status updated to $status");

      // Trigger UI refresh
      setState(() {});
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      showToast(isGood: false, msg: "Error updating attendance status: $e");
    }
  }
}
