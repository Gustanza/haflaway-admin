import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/event_tile.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/create_event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';

class MyEvents extends StatefulWidget {
  const MyEvents({super.key});

  @override
  State<MyEvents> createState() => _MyEventsState();
}

class _MyEventsState extends State<MyEvents> {
  // int groupValue = 0;
  String _currentFilter = "My Haflas";
  PageController pcont = PageController();
  final List<String> _filters = ["My Haflas", "Guest Haflas"];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: psm,
        title: const Text("HAFLAWAY HOME"),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGrad),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              navNormal(context: context, widget: const CreateEvent());
            },
            textColor: Colors.white,
            child: const Text("Create"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: psm,
          right: psm,
          top: psm * 0.5,
          bottom: psm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusFilterChips(),
            Expanded(
              child: PageView(
                controller: pcont,
                children: const [PersonalEvents(), GuestEvents()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            _filters.map((filter) {
              bool isSelected = _currentFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor: Colors.grey.shade200,
                  selectedColor:
                      filter == _currentFilter
                          ? primaryColor.shade100
                          : Colors.green.shade100,
                  avatar:
                      filter == _currentFilter
                          ? Icon(Icons.event_available)
                          : Icon(Icons.event_repeat_outlined),
                  onSelected: (selected) {
                    _currentFilter = filter;
                    if (_currentFilter == "My Haflas") {
                      pcont.jumpToPage(0);
                    } else {
                      pcont.jumpToPage(1);
                    }
                    setState(() {});
                  },
                ),
              );
            }).toList(),
      ),
    );
  }
}

class PersonalEvents extends StatefulWidget {
  const PersonalEvents({super.key});

  @override
  State<PersonalEvents> createState() => _PersonalEventsState();
}

class _PersonalEventsState extends State<PersonalEvents> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
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
            return BuildNoDt(string: "No Events");
          } else {
            return ListView.builder(
              itemCount: data.length,
              padding: const EdgeInsets.only(top: psm * 0.5),
              itemBuilder: (context, index) {
                var evlvl = data[index].categoryLevel;
                return GestureDetector(
                  onTap: () {
                    if (evlvl == '0') {
                      navNormal(
                        context: context,
                        widget: AdminPanel(isAdmin: true, edata: data[index]),
                      );
                    }
                  },
                  child: EventTile(eventData: data[index]),
                );
              },
            );
          }
        } else if (snapshot.hasError) {
          return buildErr();
        } else {
          return buildLoader();
        }
      },
    );
  }
}

class GuestEvents extends StatefulWidget {
  const GuestEvents({super.key});

  @override
  State<GuestEvents> createState() => _GuestEventsState();
}

class _GuestEventsState extends State<GuestEvents> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          firestore
              .collection(ecol)
              .where(eusersIds, arrayContains: uid)
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
            return BuildNoDt(string: "No Events");
          } else {
            return ListView.builder(
              itemCount: data.length,
              padding: const EdgeInsets.only(top: psm * 0.5),
              itemBuilder: (context, index) {
                var evlvl = data[index].categoryLevel;
                return GestureDetector(
                  onTap: () {
                    if (evlvl == '0') {
                      navNormal(
                        context: context,
                        widget: AdminPanel(isAdmin: false, edata: data[index]),
                      );
                    }
                  },
                  child: EventTile(eventData: data[index]),
                );
              },
            );
          }
        } else if (snapshot.hasError) {
          return buildErr();
        } else {
          return buildLoader();
        }
      },
    );
  }
}
