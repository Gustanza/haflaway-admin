import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/wsap.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/sms/custom_camps/ccampsmain.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/attendee_card.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/importcontr.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/stats.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/crtattendees.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/label_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/errorstrs.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';
import 'imp_preview.dart';

class Attendees extends StatefulWidget {
  final Event edata;
  final KardType kardType;
  final String title;
  const Attendees({
    super.key,
    required this.edata,
    required this.kardType,
    this.title = "Manage Invitations",
  });
  @override
  State<Attendees> createState() => _AttendeesState();
}

class _AttendeesState extends State<Attendees> with TickerProviderStateMixin {
  List<List<dynamic>>? importRows;
  List<Kard> lcrds = [];
  String? _selectedKardFilter;
  List<Attendee> atList = [];
  List<Attendee> filteredList = [];
  List<Attendee> selectList = [];
  TextEditingController impname = TextEditingController();
  TextEditingController impphone = TextEditingController();
  TextEditingController impcard = TextEditingController();
  TextEditingController impahadi = TextEditingController();
  TextEditingController impmchango = TextEditingController();
  bool _mapAhadi = true;
  bool _mapMchango = true;
  FirebaseStorage storage = FirebaseStorage.instance;
  TextEditingController scont = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  // Attendance status filters
  String _attendanceFilter = "All";
  final List<String> _filters = atStatesList;
  // Pagination variables
  int pageSize = atsPageSize;
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  ScrollController scrollController = ScrollController();

  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Attendee> searchResults = [];

  String? _labelFilterId; // Added for label filtering
  List<String> importSelectedLabels =
      []; // Added for import dialog list selection

