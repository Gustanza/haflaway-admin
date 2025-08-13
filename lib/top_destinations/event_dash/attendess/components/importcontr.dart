import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

class ImportContributor extends StatefulWidget {
  final String evId;
  const ImportContributor({super.key, required this.evId});

  @override
  State<ImportContributor> createState() => _ImportContributorState();
}

class _ImportContributorState extends State<ImportContributor> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore.collection(ecol).doc(widget.evId).collection(atcol).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var source = (snapshot.data as dynamic).docs;
          if (source.isEmpty) {
            return buildEmptyState(onPressed: () {});
          } else {
            List<Attendee> atList =
                source
                    .where((el) {
                      Attendee att = Attendee.fromMap(el.id, el.data());
                      return (att.cards[KardType.invitation.name] == null &&
                          att.cards[KardType.contribution.name] != null);
                    })
                    .map<Attendee>((e) {
                      return Attendee.fromMap(e.id, e.data());
                    })
                    .toList();
            return buildContrList(atList);
          }
        } else if (snapshot.hasError) {
          return buildErrorView();
        } else {
          return Center(child: CircularProgressIndicator(color: primaryWhite));
        }
      },
    );
  }

  buildContrList(List<Attendee> list) {
    if (list.isEmpty) {
      return buildEmptyState();
    }
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: psm),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "Import from Contributors",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: TextButton(onPressed: () {}, child: Text("Import")),
        ),

        if (list.isEmpty) buildEmptyState(),
        if (list.isNotEmpty)
          ...List.generate(list.length, (index) {
            return cstmLqCheckTile(
              onChanged: (p0) {},
              str: "${list[index].fullName}",
              value: false,
            );
          }),
      ],
    );
  }

  cstmLqCheckTile({
    required bool value,
    required void Function(bool?)? onChanged,
    required String str,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      checkColor: primaryWhite,
      checkboxScaleFactor: 0.8,
      activeColor: lqassgradBaseColor,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(50),
      ),
      value: value,
      onChanged: onChanged,
      title: Text("$str", style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
