import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/event_tile.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/create_event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';

class HaflaWayHome extends StatefulWidget {
  const HaflaWayHome({super.key});

  @override
  State<HaflaWayHome> createState() => _HaflaWayHomeState();
}

class _HaflaWayHomeState extends State<HaflaWayHome> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Haflaway",
        actions: buildActionButton(
          icon: Icons.add,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return CreateEvent();
                },
              ),
            );
          },
        ),
      ),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(gradient: scagrad),
        child: StreamBuilder(
          stream:
              firestore
                  .collection(ecol)
                  .where(eadminsIds, arrayContains: uid)
                  .where('status', isEqualTo: 'Published')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Event> data =
                  (snapshot.data as dynamic).docs.map<Event>((doc) {
                    return Event.fromMap(doc.id, doc.data());
                  }).toList();

              if (data.isEmpty) {
                return buildEmptyState();
              } else {
                return ListView.builder(
                  itemCount: data.length,
                  padding: const EdgeInsets.all(p20),
                  itemBuilder: (context, index) {
                    var evlvl = data[index].categoryLevel;
                    return GestureDetector(
                      onTap: () {
                        if (evlvl == '0') {
                          navNormal(
                            context: context,
                            widget: AdminPanel(
                              isAdmin: true,
                              edata: data[index],
                            ),
                          );
                        }
                      },
                      child: EventTile(eventData: data[index]),
                    );
                  },
                );
              }
            } else if (snapshot.hasError) {
              return buildEmptyState();
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
