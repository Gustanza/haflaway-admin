import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/attendee_card.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/crtattendees.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
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
  String? get searchFieldLabel => "Tafuta";

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
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: scagrad),
        child: Text("Andika jambo la kutafuta"),
      );
    }
    return Container(
      decoration: BoxDecoration(gradient: scagrad),
      child: FutureBuilder(
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
                  padding: EdgeInsets.only(
                    top: spaceTiles,
                    left: spaceTiles,
                    right: spaceTiles,
                    bottom: psm,
                  ),
                  itemBuilder: (context, index) {
                    Attendee attendee = atList[index];
                    var hasKey = false;
                    var campaignId =
                        widget.kardType == KardType.invitation
                            ? invCampId
                            : contrCampId;
                    return buildAttendeeCard(
                      hasKey: hasKey,
                      attendee: attendee,
                      kardType: widget.kardType,
                      eventId: widget.edata.id ?? "_",
                      campaignId: campaignId,
                      onEdit: () async {
                        await Navigator.of(context).push(
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
                      onSelected: () {
                        deleteTargAtt(atId: atList[index].id);
                      },
                      onStatusChange: (status) {
                        int index = atList.indexWhere(
                          (element) => element.id == attendee.id,
                        );
                        if (index != -1) {
                          atList[index].attendanceStatus = status;
                        }
                        safeState(() {});
                      },
                    );
                  },
                );
              } else {
                return buildErrorView();
              }
            } catch (e) {
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
                    .doc(widget.edata.id)
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

  safeState(runnable) {
    setState(() {
      runnable();
    });
  }

  popper() {
    Navigator.of(context).pop();
  }
}
