import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/event_tile.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/drawer/drawer.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';

class HaflaWayHome extends StatefulWidget {
  const HaflaWayHome({super.key});

  @override
  State<HaflaWayHome> createState() => _HaflaWayHomeState();
}

class _HaflaWayHomeState extends State<HaflaWayHome> {
  int pageSize = 5;
  bool isLoading = false;
  List<Event> events = [];
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController scrollController = ScrollController();
  QueryDocumentSnapshot<Map<String, dynamic>>? lastEvent;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    loadEvents();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 40) {
      if (!isLoading) {
        loadMoreEvents();
      }
    }
  }

  loadEvents() async {
    safeState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> res =
          await firestore
              .collection(ecol)
              .orderBy('startDate', descending: true)
              .limit(pageSize)
              .get();
      lastEvent = res.docs.last;
      events =
          res.docs.map<Event>((e) {
            return Event.fromMap(e.id, e.data());
          }).toList();
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
    safeState(() {
      isLoading = false;
    });
  }

  loadMoreEvents() async {
    safeState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> res =
          await firestore
              .collection(ecol)
              .orderBy('startDate', descending: true)
              .startAfterDocument(lastEvent!)
              .limit(pageSize)
              .get();
      lastEvent = res.docs.last;
      var tmpevents =
          res.docs.map<Event>((e) {
            return Event.fromMap(e.id, e.data());
          }).toList();
      events.addAll(tmpevents);
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
    safeState(() {
      isLoading = false;
    });
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  popper() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaback,
      drawer: drawer(context: context),
      appBar: appBar(
        title: "Haflaway",
        leading: appBarActionButton(
          onTap: () {
            if (_scaffoldKey.currentState != null) {
              if (_scaffoldKey.currentState!.isDrawerOpen) {
                // Drawer is open, so close it
                _scaffoldKey.currentState!.closeDrawer();
              } else {
                // Drawer is closed, so open it
                _scaffoldKey.currentState!.openDrawer();
              }
            }
          },
          icon: Icons.menu,
        ),
        actions: Row(
          children: [
            appBarActionButton(
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
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadEvents();
        },
        child: Ccafold(
          child:
              events.isEmpty && isLoading
                  ? buildLoader()
                  : events.isEmpty && !isLoading
                  ? BuildNoDt(
                    string: "No Events Found",
                    isRefreshed: () async {
                      await loadEvents();
                    },
                  )
                  : ListView.builder(
                    itemCount: events.length + 1,
                    controller: scrollController,
                    padding: const EdgeInsets.only(
                      left: psm,
                      right: psm,
                      top: psm,
                    ),
                    itemBuilder: (context, index) {
                      if (index == events.length && isLoading) {
                        return Padding(
                          padding: EdgeInsetsGeometry.all(psm),
                          child: Center(child: CupertinoActivityIndicator()),
                        );
                      } else if (index == events.length && !isLoading) {
                        return const SizedBox.shrink();
                      }
                      var evlvl = events[index].categoryLevel;

                      return GestureDetector(
                        onTap: () async {
                          if (evlvl == '0') {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return AdminPanel(
                                    isAdmin: true,
                                    eventO: events[index],
                                  );
                                },
                              ),
                            );
                            loadEvents();
                          }
                        },
                        child: EventTile(eventData: events[index]),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
