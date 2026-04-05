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
  required Event event,
  required KardType kardType,
}) {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  return FutureBuilder(
    future:
        firestore
            .collection(ecol)
            .doc(eventId)
            .collection(atcol)
            .where('cards.${kardType.name}', isNotEqualTo: null)
            .get(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        var source = (snapshot.data as dynamic).docs;
        List<Attendee> attendees =
            source.map<Attendee>((at) {
              return Attendee.fromMap(at.id, at.data());
            }).toList();
        return buildTiles(
          kards: kards,
          attendees: attendees,
          kardType: kardType,
          event: event,
        );
      } else if (snapshot.hasError) {
        return buildErrorView();
      } else {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasData) {
          return buildTiles(
            kards: kards,
            attendees: [],
            kardType: kardType,
            event: event,
          );
        }
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
  required Event event,
}) {
  // 1. Strict client-side filtering for accuracy
  List<Attendee> filteredAttendees =
      attendees.where((at) => at.cards[kardType.name] != null).toList();

  // 2. Filter kards by purpose
  List<Kard> filteredKards =
      kards.where((k) => k.purpose == kardType.name).toList();

  String typeLabel =
      kardType == KardType.contact ? "Contact" : _capitalize(kardType.name);

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
      const SizedBox(height: psm * 0.5),

      // 3. Financial Stats (for Contribution and Contact)
      if (kardType == KardType.contribution || kardType == KardType.contact)
        _buildFinancialStats(event),

      // 4. Card Breakdown (for Contribution and Invitation)
      if (kardType == KardType.contribution || kardType == KardType.invitation)
        ...List.generate(filteredKards.length, (idx) {
          List<Attendee> perCrdList = [];
          try {
            perCrdList =
                filteredAttendees.where((at) {
                  AttributeCard attributeCard = AttributeCard.fromMap(
                    map: at.cards[kardType.name],
                  );
                  return attributeCard.templateCardId == filteredKards[idx].id;
                }).toList();
          } catch (e) {
            debugPrint("Error filtering cards: $e");
          }

          var confirmed =
              perCrdList
                  .where((at) => at.attendanceStatus == "Confirmed")
                  .length;
          var declined =
              perCrdList
                  .where((at) => at.attendanceStatus == "Declined")
                  .length;

          return ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(psm * 0.5),
              decoration: BoxDecoration(
                gradient: lqassgrad,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                "${perCrdList.length}",
                style: const TextStyle(
                  fontSize: fsm,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text("${filteredKards[idx].type}"),
            children: [
              _buildStatTile("Confirmed", confirmed, Colors.green),
              _buildStatTile("Declined", declined, Colors.red),
            ],
          );
        }),

      const SizedBox(height: psm * 0.5),
      lqAssButton(
        label: "Total ${typeLabel}s: ${filteredAttendees.length}",
        onPressed: () {},
      ),
    ],
  );
}

Widget _buildStatTile(String label, int count, Color color) {
  return ListTile(
    title: Text(label),
    trailing: Container(
      padding: const EdgeInsets.all(psm * 0.5),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        "$count",
        style: TextStyle(
          color: color,
          fontSize: fsm,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildFinancialStats(Event event) {
  double totalPledged = event.totalPledge ?? 0;
  double totalPaid = event.totalPayment ?? 0;

  return Column(
    children: [
      _buildFinancialTile("Total Pledged", "Tsh $totalPledged", Colors.white),
      _buildFinancialTile("Total Paid", "Tsh $totalPaid", Colors.green),
      _buildFinancialTile(
        "Remaining",
        "Tsh ${totalPledged - totalPaid}",
        Colors.orange,
      ),
      const Divider(color: Colors.white10),
    ],
  );
}

Widget _buildFinancialTile(String label, String value, Color color) {
  return ListTile(
    title: Text(label),
    trailing: Text(
      value,
      style: TextStyle(fontWeight: FontWeight.bold, color: color),
    ),
  );
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
