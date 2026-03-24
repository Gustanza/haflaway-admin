import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/event_tile.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/providers/package_provider.dart';
import 'package:haflaway/top_destinations/drawer/drawer.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/gus_theme.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';

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
  String currentFilter = "This Week";
  final List<String> filters = ['Upcoming', "Today", 'This Week', 'Past'];

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
    var prov = context.read<PackageProvider>();
    var nowDt = DateTime.now();
    var now = nowDt.toIso8601String();
    var todayStart =
        DateTime(nowDt.year, nowDt.month, nowDt.day).toIso8601String();
    var todayEnd =
        DateTime(
          nowDt.year,
          nowDt.month,
          nowDt.day,
          23,
          59,
          59,
        ).toIso8601String();
    try {
      Query<Map<String, dynamic>> query = firestore.collection(ecol);

      if (!prov.isSuperAdmin) {
        query = query.where("adminsIds", arrayContains: uid);
      }

      if (currentFilter == 'Upcoming') {
        query = query
            .where('startDate', isGreaterThan: now)
            .orderBy('startDate', descending: false);
      } else if (currentFilter == 'Past') {
        query = query
            .where('endDate', isLessThan: now)
            .orderBy('endDate', descending: true);
      } else {
        // Today's or This Week: Any event that overlaps with the target range.
        // We query by startDate <= targetEnd to find potential matches.
        var targetEnd = todayEnd;
        if (currentFilter == 'This Week') {
          var sunday = nowDt.add(Duration(days: 7 - nowDt.weekday));
          targetEnd =
              DateTime(
                sunday.year,
                sunday.month,
                sunday.day,
                23,
                59,
                59,
              ).toIso8601String();
        }

        query = query
            .where('startDate', isLessThanOrEqualTo: targetEnd)
            .orderBy('startDate', descending: true);
      }

      QuerySnapshot<Map<String, dynamic>> res =
          await query.limit(pageSize).get();
      lastEvent = res.docs.isNotEmpty ? res.docs.last : null;
      events =
          res.docs.map<Event>((e) => Event.fromMap(e.id, e.data())).toList();

      if (currentFilter == "Today" || currentFilter == 'This Week') {
        var rangeStart = todayStart;
        var rangeEnd = todayEnd;

        if (currentFilter == 'This Week') {
          var monday = nowDt.subtract(Duration(days: nowDt.weekday - 1));
          var sunday = nowDt.add(Duration(days: 7 - nowDt.weekday));
          rangeStart =
              DateTime(monday.year, monday.month, monday.day).toIso8601String();
          rangeEnd =
              DateTime(
                sunday.year,
                sunday.month,
                sunday.day,
                23,
                59,
                59,
              ).toIso8601String();
        }

        events =
            events.where((e) {
              var start = e.startDate ?? rangeEnd;
              var end = e.endDate ?? rangeEnd;
              return start.compareTo(rangeEnd) <= 0 &&
                  end.compareTo(rangeStart) >= 0;
            }).toList();
      }
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
    var nowDt = DateTime.now();
    var now = nowDt.toIso8601String();
    var todayStart =
        DateTime(nowDt.year, nowDt.month, nowDt.day).toIso8601String();
    var todayEnd =
        DateTime(
          nowDt.year,
          nowDt.month,
          nowDt.day,
          23,
          59,
          59,
        ).toIso8601String();
    try {
      var prov = context.read<PackageProvider>();
      Query<Map<String, dynamic>> query = firestore.collection(ecol);

      if (!prov.isSuperAdmin) {
        query = query.where("adminsIds", arrayContains: uid);
      }

      if (currentFilter == 'Upcoming') {
        query = query
            .where('startDate', isGreaterThan: now)
            .orderBy('startDate', descending: false);
      } else if (currentFilter == 'Past') {
        query = query
            .where('endDate', isLessThan: now)
            .orderBy('endDate', descending: true);
      } else {
        var targetEnd = todayEnd;
        if (currentFilter == 'This Week') {
          var sunday = nowDt.add(Duration(days: 7 - nowDt.weekday));
          targetEnd =
              DateTime(
                sunday.year,
                sunday.month,
                sunday.day,
                23,
                59,
                59,
              ).toIso8601String();
        }
        query = query
            .where('startDate', isLessThanOrEqualTo: targetEnd)
            .orderBy('startDate', descending: true);
      }

      QuerySnapshot<Map<String, dynamic>> res =
          await query.startAfterDocument(lastEvent!).limit(pageSize).get();

      lastEvent = res.docs.isNotEmpty ? res.docs.last : lastEvent;
      var tmpevents =
          res.docs.map<Event>((e) => Event.fromMap(e.id, e.data())).toList();

      if (currentFilter == "Today" || currentFilter == 'This Week') {
        var rangeStart = todayStart;
        var rangeEnd = todayEnd;

        if (currentFilter == 'This Week') {
          var monday = nowDt.subtract(Duration(days: nowDt.weekday - 1));
          var sunday = nowDt.add(Duration(days: 7 - nowDt.weekday));
          rangeStart =
              DateTime(monday.year, monday.month, monday.day).toIso8601String();
          rangeEnd =
              DateTime(
                sunday.year,
                sunday.month,
                sunday.day,
                23,
                59,
                59,
              ).toIso8601String();
        }
        tmpevents =
            tmpevents.where((e) {
              var start = e.startDate ?? rangeEnd;
              var end = e.endDate ?? rangeEnd;
              return start.compareTo(rangeEnd) <= 0 &&
                  end.compareTo(rangeStart) >= 0;
            }).toList();
      }

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
        titleWidget: PopupMenuButton<String>(
          offset: const Offset(0, 40),
          color: const Color(0xFF141414), // _T.card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (String value) {
            safeState(() {
              currentFilter = value;
              events = [];
              loadEvents();
            });
          },
          itemBuilder: (BuildContext context) {
            return filters.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(
                  choice,
                  style: GoogleFonts.inter(
                    color:
                        currentFilter == choice
                            ? const Color(0xFFC9A84C)
                            : Colors.white,
                    fontWeight:
                        currentFilter == choice
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              );
            }).toList();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentFilter,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFC9A84C), // _T.lime
                size: 24,
              ),
            ],
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
            const SizedBox(width: spaceTiles),
            // Profile icon mimicking admin_pane / user screenshot
            appBarActionButton(
              icon: Icons.refresh,
              onTap: () async {
                await loadEvents();
                showToast(isGood: true, msg: "Events Refreshed");
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
                            child: EventTile(eventData: events[index]),
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
