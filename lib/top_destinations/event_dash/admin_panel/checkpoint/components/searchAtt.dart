import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/resolver.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:http/http.dart' as http;

class CheckPnSearchDelegate extends SearchDelegate {
  String selType = '';
  final String eId;
  final String checkpnId;
  final KardType kardType;

  CheckPnSearchDelegate({
    required this.eId,
    required this.kardType,
    required this.checkpnId,
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
      eId: eId,
      kardType: kardType,
      checkpnId: checkpnId,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return BuildResultsList(
      query: query,
      eId: eId,
      kardType: kardType,
      checkpnId: checkpnId,
    );
  }
}

class BuildResultsList extends StatefulWidget {
  final String query;
  final String eId;
  final KardType kardType;
  final String checkpnId;
  const BuildResultsList({
    super.key,
    required this.query,
    required this.eId,
    required this.checkpnId,
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
            "${getAttsUrl}/?eventId=${widget.eId}&searchKey=${widget.query}",
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
                  padding: EdgeInsets.symmetric(
                    vertical: psm * 1.3,
                    horizontal: psm,
                  ),
                  itemBuilder: (context, index) {
                    return buildAttendeeCard(atList[index]);
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

  Widget buildAttendeeCard(Attendee attendee) {
    var fullname = attendee.fullName;
    var attrCrdMap = attendee.cards[widget.kardType.name];
    AttributeCard? attributeCard;
    attributeCard =
        attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
    String crdnm =
        attributeCard != null ? attributeCard.name ?? "Not Set" : "Not Set";
    return buildGlassListItem(
      title: fullname,
      subtitle: "CARD TYPE: $crdnm",
      gradient: [lqassgradBaseColor, lqassbdrColor],
      icon: Icons.person,
      onTap: () {
        // Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return AttendeeCheckInView(
                attId: attendee.id ?? "nan",
                eId: widget.eId,
                showAppBar: true,
                onPressed: () async {},
                chckpntId: widget.checkpnId,
              );
            },
          ),
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}
