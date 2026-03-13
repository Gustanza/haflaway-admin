import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/event_tile.dart';
import 'package:haflaway/components/moving_gradient_border.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/drawer/drawer.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/gus_theme.dart';
import 'package:in_app_update/in_app_update.dart';

class HaflaWayHome extends StatefulWidget {
  const HaflaWayHome({super.key});

  @override
  State<HaflaWayHome> createState() => _HaflaWayHomeState();
}

class _HaflaWayHomeState extends State<HaflaWayHome> {
  int pageSize = evPageSize;
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
    if (!kDebugMode) checkForUpdate();
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
    pageSize = events.isEmpty ? evPageSize : events.length;
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
      extendBodyBehindAppBar: true,
      backgroundColor: GusTheme.obsidian,
      drawer: drawer(context: context),
      appBar: appBar(
        titleWidget: MovingGradientBorder(
          borderRadius: 8,
          borderWidth: 1.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              "Haflaway",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GusTheme.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        leading: appBarActionButton(
          onTap: () {
            if (_scaffoldKey.currentState != null) {
              if (_scaffoldKey.currentState!.isDrawerOpen) {
                _scaffoldKey.currentState!.closeDrawer();
              } else {
                _scaffoldKey.currentState!.openDrawer();
              }
            }
          },
          icon: Icons.menu,
        ),
        actions: Row(
          children: [
            appBarActionButton(
              icon: Icons.refresh,
              onTap: () {
                showToast(isGood: true, msg: "Refreshing feed");
                loadEvents();
              },
            ),
            const SizedBox(width: spaceTiles),
            appBarActionButton(
              icon: Icons.add,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return CreateEvent();
                    },
                  ),
                );
                loadEvents();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── ambient orbs ───────────────────────────────────────────────────
          Positioned(
            top: -150,
            right: -100,
            child: const _GusOrb(size: 400, color: GusTheme.gold),
          ),
          Positioned(
            bottom: 50,
            left: -120,
            child: const _GusOrb(size: 350, color: Color(0xFF4A6CF7)),
          ),

          // ── main content ───────────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () async {
              await loadEvents();
            },
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
                        top: 140,
                        bottom: 100,
                      ),
                      itemBuilder: (context, index) {
                        if (index == events.length && isLoading) {
                          return Padding(
                            padding: const EdgeInsets.all(psm),
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
                          child: Container(
                            margin: const EdgeInsets.only(bottom: spaceTiles),
                            child: MovingGradientBorder(
                              borderRadius: 20,
                              borderWidth: 1.2,
                              child: EventTile(eventData: events[index]),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate()
        .then((info) {
          if (info.updateAvailability == UpdateAvailability.updateAvailable) {
            InAppUpdate.performImmediateUpdate().catchError((e) {
              showToast(isGood: false, msg: "${e}");
              return AppUpdateResult.inAppUpdateFailed;
            });
          }
        })
        .catchError((e) {
          showToast(isGood: false, msg: "${e}");
        });
  }
}

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({required this.size, required this.color, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
