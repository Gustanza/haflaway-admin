import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/components/event_tile.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/providers/package_provider.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:haflaway/top_destinations/app_users/app_users.dart';
import 'package:haflaway/top_destinations/settings/account.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — same palette as admin_pane / attendees
// ─────────────────────────────────────────────────────────────────────────────

abstract class _T {
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl2    = Color(0xFFAEAEB2);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFFFFFFFF),
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

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
  String currentFilter = "Upcoming";
  final List<String> filters = ['Upcoming', 'Ongoing', 'This Week', 'Completed'];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Event> searchResults = [];

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
      if (!isLoading) loadMoreEvents();
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  loadEvents() async {
    pageSize = events.isEmpty ? evPageSize : events.length;
    safeState(() => isLoading = true);
    var prov = context.read<PackageProvider>();
    var nowDt = DateTime.now();
    var now = nowDt.toIso8601String();
    try {
      Query<Map<String, dynamic>> query = firestore.collection(ecol);
      if (!prov.isSuperAdmin) {
        query = query.where("adminsIds", arrayContains: uid);
      }
      if (currentFilter == 'Upcoming') {
        // Events that haven't started yet — soonest first
        query = query
            .where('startDate', isGreaterThan: now)
            .orderBy('startDate', descending: false);
      } else if (currentFilter == 'Completed') {
        // Events fully over — most recently ended first
        query = query
            .where('endDate', isLessThan: now)
            .orderBy('endDate', descending: true);
      } else if (currentFilter == 'Ongoing') {
        // Events happening today: started on or before end-of-today.
        // Client filters out any whose endDate is before start-of-today.
        var todayEnd =
            DateTime(nowDt.year, nowDt.month, nowDt.day, 23, 59, 59)
                .toIso8601String();
        query = query
            .where('startDate', isLessThanOrEqualTo: todayEnd)
            .orderBy('startDate', descending: true);
      } else {
        // This Week: events that START between Monday 00:00 and Sunday 23:59.
        // Both bounds are on the same field so Firestore allows it — no page
        // exhaustion from unbounded past events.
        var monday = nowDt.subtract(Duration(days: nowDt.weekday - 1));
        var sunday = nowDt.add(Duration(days: 7 - nowDt.weekday));
        var startOfWeek =
            DateTime(monday.year, monday.month, monday.day).toIso8601String();
        var endOfWeek =
            DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59)
                .toIso8601String();
        query = query
            .where('startDate', isGreaterThanOrEqualTo: startOfWeek)
            .where('startDate', isLessThanOrEqualTo: endOfWeek)
            .orderBy('startDate', descending: false);
      }
      QuerySnapshot<Map<String, dynamic>> res =
          await query.limit(pageSize).get();
      lastEvent = res.docs.isNotEmpty ? res.docs.last : null;
      events =
          res.docs.map<Event>((e) => Event.fromMap(e.id, e.data())).toList();

      // Client-side refinement ────────────────────────────────────────────────
      if (currentFilter == 'Ongoing') {
        // Keep only events whose endDate falls on or after start-of-today
        var todayStart =
            DateTime(nowDt.year, nowDt.month, nowDt.day).toIso8601String();
        events = events.where((e) {
          final end = e.endDate ?? now;
          return end.compareTo(todayStart) >= 0;
        }).toList();
      }
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
    safeState(() => isLoading = false);
  }

  loadMoreEvents() async {
    safeState(() => isLoading = true);
    var nowDt = DateTime.now();
    var now = nowDt.toIso8601String();
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
      } else if (currentFilter == 'Completed') {
        query = query
            .where('endDate', isLessThan: now)
            .orderBy('endDate', descending: true);
      } else if (currentFilter == 'Ongoing') {
        var todayEnd =
            DateTime(nowDt.year, nowDt.month, nowDt.day, 23, 59, 59)
                .toIso8601String();
        query = query
            .where('startDate', isLessThanOrEqualTo: todayEnd)
            .orderBy('startDate', descending: true);
      } else {
        // This Week: both bounds on startDate — Firestore allows it
        var monday = nowDt.subtract(Duration(days: nowDt.weekday - 1));
        var sunday = nowDt.add(Duration(days: 7 - nowDt.weekday));
        var startOfWeek =
            DateTime(monday.year, monday.month, monday.day).toIso8601String();
        var endOfWeek =
            DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59)
                .toIso8601String();
        query = query
            .where('startDate', isGreaterThanOrEqualTo: startOfWeek)
            .where('startDate', isLessThanOrEqualTo: endOfWeek)
            .orderBy('startDate', descending: false);
      }
      QuerySnapshot<Map<String, dynamic>> res =
          await query.startAfterDocument(lastEvent!).limit(pageSize).get();
      lastEvent = res.docs.isNotEmpty ? res.docs.last : lastEvent;
      var tmpevents =
          res.docs.map<Event>((e) => Event.fromMap(e.id, e.data())).toList();

      // Client-side refinement ────────────────────────────────────────────────
      if (currentFilter == 'Ongoing') {
        var todayStart =
            DateTime(nowDt.year, nowDt.month, nowDt.day).toIso8601String();
        tmpevents = tmpevents.where((e) {
          final end = e.endDate ?? now;
          return end.compareTo(todayStart) >= 0;
        }).toList();
      }

      events.addAll(tmpevents);
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
    safeState(() => isLoading = false);
  }

  safeState(runnable) {
    if (mounted) setState(() => runnable());
  }

  popper() => Navigator.of(context).pop();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeList = isSearching ? searchResults : events;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _T.bg,
      body: Stack(
        children: [
          // Ambient orbs
          const Positioned(
            top: -120,
            right: -80,
            child: _GusOrb(size: 380, color: _T.lime, opacity: 0.10),
          ),
          const Positioned(
            bottom: 60,
            left: -100,
            child: _GusOrb(size: 300, color: _T.lime, opacity: 0.05),
          ),

          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await loadEvents(),
                    color: _T.lime,
                    backgroundColor: _T.card2,
                    child: activeList.isEmpty && isLoading && !isSearching
                        ? buildLoader()
                        : activeList.isEmpty && !isLoading
                            ? BuildNoDt(
                                string: isSearching
                                    ? "No Results Found"
                                    : "No Events Found",
                                isRefreshed: () async {
                                  if (isSearching) {
                                    performSearch(searchController.text);
                                  } else {
                                    await loadEvents();
                                  }
                                },
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                    psm, 16, psm, 120),
                                itemCount: activeList.length +
                                    (isSearching ? 0 : 1),
                                itemBuilder: (context, index) {
                                  if (index == activeList.length) {
                                    return isLoading
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 24),
                                            child: Center(
                                              child: CupertinoActivityIndicator(
                                                  color: _T.lime),
                                            ),
                                          )
                                        : const SizedBox.shrink();
                                  }
                                  if (index >= activeList.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final ev = activeList[index];
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey('ev_${ev.id}'),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                        milliseconds:
                                            300 + (index.clamp(0, 8) * 60)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) =>
                                        Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (ev.categoryLevel == '0') {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => AdminPanel(
                                                  isAdmin: true,
                                                  eventO: ev,
                                                ),
                                              ),
                                            );
                                            loadEvents();
                                          }
                                        },
                                        child: EventTile(
                                          eventData: ev,
                                          onRefresh: loadEvents,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    final prov = context.watch<PackageProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          // Filter dropdown title
          if (!isSearching)
            PopupMenuButton<String>(
              offset: const Offset(0, 44),
              color: _T.card2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _T.sep, width: 0.8),
              ),
              onSelected: (value) {
                safeState(() {
                  currentFilter = value;
                  events = [];
                  loadEvents();
                });
              },
              itemBuilder: (context) => filters.map((choice) {
                final isActive = currentFilter == choice;
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      if (isActive) ...[
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _T.lime,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else
                        const SizedBox(width: 13),
                      Text(
                        choice,
                        style: _T.f(
                          size: 15,
                          weight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive ? _T.lime : _T.lbl1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentFilter,
                    style: _T.f(
                      size: 28,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFFFFFF),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _T.lime,
                    size: 22,
                  ),
                ],
              ),
            ),

          // Search field
          if (isSearching)
            Expanded(
              child: CupertinoSearchTextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: performSearch,
              ),
            ),

          if (!isSearching) const Spacer(),

          // Action buttons
          Row(
            children: [
              if (!isSearching) ...[
                _headerBtn(
                  icon: Icons.search_rounded,
                  onTap: () => safeState(() => isSearching = true),
                ),
                const SizedBox(width: 8),
                _headerBtn(
                  icon: Icons.add_rounded,
                  accent: true,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateEvent()),
                    );
                    loadEvents();
                  },
                ),
                const SizedBox(width: 8),
                // More menu
                PopupMenuButton<int>(
                  offset: const Offset(0, 44),
                  color: _T.card2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _T.sep, width: 0.8),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _T.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _T.sep, width: 0.8),
                    ),
                    child: const Icon(Icons.more_horiz_rounded,
                        color: _T.lbl2, size: 18),
                  ),
                  onSelected: (value) {
                    if (value == 0) {
                      loadEvents();
                      showToast(isGood: true, msg: "Events Refreshed");
                    } else if (value == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const Mipangilio()),
                      );
                    } else if (value == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AppUsersScreen()),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    _menuItem(0, Icons.refresh_rounded, "Refresh"),
                    _menuItem(1, Icons.settings_outlined, "Settings"),
                    if (prov.isSuperAdmin)
                      _menuItem(
                          2, Icons.people_outline_rounded, "Users"),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextButton(
                    onPressed: () => safeState(() {
                      isSearching = false;
                      searchController.clear();
                      searchResults = [];
                    }),
                    child: Text(
                      "Cancel",
                      style: _T.f(
                          size: 14,
                          weight: FontWeight.w600,
                          color: _T.lime),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<int> _menuItem(int value, IconData icon, String label) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: _T.lime, size: 18),
          const SizedBox(width: 12),
          Text(label, style: _T.f(size: 14, color: _T.lbl1)),
        ],
      ),
    );
  }

  Widget _headerBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: accent ? _T.limeDim : _T.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent
                ? _T.lime.withValues(alpha: 0.4)
                : _T.sep,
            width: 0.8,
          ),
        ),
        child: Icon(icon,
            color: accent ? _T.lime : _T.lbl2, size: 18),
      ),
    );
  }

  // ── Misc ───────────────────────────────────────────────────────────────────

  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate()
        .then((info) {
          if (info.updateAvailability == UpdateAvailability.updateAvailable) {
            InAppUpdate.performImmediateUpdate().catchError((e) {
              showToast(isGood: false, msg: "$e");
              return AppUpdateResult.inAppUpdateFailed;
            });
          }
        })
        .catchError((e) => showToast(isGood: false, msg: "$e"));
  }

  performSearch(String query) async {
    if (query.isEmpty) {
      safeState(() => searchResults = []);
      return;
    }
    safeState(() => isLoading = true);
    try {
      var prov = context.read<PackageProvider>();
      Query<Map<String, dynamic>> queryRef = firestore.collection(ecol);
      if (!prov.isSuperAdmin) {
        queryRef = queryRef.where("adminsIds", arrayContains: uid);
      }
      final searchKey = query.toLowerCase();
      queryRef = queryRef
          .where('titleLower', isGreaterThanOrEqualTo: searchKey)
          .where('titleLower', isLessThanOrEqualTo: '$searchKey\uf8ff')
          .limit(20);
      final res = await queryRef.get();
      searchResults =
          res.docs.map<Event>((e) => Event.fromMap(e.id, e.data())).toList();
    } catch (e) {
      debugPrint("search_error: $e");
      showToast(isGood: false, msg: "Search failed: $e");
    }
    safeState(() => isLoading = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient orb
// ─────────────────────────────────────────────────────────────────────────────

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({
    required this.size,
    required this.color,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
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
