import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';

quickStats({
  required List<Kard> kards,
  required String eventId,
  required KardType kardType,
}) {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  return FutureBuilder(
    future:
        firestore
            .collection(ecol)
            .doc(eventId)
            .collection(atcol)
            .where('cards.invitation', isNotEqualTo: null)
            .get(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        var source = (snapshot.data as dynamic).docs;
        if (source.isEmpty) {
          return buildEmptyState();
        }
        List<Attendee> attendees =
            source.map<Attendee>((at) {
              return Attendee.fromMap(at.id, at.data());
            }).toList();
        return buildTiles(
          kards: kards,
          attendees: attendees,
          kardType: kardType,
        );
      } else if (snapshot.hasError) {
        return buildErrorState();
      } else {
        return ListTile(
          title: Text("Loading..."),
          trailing: CupertinoActivityIndicator(),
        );
      }
    },
  );
}

buildTiles({
  required List<Kard> kards,
  required KardType kardType,
  required List<Attendee> attendees,
}) {
  return ListView(
    shrinkWrap: true,
    padding: EdgeInsets.only(
      top: psm * 1.7,
      left: psm,
      right: psm,
      bottom: psm * 1.7,
    ),
    children: [
      Text(
        "Quick Overview",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fsm + 4, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: psm * 0.5),
      ...List.generate(kards.length, (idx) {
        List<Attendee> perCrdList = [];
        try {
          perCrdList =
              attendees.where((at) {
                AttributeCard attributeCard = AttributeCard.fromMap(
                  map: at.cards[kardType.name],
                );
                return attributeCard.templateCardId == kards[idx].id;
              }).toList();
        } catch (e) {
          // Will handle some
        }
        var confirmedlist =
            perCrdList.where((at) {
              return at.attendanceStatus == "Confirmed";
            }).length;
        var declinedlist =
            perCrdList.where((at) {
              return at.attendanceStatus == "Declined";
            }).length;
        return ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(psm * 0.5),
            decoration: BoxDecoration(
              gradient: lqassgrad,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              "${perCrdList.length}",
              style: TextStyle(fontSize: fsm, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text("${kards[idx].type}"),
          children: [
            ListTile(
              title: Text("Confirmed"),
              trailing: Container(
                padding: EdgeInsets.all(psm * 0.5),
                decoration: BoxDecoration(
                  gradient: lqassgrad,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  "$confirmedlist",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: fsm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text("Declined"),
              trailing: Container(
                padding: EdgeInsets.all(psm * 0.5),
                decoration: BoxDecoration(
                  gradient: lqassgrad,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  "$declinedlist",
                  style: TextStyle(
                    fontSize: fsm,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
      SizedBox(height: psm * 0.5),
      lqAssButton(label: "Total Count: ${attendees.length}", onPressed: () {}),
    ],
  );
}
