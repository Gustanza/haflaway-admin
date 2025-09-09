import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/crtattendees.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/view_card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:http/http.dart' as http;

class DhaSearchDelegate extends SearchDelegate {
  String selType = '';
  final Event edata;
  final KardType kardType;

  DhaSearchDelegate({required this.edata, required this.kardType});

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
    return BuildResultsList(query: query, edata: edata, kardType: kardType);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return BuildResultsList(query: query, edata: edata, kardType: kardType);
  }
}

class BuildResultsList extends StatefulWidget {
  final String query;
  final Event edata;
  final KardType kardType;
  const BuildResultsList({
    super.key,
    required this.query,
    required this.edata,
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
      return Center(child: Text("Type Something to Search"));
    }
    return FutureBuilder(
      future: http.get(
        Uri.parse(
          "${getAttsUrl}/?eventId=${widget.edata.id}&searchKey=${widget.query}",
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
    );
  }

  Widget buildAttendeeCard(Attendee attendee) {
    var fullname = attendee.fullName;
    var attrCrdMap = attendee.cards[widget.kardType.name];
    AttributeCard? attributeCard;
    attributeCard =
        attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
    String crdnm =
        attributeCard != null ? attributeCard.name ?? "Not Set" : "Not Set";

    // Calculate message count if messages property exists
    int messageCount = 0;
    messageCount = (attendee.messages).length;

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.only(left: psm, right: psm, bottom: psm * 0.75),
        decoration: BoxDecoration(
          gradient: lqassgrad,
          border: lqassbdr,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(psm),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                children: [
                  // first child
                  Stack(
                    children: [
                      Hero(
                        tag: "avatar-${attendee.id}",
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              size: 28,
                              Icons.account_circle,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      if (messageCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                messageCount > 99 ? "99+" : "$messageCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // second child
                  const SizedBox(width: psm),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fullname,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fsm + 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.event, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    crdnm,
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                // const SizedBox(width: psm * 2),
                                TextButton(
                                  onPressed: () {
                                    var vcrd =
                                        attendee.cards[widget.kardType.name];
                                    if (vcrd != null) {
                                      AttributeCard attrCrd =
                                          AttributeCard.fromMap(map: vcrd);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return ViewCard(
                                              cardUrl: attrCrd.url ?? "",
                                            );
                                          },
                                        ),
                                      );
                                    } else {
                                      showToast(
                                        isGood: false,
                                        msg: "Unable to View",
                                      );
                                    }
                                  },
                                  child: Icon(
                                    Clarity.eye_show_line,
                                    size: icnmd,
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                Icon(Clarity.mobile_phone_line, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  attendee.phone,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: psm * 2),
                                Transform.scale(
                                  scale: 0.75,
                                  child: IconButton.outlined(
                                    onPressed: () {
                                      callNumber(attendee.phone);
                                    },
                                    icon: const Icon(Icons.call, size: icnsm),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: IconButton.outlined(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return CreateAttendees(
                                              event: widget.edata,
                                              kardType: widget.kardType,
                                              attendee: attendee,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.edit_document,
                                      size: icnsm,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: psm * 0.5),
                      ],
                    ),
                  ),
                ],
              ),

              _buildAttendanceControls(attendee),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceControls(Attendee attendee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        border: lqassbdr,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusButton(
            attendee,
            "Confirmed",
            Icons.check_circle,
            Colors.green,
            attendee.attendanceStatus == "Confirmed",
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            attendee,
            "Not Confirmed",
            Icons.schedule,
            Colors.grey,
            attendee.attendanceStatus == "Not Confirmed" ||
                attendee.attendanceStatus == null,
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            attendee,
            "Declined",
            Icons.cancel,
            Colors.red,
            attendee.attendanceStatus == "Declined",
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            attendee,
            "Call Made",
            Icons.call_made,
            Colors.teal,
            attendee.attendanceStatus == "Call Made",
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
    return InkWell(
      onTap: () {
        // Vibrate for haptic feedback
        HapticFeedback.mediumImpact();
        updateAttendanceStatus(attendee, status);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : color),
            if (isActive) const SizedBox(width: 4),
            if (isActive)
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
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
          .doc(widget.edata.id)
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
