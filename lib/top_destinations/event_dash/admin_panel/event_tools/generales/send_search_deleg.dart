import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/attendee_card.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/crtattendees.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:http/http.dart' as http;

class SendSearchDelegate extends SearchDelegate {
  String selType = '';
  final Event event;
  final String campaignId;
  final KardType kardType;

  SendSearchDelegate({
    required this.event,
    required this.kardType,
    required this.campaignId,
  });

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
    return BuildResultsList(
      query: query,
      event: event,
      kardType: kardType,
      campaignId: campaignId,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return BuildResultsList(
      query: query,
      event: event,
      kardType: kardType,
      campaignId: campaignId,
    );
  }
}

class BuildResultsList extends StatefulWidget {
  final String query;
  final Event event;
  final KardType kardType;
  final String campaignId;
  const BuildResultsList({
    super.key,
    required this.query,
    required this.event,
    required this.campaignId,
    required this.kardType,
  });

  @override
  State<BuildResultsList> createState() => _BuildResultsListState();
}

class _BuildResultsListState extends State<BuildResultsList> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Attendee> selectList = [];
  List<Attendee> attendeesList = [];
  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: scagrad),
        child: Text("Type Something to Search"),
      );
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(bmd * 10),
          side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
        ),
        foregroundColor: Colors.white,
        child: Icon(Icons.arrow_forward),
        onPressed: () {},
      ),
      body: Ccafold(
        child: FutureBuilder(
          future: http.get(
            Uri.parse(
              "${getAttsUrl}/?eventId=${widget.event.id}&searchKey=${widget.query}",
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
                  attendeesList =
                      data.map((e) {
                        var item = e['item'];
                        return Attendee.fromMap(item['id'] ?? "", item);
                      }).toList();
                  return ListView.builder(
                    itemCount: attendeesList.length,
                    padding: EdgeInsets.all(spaceTiles),
                    itemBuilder: (context, index) {
                      Attendee attendee = attendeesList[index];
                      var hasKey = selectList.any((test) {
                        return test.id == attendee.id;
                      });
                      return buildAttendeeCard(
                        hasKey: hasKey,
                        attendee: attendee,
                        kardType: widget.kardType,
                        eventId: widget.event.id ?? "_",
                        campaignId: widget.campaignId,
                        onEdit: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return CreateAttendees(
                                  event: widget.event,
                                  kardType: widget.kardType,
                                  attendee: attendee,
                                );
                              },
                            ),
                          );
                          // loadAttendees();
                        },
                        onSelected: () {
                          if (hasKey) {
                            var tmp =
                                selectList.where((test) {
                                  return test.id != attendee.id;
                                }).toList();
                            selectList = tmp;
                          } else {
                            selectList.add(attendee);
                          }
                          safeState(() {});
                        },
                        onStatusChange: (status) {
                          int index = attendeesList.indexWhere(
                            (element) => element.id == attendee.id,
                          );
                          if (index != -1) {
                            attendeesList[index].attendanceStatus = status;
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
                debugPrint("Abject: ${e}");
                return buildErrorView();
              }
            } else if (snapshot.hasError) {
              return buildErrorView();
            } else
              return Center(child: CupertinoActivityIndicator());
          },
        ),
      ),
    );
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
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
                    .doc(widget.event.id)
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
}
