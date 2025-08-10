import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
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
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions: buildActionButton(
          icon: Icons.add,
          onTap: () {
            //
          },
        ),
      ),
      body: Ccafold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: p20),
            StreamBuilder(
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
                    child: Column(
                      children: List.generate(docs.length, (index) {
                        return Column(
                          children: [
                            buildGlassCheckpointItem(
                              context,
                              widget.edata,
                              docs[index],
                            ),
                            buildDivider(),
                          ],
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
          ],
        ),
      ),
    );
  }
}