  @override
  void initState() {
    super.initState();
    getCards();
    // Add scroll listener for pagination
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  // Scroll listener to detect when user reaches bottom
  void _scrollListener() {
    // Debug the scroll position
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMore) {
        _loadMoreAttendees();
      }
    }
  }

  // Load first batch of attendees
  Future<void> _loadAttendees() async {
    if (isLoading) return;
    atList = [];
    lastDocument = null;
    setState(() {
      isLoading = true;
      hasMore = true;
      pageSize = atsPageSize;
    });
    try {
      // Keep fetching pages until we find records of the correct kardType
      // (avoids showing empty when contacts are buried past the first page)
      const maxPages = 50;
      int pages = 0;
      while (atList.isEmpty && hasMore && pages < maxPages) {
        Query<Map<String, dynamic>> query =
            lastDocument == null ? nQwrBuilder() : mQwrBuilder();
        var snapshot = await query.get();
        pages++;

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          if (_selectedKardFilter != null ||
              _attendanceFilter != "All" ||
              _labelFilterId != null) {
            showToast(isGood: true, msg: "No guests found matching filters");
          }
          break;
        }

        lastDocument = snapshot.docs.last;
        if (snapshot.docs.length < pageSize) hasMore = false;

        atList =
            snapshot.docs
                .where((test) {
                  try {
                    var krd = test['cards'][widget.kardType.name];
                    return krd != null;
                  } catch (e) {
                    return false;
                  }
                })
                .map<Attendee>((doc) => Attendee.fromMap(doc.id, doc.data()))
                .toList();
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("_loadAttendees error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  nQwrBuilder() {
    Query q = firestore.collection(ecol).doc(widget.edata.id).collection(atcol);

    if (_selectedKardFilter != null) {
      q = q.where(
        "cards.${widget.kardType.name}.templateCardId",
        isEqualTo: _selectedKardFilter,
      );
    }

    if (_attendanceFilter != "All") {
      q = q.where("attendanceStatus", isEqualTo: _attendanceFilter);
    }

    if (_labelFilterId != null) {
      q = q.where("labelIds", arrayContains: _labelFilterId);
    }

    if (_selectedKardFilter != null) {
      q = q.orderBy("cards.${widget.kardType.name}.templateCardId");
    }
    if (_attendanceFilter != "All") {
      q = q.orderBy("attendanceStatus");
    }
    if (_selectedKardFilter == null && _attendanceFilter == "All") {
      q = q.orderBy("createdAt", descending: true);
    }

    return q.limit(pageSize);
  }

  mQwrBuilder() {
    Query q = firestore.collection(ecol).doc(widget.edata.id).collection(atcol);

    if (_selectedKardFilter != null) {
      q = q.where(
        "cards.${widget.kardType.name}.templateCardId",
        isEqualTo: _selectedKardFilter,
      );
    }

    if (_attendanceFilter != "All") {
      q = q.where("attendanceStatus", isEqualTo: _attendanceFilter);
    }

    if (_labelFilterId != null) {
      q = q.where("labelIds", arrayContains: _labelFilterId);
    }

    if (_selectedKardFilter != null) {
      q = q.orderBy("cards.${widget.kardType.name}.templateCardId");
    }
    if (_attendanceFilter != "All") {
      q = q.orderBy("attendanceStatus");
    }
    if (_selectedKardFilter == null && _attendanceFilter == "All") {
      q = q.orderBy("createdAt", descending: true);
    }

    return q.startAfterDocument(lastDocument!).limit(pageSize);
  }

  // Load more attendees when scrolling to bottom
  Future<void> _loadMoreAttendees() async {
    if (isLoading || !hasMore || lastDocument == null) return;

    setState(() {
      isLoading = true;
    });
    pageSize = atsPageSize;
    try {
      Query<Map<String, dynamic>> query = mQwrBuilder();

      var snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          hasMore = false;
          isLoading = false;
        });
        return;
      }

      lastDocument = snapshot.docs.last;
      final newAttendees =
          snapshot.docs
              .where((test) {
                try {
                  var krd = test['cards'][widget.kardType.name];
                  if (krd == null) {
                    return false;
                  } else {
                    return true;
                  }
                } catch (e) {
                  return false;
                }
              })
              .map<Attendee>((doc) {
                return Attendee.fromMap(doc.id, doc.data());
              })
              .toList();
      setState(() {
        atList.addAll(newAttendees);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final uri = Uri.parse(
        "$getAttsUrl/?eventId=${widget.edata.id}&searchKey=${Uri.encodeComponent(query)}&kardType=${widget.kardType.name}",
      );
      final response = await http.get(uri);
      final body = jsonDecode(response.body);
      if (body['status'] == true) {
        final List data = body['data'];
        setState(() {
          searchResults =
              data
                  .map((e) {
                    final item = Map<String, dynamic>.from(e['item']);
                    return Attendee.fromMap(item['id'] ?? '', item);
                  })
                  .where((at) {
                    try {
                      return at.cards[widget.kardType.name] != null;
                    } catch (_) {
                      return false;
                    }
                  })
                  .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("search_error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAttendees();
  }

  getMainBuild() {
    return GestureDetector(
      onTap: _showMainSheet,
      child: const Icon(Icons.more_horiz_rounded, color: _T.lime, size: 22),
    );
  }

  void _showMainSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => modalBtmSheet(
            bdrdm: 28,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: _T.card3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: _T.lime.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: _T.lime,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Event Tools",
                              style: _T.f(
                                size: 18,
                                weight: FontWeight.w800,
                                color: _T.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              "Analytics & communications",
                              style: _T.f(size: 12, color: _T.lbl3),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Analytics ──
                    _sheetSectionLabel("Analytics"),
                    const SizedBox(height: 10),
                    _sheetTile(
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF5E5CE6),
                      title: "Summary",
                      subtitle: "Attendance stats and full breakdown",
                      onTap: () {
                        Navigator.pop(ctx);
                        showQuickStats();
                      },
                    ),
                    const SizedBox(height: 10),
                    _sheetTile(
                      icon: Icons.label_rounded,
                      color: _T.lime,
                      title: "Manage Labels",
                      subtitle: "Create and organise guest labels",
                      onTap: () {
                        Navigator.pop(ctx);
                        showLabelManager(context, widget.edata);
                      },
                    ),

                    // ── Communications ──
                    const SizedBox(height: 22),
                    _sheetSectionLabel("Communications"),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        if (widget.kardType == KardType.invitation ||
                            widget.kardType == KardType.contribution) ...[
                          _sheetTile(
                            icon: Icons.mark_email_unread_rounded,
                            color: const Color(0xFF5AC8FA),
                            title: "Send Card(s)",
                            subtitle:
                                widget.kardType == KardType.invitation
                                    ? "Dispatch digital invitation cards"
                                    : "Send contribution cards to guests",
                            onTap: () async {
                              Navigator.pop(ctx);
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => InvitesIssuers(
                                        event: widget.edata,
                                        kardType: widget.kardType,
                                        campaignId:
                                            widget.kardType ==
                                                    KardType.invitation
                                                ? invCampId
                                                : contrCampId,
                                      ),
                                ),
                              );
                              _loadAttendees();
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (widget.kardType == KardType.invitation) ...[
                          _sheetTile(
                            icon: Icons.notifications_active_rounded,
                            color: const Color(0xFFFF9F0A),
                            title: "Send Reminder(s)",
                            subtitle: "Nudge guests who haven't responded",
                            onTap: () async {
                              Navigator.pop(ctx);
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => InvitesIssuers(
                                        event: widget.edata,
                                        kardType: widget.kardType,
                                        campaignId: invRemCampId,
                                      ),
                                ),
                              );
                              _loadAttendees();
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        _sheetTile(
                          icon: Icons.sms_rounded,
                          color: const Color(0xFF30D158),
                          title: "Send Bulk SMS",
                          subtitle: "Text message all or filtered guests",
                          onTap: () async {
                            Navigator.pop(ctx);
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => AdminCampaigns(
                                      event: widget.edata,
                                      title: "Send Bulk SMS",
                                      kardType: widget.kardType,
                                    ),
                              ),
                            );
                            _loadAttendees();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  getMiniBuild() {
    return GestureDetector(
      onTap: _showMiniSheet,
      child: const Icon(Icons.group_add_rounded, color: _T.lime, size: 22),
    );
  }

  void _showMiniSheet() {
    final entityLabel =
        widget.kardType == KardType.invitation
            ? "Invitee"
            : widget.kardType == KardType.contribution
            ? "Contributor"
            : "Contact";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => modalBtmSheet(
            bdrdm: 28,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: _T.card3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: _T.lime.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.group_add_rounded,
                            color: _T.lime,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add $entityLabel",
                              style: _T.f(
                                size: 18,
                                weight: FontWeight.w800,
                                color: _T.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              "Choose how to add guests",
                              style: _T.f(size: 12, color: _T.lbl3),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _sheetTile(
                      icon: Icons.person_add_alt_1_rounded,
                      color: _T.lime,
                      title: "Add Manually",
                      subtitle: "Enter guest details one by one",
                      onTap: () async {
                        Navigator.pop(ctx);
                        final title =
                            widget.kardType == KardType.invitation
                                ? "Invitation"
                                : widget.kardType == KardType.contribution
                                ? "Contributor"
                                : "Contact";
                        await navNormal(
                          context: context,
                          widget: CreateAttendees(
                            event: widget.edata,
                            title: title,
                            kardType: widget.kardType,
                          ),
                        );
                        _loadAttendees();
                      },
                    ),
                    const SizedBox(height: 10),
                    _sheetTile(
                      icon: Icons.upload_file_rounded,
                      color: const Color(0xFF5AC8FA),
                      title: "Upload Spreadsheet",
                      subtitle: "Import guests from an Excel file",
                      onTap: () {
                        Navigator.pop(ctx);
                        importFile();
                      },
                    ),
                    if (widget.kardType == KardType.invitation) ...[
                      const SizedBox(height: 10),
                      _sheetTile(
                        icon: Icons.monetization_on_rounded,
                        color: const Color(0xFFFF9F0A),
                        title: "Import from Contributors",
                        subtitle: "Pull in existing contributors as guests",
                        onTap: () {
                          Navigator.pop(ctx);
                          showSelectCard(isContactImport: false);
                        },
                      ),
                      const SizedBox(height: 10),
                      _sheetTile(
                        icon: Icons.contacts_rounded,
                        color: const Color(0xFF30D158),
                        title: "Import from Contacts",
                        subtitle: "Bring in saved contacts as guests",
                        onTap: () {
                          Navigator.pop(ctx);
                          showSelectCard(isContactImport: true);
                        },
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // ── Shared sheet helpers ─────────────────────────────────────────────────

  Widget _sheetTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.f(
                      size: 14,
                      weight: FontWeight.w700,
                      color: _T.lbl1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.f(size: 12, color: _T.lbl3, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _T.lbl4,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: _T.f(
        size: 10,
        weight: FontWeight.w800,
        color: _T.lbl4,
        letterSpacing: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool inSelectMode = selectList.isNotEmpty;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        floatingActionButton: _buildFloatingActions(),
        body: Stack(
          children: [
            // Ambient Orbs
            const Positioned(
              top: -80,
              right: -80,
              child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
            ),
            const Positioned(
              bottom: -40,
              left: -80,
              child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
            ),

            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(inSelectMode),
                      if (!isSearching) _titleBlock(),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
              onRefresh: () async {
                await _loadAttendees();
              },
              color: _T.lime,
              backgroundColor: _T.card2,
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // ── Pending Notice ──
                  if (!isSearching &&
                      atList.any((at) => at.isCardPending(widget.kardType)))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _PendingBanner(onRefresh: _loadAttendees),
                      ),
                    ),

                  // ── Hero Card for Contributions ──
                  if (widget.kardType == KardType.contribution &&
                      atList.isNotEmpty &&
                      !isSearching)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Builder(
                          builder: (context) {
                            final double pct =
                                widget.edata.totalPledge! > 0
                                    ? widget.edata.totalPayment! /
                                        widget.edata.totalPledge!
                                    : 0.0;
                            return _HeroCard(
                              totalPledged: widget.edata.totalPledge!,
                              totalPaid: widget.edata.totalPayment!,
                              pct: pct,
                              progressAnim: AlwaysStoppedAnimation(pct),
                            );
                          },
                        ),
                      ),
                    ),

                  // ── Content ──
                  if ((isSearching ? searchResults : atList).isEmpty &&
                      isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(color: _T.lime),
                      ),
                    )
                  else if ((isSearching ? searchResults : atList).isEmpty &&
                      !isLoading)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child:
                            isSearching
                                ? searchController.text.isEmpty
                                    ? const GusSearchEmpty.prompt()
                                    : GusSearchEmpty.noResults(
                                      query: searchController.text,
                                    )
                                : BuildNoDt(
                                  string: "no data",
                                  isRefreshed: () async =>
                                      await _loadAttendees(),
                                ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            var activeList =
                                isSearching ? searchResults : atList;

                            // Pagination loader or end-of-list indicator
                            if (index == activeList.length) {
                              return isSearching
                                  ? const SizedBox(height: 100)
                                  : _buildListFooter();
                            }

                            final attendee = activeList[index];
                            final hasKey = selectList.any(
                              (t) => t.id == attendee.id,
                            );
                            final campaignId =
                                widget.kardType == KardType.invitation
                                    ? invCampId
                                    : contrCampId; 

                            return TweenAnimationBuilder<double>(
                              key: ValueKey('anim_${attendee.id}'),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 350 + (index.clamp(0, 10) * 50),
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 16 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: buildAttendeeCard(
                                hasKey: hasKey,
                                attendee: attendee,
                                kardType: widget.kardType,
                                eventId: widget.edata.id ?? "_",
                                campaignId: campaignId,
                                showMessageStatus:
                                    widget.kardType != KardType.contact,
                                allLabels: widget.edata.labels ?? [],
                                onEdit: () async {
                                  String entityTitle =
                                      widget.kardType == KardType.invitation
                                          ? "Invitation"
                                          : widget.kardType ==
                                              KardType.contribution
                                          ? "Contributor"
                                          : "Contact";
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CreateAttendees(
                                            event: widget.edata,
                                            title: entityTitle,
                                            kardType: widget.kardType,
                                            attendee: attendee,
                                          ),
                                    ),
                                  );
                                  _loadAttendees();
                                },
                                onSelected: () {
                                  if (hasKey) {
                                    selectList.removeWhere(
                                      (t) => t.id == attendee.id,
                                    );
                                  } else {
                                    selectList.add(attendee);
                                  }
                                  safeState(() {});
                                },
                                onStatusChange: (status) {
                                  if (widget.kardType ==
                                      KardType.contribution) {
                                    return _loadAttendees();
                                  }
                                  int idx = activeList.indexWhere(
                                    (element) => element.id == attendee.id,
                                  );
                                  if (idx != -1) {
                                    activeList[idx].attendanceStatus = status;
                                  }
                                  safeState(() {});
                                },
                              ),
                            );
                          },
                          childCount:
                              (isSearching ? searchResults : atList).length + 1,
                        ),
                      ),
                    ),

                  // ── Bottom Padding ──
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 100,
                    ),
                  ),
                ],
              ),
            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool inSelectMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          if (!isSearching)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _T.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _T.sep, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _T.lime,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Back',
                      style: _T.f(
                        size: 13,
                        weight: FontWeight.w500,
                        color: _T.lbl1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isSearching)
            Expanded(
              child: CupertinoSearchTextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) {
                  performSearch(v);
                },
              ),
            ),
          if (!isSearching) const Spacer(),
          if (inSelectMode)
            _glassActionChip(
              icon: Icons.delete,
              label: "Delete",
              color: Colors.redAccent,
              onTap: delSelect,
            )
          else
            Row(
              children: [
                if (!isSearching) ...[
                  if (widget.kardType != KardType.contact) ...[
                    _buildFilterButton(),
                    const SizedBox(width: 8),
                  ],
                  _floatingButton(
                    icon: Icons.search,
                    onTap: () {
                      setState(() {
                        isSearching = true;
                      });
                    },
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isSearching = false;
                          searchController.clear();
                          searchResults = [];
                        });
                      },
                      child: Text(
                        "Cancel",
                        style: _T.f(
                          size: 14,
                          weight: FontWeight.w600,
                          color: _T.lime,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.8,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 6),
          _buildListHeader(atList.length),
        ],
      ),
    );
  }

  Widget _buildListFooter() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CupertinoActivityIndicator(color: _T.lime)),
      );
    } else if (!hasMore && atList.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _T.card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: Text(
              "End of list",
              style: _T.f(size: 13, color: _T.lbl4, height: 1.0),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 20);
  }

  // Build elegant filter button for app bar
  Widget _buildFilterButton() {
    int activeFiltersCount = 0;
    if (_selectedKardFilter != null) activeFiltersCount++;
    if (_attendanceFilter != "All") activeFiltersCount++;
    if (_labelFilterId != null) activeFiltersCount++;

    final bool hasFilters = activeFiltersCount > 0;

    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasFilters ? _T.limeDim : _T.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFilters ? _T.lime.withValues(alpha: 0.4) : _T.sep,
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: hasFilters ? _T.lime : _T.lbl2,
              size: 20,
            ),
          ),
          if (hasFilters)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _T.lime,
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.bg, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    "$activeFiltersCount",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Show elegant filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => modalBtmSheet(
            bdrdm: bmd,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _T.card3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _T.lime.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: _T.lime,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Filter Guests",
                          style: _T.f(
                            size: 18,
                            weight: FontWeight.w700,
                            color: _T.lbl1,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedKardFilter != null ||
                            _attendanceFilter != "All" ||
                            _labelFilterId != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedKardFilter = null;
                                _attendanceFilter = "All";
                                _labelFilterId = null;
                              });
                              Navigator.pop(context);
                              _loadAttendees();
                            },
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 15,
                              color: Colors.redAccent,
                            ),
                            label: Text(
                              "Clear",
                              style: _T.f(
                                size: 13,
                                color: Colors.redAccent,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: _T.lbl3,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 0.5, color: _T.sep),
                  // Filter sections
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(psm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Type Filter Section
                          if (lcrds.isNotEmpty) ...[
                            _buildFilterSection(
                              title: "Card Type",
                              icon: Icons.credit_card,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  // All Cards option
                                  _buildFilterChip(
                                    label: "All Cards",
                                    isSelected: _selectedKardFilter == null,
                                    onTap: () {
                                      setState(() {
                                        _selectedKardFilter = null;
                                      });
                                      Navigator.pop(context);
                                      _loadAttendees();
                                    },
                                  ),
                                  // Individual card options
                                  ...lcrds.map(
                                    (kard) => _buildFilterChip(
                                      label: kard.type,
                                      isSelected:
                                          _selectedKardFilter == kard.id,
                                      onTap: () {
                                        setState(() {
                                          _selectedKardFilter =
                                              _selectedKardFilter == kard.id
                                                  ? null
                                                  : kard.id;
                                        });
                                        Navigator.pop(context);
                                        _loadAttendees();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Attendance Status Filter Section
                          _buildFilterSection(
                            title: "Attendance Status",
                            icon: Icons.person,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _filters
                                      .map(
                                        (filter) => _buildFilterChip(
                                          label: filter,
                                          isSelected:
                                              _attendanceFilter == filter,
                                          onTap: () {
                                            setState(() {
                                              _attendanceFilter = filter;
                                            });
                                            Navigator.pop(context);
                                            _loadAttendees();
                                          },
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),

                          // Labels Filter Section
                          if (widget.edata.labels != null &&
                              widget.edata.labels!.isNotEmpty) ...[
                            _buildFilterSection(
                              title: "Labels",
                              icon: Icons.label_outline_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildFilterChip(
                                    label: "All Labels",
                                    isSelected: _labelFilterId == null,
                                    onTap: () {
                                      setState(() {
                                        _labelFilterId = null;
                                      });
                                      Navigator.pop(context);
                                      _loadAttendees();
                                    },
                                  ),
                                  ...widget.edata.labels!.map(
                                    (label) => _buildFilterChip(
                                      label: label.name,
                                      color: Color(label.colorValue),
                                      isSelected: _labelFilterId == label.id,
                                      onTap: () {
                                        setState(() {
                                          _labelFilterId =
                                              _labelFilterId == label.id
                                                  ? null
                                                  : label.id;
                                        });
                                        Navigator.pop(context);
                                        _loadAttendees();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + psm * 0.25,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Build filter section header
  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _T.lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: _T.lime),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: _T.f(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _T.lbl2,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final accentColor = color ?? _T.lime;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.14) : _T.card2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor.withValues(alpha: 0.7) : _T.sep,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: _T.f(
                size: 12,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _T.white : _T.lbl2,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 13, color: accentColor),
            ],
          ],
        ),
      ),
    );
  }

  // ── New UI helper methods ──────────────────────────────────

  Widget _floatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Icon(icon, color: _T.lbl2, size: 18),
      ),
    );
  }

  Widget _glassActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: _T.f(size: 13, weight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFrostedFAB(child: getMiniBuild(), isMini: true),
        if (selectList.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFrostedFAB(
            child: IconButton(
              icon: const Icon(Icons.label_outline_rounded, color: _T.lime),
              onPressed: showBulkLabeling,
            ),
            isMini: true,
          ),
        ],
        const SizedBox(height: 12),
        _buildFrostedFAB(child: getMainBuild(), isMini: false),
      ],
    );
  }

  Widget _buildFrostedFAB({required Widget child, bool isMini = false}) {
    final double size = isMini ? 48.0 : 56.0;
    final double radius = size / 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _T.card2,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _T.sep, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildListHeader(int count) {
    final bool hasActiveFilters =
        _selectedKardFilter != null ||
        _attendanceFilter != "All" ||
        _labelFilterId != null;
    final String entity =
        widget.kardType == KardType.invitation
            ? 'Invitees'
            : widget.kardType == KardType.contribution
            ? 'Contributors'
            : 'Contacts';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            "$count $entity",
            style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl3),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _T.lime.withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: Text(
                "Filtered",
                style: _T.f(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _T.lime,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  selectAll() {
    if (atList.isNotEmpty) {
      if (selectList.length != atList.length) {
        selectList.addAll(atList);
      } else {
        selectList = [];
      }
      setState(() {});
    }
  }

  getCards() async {
    try {
      var res =
          await firestore
              .collection(ecol)
              .doc(widget.edata.id)
              .collection(cardcol)
              .where("purpose", isEqualTo: widget.kardType.name)
              .get();
      lcrds =
          res.docs.map<Kard>((doc) {
            return Kard.fromMap(doc.id, doc.data());
          }).toList();
    } catch (e) {
      debugPrint("Error loading cards: $e");
    }
    safeState(() {});
  }

  showBulkLabeling() {
    if (widget.edata.labels == null || widget.edata.labels!.isEmpty) {
      showToast(
        isGood: false,
        msg: "No lists created yet. Create one from the menu.",
      );
      return;
    }

    // Determine initial states for each label
    Map<String, bool?> labelStates = {};
    for (var label in widget.edata.labels!) {
      bool allHave = true;
      bool noneHave = true;
      for (var attendee in selectList) {
        bool hasLabel = attendee.labelIds?.contains(label.id) ?? false;
        if (hasLabel) {
          noneHave = false;
        } else {
          allHave = false;
        }
      }
      if (allHave) {
        labelStates[label.id] = true;
      } else if (noneHave) {
        labelStates[label.id] = false;
      } else {
        labelStates[label.id] = null; // Mixed state
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return modalBtmSheet(
              bdrdm: 28,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Guest Labels",
                          style: _T.f(size: 20, weight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: _T.lbl3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Manage lists for ${selectList.length} selected guest(s):",
                      style: _T.f(color: _T.grey2),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.edata.labels!.length,
                        itemBuilder: (context, index) {
                          final label = widget.edata.labels![index];
                          final state = labelStates[label.id];
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: state,
                            tristate: true,
                            title: Text(label.name, style: _T.f()),
                            secondary: CircleAvatar(
                              backgroundColor: Color(label.colorValue),
                              radius: 6,
                            ),
                            activeColor: _T.lime,
                            checkboxShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                // Toggle logic: false or null -> true; true -> false
                                if (state == true) {
                                  labelStates[label.id] = false;
                                } else {
                                  labelStates[label.id] = true;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildPrimaryButton(
                      onTap: () {
                        Navigator.pop(context);
                        _applyBulkLabelsBatch(labelStates);
                      },
                      label: "Apply Changes",
                      iconData: Icons.check_circle_outline,
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _applyBulkLabelsBatch(Map<String, bool?> labelStates) async {
    showToast(isGood: true, msg: "Updating guest lists...");

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var attendee in selectList) {
        final ref = FirebaseFirestore.instance
            .collection('events')
            .doc(widget.edata.id)
            .collection('attendees')
            .doc(attendee.id);

        for (var entry in labelStates.entries) {
          if (entry.value == true) {
            // Ensure added to all
            batch.update(ref, {
              'labelIds': FieldValue.arrayUnion([entry.key]),
            });
          } else if (entry.value == false) {
            // Ensure removed from all
            batch.update(ref, {
              'labelIds': FieldValue.arrayRemove([entry.key]),
            });
          }
          // If null, do nothing (keep individual states)
        }
      }

      await batch.commit();

      setState(() {
        for (var attendee in selectList) {
          attendee.labelIds ??= [];
          for (var entry in labelStates.entries) {
            if (entry.value == true) {
              if (!attendee.labelIds!.contains(entry.key)) {
                attendee.labelIds!.add(entry.key);
              }
            } else if (entry.value == false) {
              attendee.labelIds!.remove(entry.key);
            }
          }
        }
        selectList.clear();
      });

      showToast(isGood: true, msg: "Updated successfully");
    } catch (e) {
      showToast(isGood: false, msg: "Failed to update: $e");
    }
  }

  delSelect() async {
    var uid = auth.currentUser?.uid;
    if (uid != widget.edata.authorId) {
      showToast(isGood: false, msg: "Action not allowed");
      return;
    }
    if (selectList.isEmpty) {
      showToast(isGood: false, msg: "Select attendee(s) first");
      return;
    }
    return await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text("Destructive Action"),
          message: Text(
            "You are about to delete ${selectList.length} attendee(s), keep in mind this action is ireversible",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: fsm),
          ),
          actions: [
            CupertinoActionSheetAction(
              isDefaultAction: true,
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await del();
                await _loadAttendees();
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("Cancel"),
              onPressed: () {
                poper();
              },
            ),
          ],
        );
      },
    );
  }

  del() async {
    try {
      poper();
      showToast(isGood: true, msg: "Deleting....");
      for (var sel in selectList) {
        firestore
            .collection(ecol)
            .doc(widget.edata.id)
            .collection(atcol)
            .doc(sel.id)
            .delete();
      }
      selectList = [];
      showToast(isGood: true, msg: "Success");
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
  }

  showQuickStats() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return modalBtmSheet(
          bdrdm: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _T.sep,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              quickStats(
                eventId: widget.edata.id ?? "",
                event: widget.edata,
                kardType: widget.kardType,
                kards: lcrds,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  showSelectCard({bool isContactImport = false}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return modalBtmSheet(
          bdrdm: 20,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pull handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _T.sep,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Designate Card",
                  style: _T.f(size: 18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                ...List.generate(lcrds.length, (idx) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      lqAssButton(
                        label: lcrds[idx].type,
                        onPressed: () {
                          Navigator.of(context).pop();
                          showImportContributor(
                            kard: lcrds[idx],
                            isContactImport: isContactImport,
                          );
                        },
                      ),
                      if (idx < lcrds.length - 1) const SizedBox(height: 10),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  showImportContributor({required Kard kard, bool isContactImport = false}) {
    return showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(bmd),
          topRight: Radius.circular(bmd),
        ),
      ),
      context: context,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: modalBtmSheet(
            bdrdm: bmd,
            child: ImportContributor(
              kard: kard,
              event: widget.edata,
              isContactImport: isContactImport,
              availableLabels: widget.edata.labels ?? [],
            ),
          ),
        );
      },
    );
  }

  importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx', 'xlsm', 'xlsb'],
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = file.name.split('.').last.toLowerCase();
    if (!['xls', 'xlsx', 'xlsm', 'xlsb'].contains(ext)) {
      showToast(isGood: false, msg: "Please select a valid Excel file");
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildFileConfirmDialog(ctx, file.name),
    );
    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildFileLoadingDialog(),
    );

    Map<dynamic, dynamic>? sels;

    try {
      final base64File = base64Encode(bytes);
      final response = await http.post(
        Uri.parse(excelToCsvUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fileBase64': base64File}),
      );
      final body = jsonDecode(response.body);
      if (body['status'] != true) {
        throw Exception(body['message'] ?? "Processing failed");
      }

      final rawHeaders = Map<String, dynamic>.from(body['headers'] ?? {});
      sels = {};
      rawHeaders.forEach((k, v) => sels![int.parse(k)] = v);

      importRows = List<List<dynamic>>.from(
        (body['rows'] as List).map((r) => List<dynamic>.from(r)),
      );

      setState(() => importSelectedLabels = []);
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
      showToast(isGood: false, msg: "Failed to process file");
      return;
    }

    if (mounted) Navigator.of(context).pop();
    await showMatcher(sels);
  }

  Widget _buildFileConfirmDialog(BuildContext ctx, String fileName) {
    return glassDialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.table_chart_rounded, color: _T.lime, size: 32),
            ),
            const SizedBox(height: 16),
            Text("Process File?", style: _T.f(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: _T.f(size: 12, color: _T.lime, weight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              "We'll upload and convert this file so you can map columns for import.",
              textAlign: TextAlign.center,
              style: _T.f(size: 13, color: _T.lbl3),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      alignment: Alignment.center,
                      child: Text("Cancel", style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lbl2)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _T.limeDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _T.lime.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: Text("Proceed", style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lime)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileLoadingDialog() {
    return glassDialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(color: _T.lime, radius: 14),
            const SizedBox(height: 16),
            Text("Processing file...", style: _T.f(size: 14, color: _T.lbl2)),
          ],
        ),
      ),
    );
  }

  showMatcher(Map<dynamic, dynamic> sels) {
    if (lcrds.isEmpty && widget.kardType != KardType.contact) {
      showToast(isGood: false, msg: "This action requires existing cards");
      return;
    }
    // creating a synthetic map for cards
    var synCrdmap = {};
    for (var lcrd in lcrds) {
      synCrdmap[lcrd.id] = lcrd.type;
    }

    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setAltState) {
            return modalBtmSheet(
              bdrdm: 28,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: _T.sep,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: _T.lime,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Configure Import",
                          style: _T.f(size: 20, weight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: Lists
                    if (widget.edata.labels != null &&
                        widget.edata.labels!.isNotEmpty) ...[
                      Text(
                        "Step 1: Assign to Labels",
                        style: _T.f(
                          size: 14,
                          color: _T.lime,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.edata.labels!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final label = widget.edata.labels![i];
                            final isSelected = importSelectedLabels.contains(
                              label.id,
                            );
                            return GestureDetector(
                              onTap: () {
                                setAltState(() {
                                  if (isSelected) {
                                    importSelectedLabels.remove(label.id);
                                  } else {
                                    importSelectedLabels.add(label.id);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Color(
                                            label.colorValue,
                                          ).withValues(alpha: 0.2)
                                          : _T.card,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Color(label.colorValue)
                                            : Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                  ),
                                ),
                                child: Text(
                                  label.name,
                                  style: _T.f(
                                    size: 13,
                                    color:
                                        isSelected
                                            ? Color(label.colorValue)
                                            : Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                    weight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    Text(
                      "Step 2: Map Excel Columns",
                      style: _T.f(
                        size: 14,
                        color: _T.lime,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MAPPING ROWS
                    _buildMappingRow(
                      icon: Icons.person_outline,
                      label: "Name",
                      dropdown: buildDrop(sels, impname, setAltState),
                    ),
                    const SizedBox(height: 16),
                    _buildMappingRow(
                      icon: Icons.phone_android_outlined,
                      label: "Phone",
                      dropdown: buildDrop(sels, impphone, setAltState),
                    ),

                    if (widget.kardType == KardType.contribution ||
                        widget.kardType == KardType.contact) ...[
                      const SizedBox(height: 16),
                      _buildMappingRow(
                        icon: Icons.favorite_border,
                        label: "Pledges",
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: _mapAhadi,
                                activeColor: _T.lime,
                                onChanged:
                                    (v) => setAltState(() => _mapAhadi = v),
                              ),
                            ),
                            if (_mapAhadi) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: buildDrop(sels, impahadi, setAltState),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMappingRow(
                        icon: Icons.payments_outlined,
                        label: "Contribution",
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: _mapMchango,
                                activeColor: _T.lime,
                                onChanged:
                                    (v) => setAltState(() => _mapMchango = v),
                              ),
                            ),
                            if (_mapMchango) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: buildDrop(sels, impmchango, setAltState),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    if (widget.kardType != KardType.contact) ...[
                      const SizedBox(height: 16),
                      _buildMappingRow(
                        icon: Icons.card_membership_outlined,
                        label: "Card Type",
                        dropdown: buildDrop(synCrdmap, impcard, setAltState),
                      ),
                    ],

                    const SizedBox(height: 40),
                    buildPrimaryButton(
                      label: "Proceed to Preview",
                      iconData: Icons.arrow_forward_rounded,
                      onTap: () async {
                        if (isGreen()) {
                          poper();
                          Map<String, dynamic> mapp = {
                            'fullName': int.parse(impname.text),
                            'phone': int.parse(impphone.text),
                            if ((widget.kardType == KardType.contribution ||
                                    widget.kardType == KardType.contact) &&
                                _mapAhadi)
                              'ahadi': int.parse(impahadi.text),
                            if ((widget.kardType == KardType.contribution ||
                                    widget.kardType == KardType.contact) &&
                                _mapMchango)
                              'mchango': int.parse(impmchango.text),
                            if (importSelectedLabels.isNotEmpty)
                              'labelIds': importSelectedLabels,
                          };
                          var cardId =
                              widget.kardType == KardType.contact
                                  ? "contact"
                                  : impcard.text;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => ImpPreview(
                                    mapp: mapp,
                                    importRows: importRows!,
                                    templateCardId: cardId,
                                    event: widget.edata,
                                    kardType: widget.kardType,
                                    labelIds: importSelectedLabels,
                                  ),
                            ),
                          );
                          await _loadAttendees();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMappingRow({
    required IconData icon,
    required String label,
    Widget? dropdown,
    Widget? child,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _T.lime.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _T.lime, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(label, style: _T.f(weight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: dropdown ?? child ?? const SizedBox.shrink()),
      ],
    );
  }

  Widget buildDrop(
    Map sels,
    TextEditingController mapcont, [
    StateSetter? altState,
  ]) {
    // Current value from the controller
    dynamic currentKey;
    try {
      currentKey = int.tryParse(mapcont.text) ?? mapcont.text;
      if (currentKey == "") currentKey = null;
    } catch (_) {}

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.sep),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: sels.containsKey(currentKey) ? currentKey : null,
          hint: Text("Select Source", style: _T.f(size: 13, color: _T.lbl4)),
          dropdownColor: _T.card,
          icon: const Icon(Icons.expand_more_rounded, color: _T.lime, size: 20),
          isExpanded: true,
          onChanged: (val) {
            (altState ?? setState)(() {
              mapcont.text = "$val";
            });
          },
          items:
              sels.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    "${entry.value}",
                    style: _T.f(size: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  isGreen() {
    if (impname.text.isEmpty) {
      showToast(isGood: false, msg: "Select a column with values for name");
      return false;
    } else if (impphone.text.isEmpty) {
      showToast(isGood: false, msg: "Select a column with values for phone");
      return false;
    } else if ((widget.kardType == KardType.contribution ||
            widget.kardType == KardType.contact) &&
        _mapAhadi &&
        impahadi.text.isEmpty) {
      showToast(isGood: false, msg: "Select a column for pledges or opt out");
      return false;
    } else if ((widget.kardType == KardType.contribution ||
            widget.kardType == KardType.contact) &&
        _mapMchango &&
        impmchango.text.isEmpty) {
      showToast(
        isGood: false,
        msg: "Select a column for contributions or opt out",
      );
      return false;
    } else if (widget.kardType != KardType.contact && impcard.text.isEmpty) {
      showToast(isGood: false, msg: "Select a card to assign the attendees");
      return false;
    } else {
      return true;
    }
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  poper() {
    Navigator.of(context).pop();
  }
}

class _HeroCard extends StatelessWidget {
  final double totalPledged;
  final double totalPaid;
  final double pct;
  final Animation<double> progressAnim;

  const _HeroCard({
    required this.totalPledged,
    required this.totalPaid,
    required this.pct,
    required this.progressAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.sep, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _T.lime.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _T.lime.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _T.lime,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'CONTRIBUTIONS',
                    style: _T.f(
                      size: 11,
                      weight: FontWeight.w700,
                      color: _T.lbl3,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _T.limeDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _T.lime.withValues(alpha: 0.3),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  '${(pct * 100).round()}%',
                  style: _T.f(
                    size: 13,
                    weight: FontWeight.w800,
                    color: _T.lime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatMoney(totalPaid, currency: "TZS"),
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -1.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          // Gradient progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 6, color: _T.card3),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_T.lime.withValues(alpha: 0.7), _T.lime],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal: ${formatMoney(totalPledged, currency: "TZS")}',
                style: _T.f(size: 12, color: _T.lbl3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark, matching admin_pane.dart
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  // Backgrounds
  static const bg = Color(0xFF111114);
  static const card = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const card3 = Color(0xFF3A3A3C);
  static const sep = Color(0xFF2C2C2E);

  // Accent
  static const lime = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);

  // Text hierarchy
  static const white = Color(0xFFFFFFFF);
  static const lbl1 = Color(0xFFEEEEF0);
  static const lbl2 = Color(0xFFAEAEB2);
  static const lbl3 = Color(0xFF8E8E93);
  static const lbl4 = Color(0xFF48484A);

  // Compat shorthands
  static Color get grey2 => lbl3;

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
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

class _PendingBanner extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _PendingBanner({required this.onRefresh});

  static const _orange = Color(0xFFFF9500); // Apple system orange

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _orange.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Generating Cards",
                  style: _T.f(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _T.lbl1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Some cards are still processing. Refresh in a moment.",
                  style: _T.f(size: 11, color: _T.lbl3, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _orange.withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: Text(
                "Refresh",
                style: _T.f(size: 12, weight: FontWeight.w700, color: _orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
