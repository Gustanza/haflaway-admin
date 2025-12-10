import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/gen_constants.dart';
import 'package:haflaway/utils/dimensions.dart';

class InvitesIssuers extends StatefulWidget {
  final String eventId;
  const InvitesIssuers({super.key, required this.eventId});

  @override
  State<InvitesIssuers> createState() => _InvitesIssuersState();
}

class _InvitesIssuersState extends State<InvitesIssuers> {
  String selChannel = '';
  String selStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(
        title: "Tuma Mialiko",
        leading: buildActionButton(icon: Icons.arrow_back, onTap: () {}),
        actions: Row(
          children: [IconButton(onPressed: () {}, icon: Icon(Icons.search))],
        ),
      ),
      body: FutureBuilder(
        future:
            FirebaseFirestore.instance
                .collection(ecol)
                .doc(widget.eventId)
                .collection(atcol)
                .where(
                  "messageIndexes",
                  arrayContains: {'channel': 'whatsapp', 'status': 'read'},
                )
                .get(),
        builder: (context, snapshot) {
          return Center(child: Text("${snapshot.data?.docs.length}"));
        },
      ),
      // body: ListView(
      //   padding: EdgeInsets.all(spaceTiles),
      //   children: [
      //     Row(
      //       children: [
      //         buildDropDwn(shannnels, (value) {
      //           safeState(() {
      //             selChannel = value;
      //           });
      //         }),
      //         const SizedBox(width: spaceTiles),
      //         buildDropDwn(shtates, (value) {
      //           safeState(() {
      //             selStatus = value;
      //           });
      //         }),
      //       ],
      //     ),
      //     ListTile(
      //       title: Text("Chaguzi: 4 kati ya 30"),
      //       trailing: TextButton(onPressed: () {}, child: Text("Chagua Zote")),
      //     ),
      //   ],
      // ),
    );
  }

  buildDropDwn(Map shanns, Function(dynamic) onSelected) {
    return Expanded(
      child: DropdownMenu(
        width: double.maxFinite,
        showTrailingIcon: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(bsm)),
        ),
        initialSelection: shanns.entries.first.key,
        onSelected: onSelected,
        dropdownMenuEntries:
            shanns.entries.map<DropdownMenuEntry>((e) {
              return DropdownMenuEntry(value: e.key, label: e.value);
            }).toList(),
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
}
