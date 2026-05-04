import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';

class CheckPoints extends StatefulWidget {
  final Event edata;
  const CheckPoints({super.key, required this.edata});

  @override
  State<CheckPoints> createState() => _CheckPointsState();
}

class _CheckPointsState extends State<CheckPoints> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "CheckPoints",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions: appBarActionButton(
          icon: Icons.add,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.85,
                child: modalBtmSheet(
                  bdrdm: 28,
                  child: ChkpnForm(eId: widget.edata.id ?? ''),
                ),
              ),
            );
          },
        ),
      ),
      body: Ccafold(
        child: StreamBuilder(
          stream:
              firestore
                  .collection(ecol)
                  .doc(widget.edata.id)
                  .collection(echecksub)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<CheckPoint> docs =
                  (snapshot.data as dynamic).docs.map<CheckPoint>((doc) {
                    return CheckPoint.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
                  }).toList();

              if (docs.isEmpty) {
                return buildGlassEmptyState();
              }

              return buildGlassCard(
                child: ListView(
                  padding: EdgeInsets.all(psm),
                  children: List.generate(docs.length, (index) {
                    return buildGlassCheckpointItem(
                      context,
                      widget.edata,
                      docs[index],
                    );
                  }),
                ),
              );
            } else if (snapshot.hasError) {
              return buildGlassErrorView();
            }
            return buildGlassShimmerLoader();
          },
        ),
      ),
    );
  }
}
