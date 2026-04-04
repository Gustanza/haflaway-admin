import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart' as exl;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/custom_popup_btn.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/wsap.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/sms/custom_camps/ccampsmain.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/attendee_card.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/importcontr.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/stats.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/crtattendees.dart';
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
import 'package:icons_plus/icons_plus.dart';
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
  Uint8List? xcelBytes;
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
    setState(() {
      isLoading = true;
    });
    pageSize = atList.isEmpty ? atsPageSize : atList.length;
    try {
      Query<Map<String, dynamic>> query = nQwrBuilder();
      var snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          hasMore = false;
          isLoading = false;
        });
        if (_selectedKardFilter != null || _attendanceFilter != "All")
          showToast(isGood: true, msg: "NO ITEMS FOUND");
        return;
      }
      lastDocument = snapshot.docs.last;
      setState(() {
        atList =
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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  nQwrBuilder() {
    if (_selectedKardFilter != null && _attendanceFilter != "All") {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .where(
            "cards.${widget.kardType.name}.templateCardId",
            isEqualTo: _selectedKardFilter,
          )
          .where("attendanceStatus", isEqualTo: _attendanceFilter)
          .orderBy("cards.${widget.kardType.name}.templateCardId")
          .orderBy("attendanceStatus")
          .limit(pageSize);
    } else if (_selectedKardFilter == null && _attendanceFilter != "All") {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .where("attendanceStatus", isEqualTo: _attendanceFilter)
          .orderBy("attendanceStatus")
          .limit(pageSize);
    } else if (_selectedKardFilter != null && _attendanceFilter == "All") {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .where(
            "cards.${widget.kardType.name}.templateCardId",
            isEqualTo: _selectedKardFilter,
          )
          .orderBy("cards.${widget.kardType.name}.templateCardId")
          .limit(pageSize);
    } else if (widget.kardType == KardType.contact) {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .orderBy("createdAt", descending: true)
          .limit(pageSize);
    } else {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .orderBy("createdAt", descending: true)
          .limit(pageSize);
    }
  }

  mQwrBuilder() {
    if (_selectedKardFilter != null && _attendanceFilter != "All") {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .where(
            "cards.${widget.kardType.name}.templateCardId",
            isEqualTo: _selectedKardFilter,
          )
          .where("attendanceStatus", isEqualTo: _attendanceFilter)
          .orderBy("cards.${widget.kardType.name}.templateCardId")
          .orderBy("attendanceStatus")
          .startAfterDocument(lastDocument!)
          .limit(pageSize);
    } else if (_selectedKardFilter == null && _attendanceFilter != "All") {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .where("attendanceStatus", isEqualTo: _attendanceFilter)
          .orderBy("attendanceStatus")
          .startAfterDocument(lastDocument!)
          .limit(pageSize);
    } else if (_selectedKardFilter != null && _attendanceFilter == "All") {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .where(
            "cards.${widget.kardType.name}.templateCardId",
            isEqualTo: _selectedKardFilter,
          )
          .orderBy("cards.${widget.kardType.name}.templateCardId")
          .startAfterDocument(lastDocument!)
          .limit(pageSize);
    } else if (widget.kardType == KardType.contact) {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .orderBy("createdAt", descending: true)
          .startAfterDocument(lastDocument!)
          .limit(pageSize);
    } else {
      return firestore
          .collection(ecol)
          .doc(widget.edata.id)
          .collection(atcol)
          .orderBy("createdAt", descending: true)
          .startAfterDocument(lastDocument!)
          .limit(pageSize);
    }
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
      String searchKey = query.toLowerCase();

      // Ensure we filter by current kardType and prefix search on name
      QuerySnapshot<Map<String, dynamic>> res =
          await firestore
              .collection(ecol)
              .doc(widget.edata.id)
              .collection(atcol)
              .where('fullNameLower', isGreaterThanOrEqualTo: searchKey)
              .where('fullNameLower', isLessThanOrEqualTo: searchKey + '\uf8ff')
              .limit(100) // Increased limit to ensure enough filtered results
              .get();

      setState(() {
        searchResults =
            res.docs
                .where((doc) {
                  try {
                    var krd = doc.data()['cards'][widget.kardType.name];
                    return krd != null;
                  } catch (e) {
                    return false;
                  }
                })
                .map<Attendee>((doc) => Attendee.fromMap(doc.id, doc.data()))
                .take(20) // Only take top 20 after filtering
                .toList();
        isLoading = false;
      });
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
    return bildPopupMenu(
      icon: Icon(Icons.exit_to_app_outlined),
      popItems: [
        PopClickers(
          leading: Icon(Icons.summarize),
          title: Text("Summary"),
          onTap: showQuickStats,
        ),
        if (widget.kardType == KardType.invitation ||
            widget.kardType == KardType.contribution)
          PopClickers(
            leading: Icon(Icons.mail),
            title: Text("Send Card"),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return InvitesIssuers(
                      event: widget.edata,
                      kardType: widget.kardType,
                      campaignId:
                          widget.kardType == KardType.invitation
                              ? invCampId
                              : contrCampId,
                    );
                  },
                ),
              );
              _loadAttendees();
            },
          ),
        if (widget.kardType == KardType.invitation)
          PopClickers(
            leading: Icon(Icons.mail),
            title: Text("Send Reminder"),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return InvitesIssuers(
                      event: widget.edata,
                      kardType: widget.kardType,
                      campaignId: invRemCampId,
                    );
                  },
                ),
              );
              _loadAttendees();
            },
          ),
        PopClickers(
          leading: Icon(Icons.sms),
          title: Text("Send Bulk SMS"),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return AdminCampaigns(
                    event: widget.edata,
                    title: "Send Bulk SMS",
                    kardType: widget.kardType,
                  );
                },
              ),
            );
            _loadAttendees();
          },
        ),

        // PopClickers(
        //   leading: Icon(Icons.sms),
        //   title: Text("Rekebisha Burger"),
        //   onTap: () async {
        //     try {
        //       firestore
        //           .collection(ecol)
        //           .doc(widget.edata.id)
        //           .collection(atcol)
        //           .where("cards.invitation.name", isEqualTo: "DOUBLE ")
        //           .get()
        //           .then((snapshot) {
        //             print("Docuements: ${snapshot.docs.length}");
        //             for (var doc in snapshot.docs) {
        //               doc.reference.set({
        //                 "checkinStatus": [
        //                   {
        //                     "attendee_name": "SLOT 01",
        //                     "checkpoints": {"JHsilQlhDgHEpbnyBbfQ": false},
        //                   },
        //                   {
        //                     "attendee_name": "SLOT 02",
        //                     "checkpoints": {"JHsilQlhDgHEpbnyBbfQ": false},
        //                   },
        //                 ],
        //               }, SetOptions(merge: true));
        //             }
        //           });
        //     } catch (e) {
        //       debugPrint("Shida: $e");
        //     }
        //   },
        // ),
      ],
    );
  }

  getMiniBuild() {
    return bildPopupMenu(
      icon: Icon(Icons.group_add),
      popItems: [
        PopClickers(
          leading: Icon(Icons.group_add),
          title: Text(
            widget.kardType == KardType.invitation
                ? "Add Invitee"
                : widget.kardType == KardType.contribution
                ? "Add Contributor"
                : widget.kardType == KardType.contact
                ? "Add Contact"
                : "",
          ),
          onTap: () async {
            String title =
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
        PopClickers(
          leading: Icon(Icons.note_add_rounded),
          title: Text("Upload File"),
          onTap: () {
            importFile();
          },
        ),
        if (widget.kardType == KardType.invitation) ...[
          PopClickers(
            leading: Icon(Icons.monetization_on_sharp),
            title: Text("Import from Contributors"),
            onTap: () {
              showSelectCard(isContactImport: false);
            },
          ),
          PopClickers(
            leading: Icon(Icons.contact_phone_rounded),
            title: Text("Import from Contacts"),
            onTap: () {
              showSelectCard(isContactImport: true);
            },
          ),
        ],
      ],
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
              top: -100,
              right: -100,
              child: _GusOrb(size: 300, color: _T.lime, opacity: 0.08),
            ),
            const Positioned(
              bottom: -50,
              left: -100,
              child: _GusOrb(size: 250, color: _T.lime, opacity: 0.05),
            ),

            RefreshIndicator(
              onRefresh: () async {
                await _loadAttendees();
              },
              color: _T.lime,
              backgroundColor: _T.card,
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // ── Header Section ──
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topBar(inSelectMode),
                          if (!isSearching) _titleBlock(),
                        ],
                      ),
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
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: BuildNoDt(
                        string: isSearching ? "No Results Found" : "no data",
                        isRefreshed: () async {
                          if (isSearching) {
                            performSearch(searchController.text);
                          } else {
                            await _loadAttendees();
                          }
                        },
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
                                onEdit: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CreateAttendees(
                                            event: widget.edata,
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
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool inSelectMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          if (!isSearching)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _T.lime,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
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
              icon: Clarity.trash_solid,
              label: "Delete",
              color: Colors.redAccent,
              onTap: delSelect,
            )
          else if (widget.kardType != KardType.contact)
            Row(
              children: [
                if (!isSearching) ...[
                  _buildFilterButton(),
                  const SizedBox(width: 8),
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
                        style: GoogleFonts.inter(
                          color: _T.lime,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
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
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "End of list",
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 20);
  }

  // Build elegant filter button for app bar
  Widget _buildFilterButton() {
    // Count active filters
    int activeFiltersCount = 0;
    if (_selectedKardFilter != null) activeFiltersCount++;
    if (_attendanceFilter != "All") activeFiltersCount++;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showFilterBottomSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.tune,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
            ),
          ),
        ),
        // Active filter indicator badge
        if (activeFiltersCount > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  "$activeFiltersCount",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
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
                    margin: EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: psm,
                      vertical: psm * 0.5,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 24,
                        ),
                        SizedBox(width: psm * 0.5),
                        Text(
                          "Filters",
                          style: TextStyle(
                            fontSize: fsm + 4,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        if (_selectedKardFilter != null ||
                            _attendanceFilter != "All")
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedKardFilter = null;
                                _attendanceFilter = "All";
                              });
                              Navigator.pop(context);
                              _loadAttendees();
                            },
                            child: Text(
                              "Clear All",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.2),
                    height: 1,
                  ),
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
                            SizedBox(height: psm * 1.5),
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + psm * 0.5,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.8)),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: fsm + 2,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        SizedBox(height: psm * 0.75),
        child,
      ],
    );
  }

  // Build elegant filter chip for bottom sheet
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle, size: 16, color: Colors.white),
                SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fsm,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.8),
                ),
              ),
            ],
          ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFrostedFAB(child: getMiniBuild(), isMini: true),
        const SizedBox(height: 12),
        _buildFrostedFAB(child: getMainBuild(), isMini: false),
      ],
    );
  }

  Widget _buildFrostedFAB({required Widget child, bool isMini = false}) {
    final double size = isMini ? 48.0 : 56.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(color: _T.lime.withOpacity(0.2), width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader(int count) {
    bool hasActiveFilters =
        _selectedKardFilter != null || _attendanceFilter != "All";
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            "${count} ${widget.kardType == KardType.invitation
                ? 'Invitees'
                : widget.kardType == KardType.contribution
                ? 'Contributors'
                : 'Contacts'}",
            style: _T.f(
              size: 14,
              weight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
          ),
          if (hasActiveFilters) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Filtered",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              quickStats(
                eventId: widget.edata.id ?? "",
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
                    color: Colors.white.withOpacity(0.1),
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
    if (result != null) {
      var bytes = result.files.single.bytes;
      var excel = exl.Excel.decodeBytes(bytes!);
      var tblKey = excel.tables.keys.firstOrNull;
      var table = excel.tables[tblKey];

      var frow = table!.rows.first;
      Map<dynamic, dynamic> sels = {};
      for (var cell in frow) {
        sels[cell!.columnIndex] = cell.value;
      }
      xcelBytes = bytes;
      await showMatcher(sels);
    } else {
      showToast(isGood: false, msg: genErrMsg);
    }
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
    // ends here
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(bmd),
          topRight: Radius.circular(bmd),
        ),
      ),
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setAltState) {
            return modalBtmSheet(
              bdrdm: bmd,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: psm),
                    Text(
                      "Import from File",
                      style: TextStyle(
                        fontSize: fsm + 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(psm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Name",
                            style: TextStyle(
                              fontSize: fsm + 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          buildDrop(sels, impname),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(psm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Phone",
                            style: TextStyle(
                              fontSize: fsm + 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          buildDrop(sels, impphone),
                        ],
                      ),
                    ),
                    // Ahadi & Michango Stuff
                    if (widget.kardType == KardType.contribution ||
                        widget.kardType == KardType.contact)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: psm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _mapAhadi,
                                  onChanged: (v) {
                                    setAltState(() {
                                      _mapAhadi = v ?? false;
                                    });
                                  },
                                ),
                                const Text(
                                  "Pledge",
                                  style: TextStyle(
                                    fontSize: fsm + 2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (_mapAhadi) buildDrop(sels, impahadi),
                          ],
                        ),
                      ),
                    if (widget.kardType == KardType.contribution ||
                        widget.kardType == KardType.contact)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: psm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _mapMchango,
                                  onChanged: (v) {
                                    setAltState(() {
                                      _mapMchango = v ?? false;
                                    });
                                  },
                                ),
                                const Text(
                                  "Contribution",
                                  style: TextStyle(
                                    fontSize: fsm + 2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (_mapMchango) buildDrop(sels, impmchango),
                          ],
                        ),
                      ),
                    if (widget.kardType != KardType.contact)
                      Padding(
                        padding: const EdgeInsets.all(psm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Card",
                              style: TextStyle(
                                fontSize: fsm + 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            buildDrop(synCrdmap, impcard),
                          ],
                        ),
                      ),
                    const SizedBox(height: psm),
                    lqAssButton(
                      label: "Continue",
                      onPressed: () async {
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
                          };
                          var cardId =
                              widget.kardType == KardType.contact
                                  ? "contact"
                                  : impcard.text;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return ImpPreview(
                                  mapp: mapp,
                                  xcelBytes: xcelBytes!,
                                  templateCardId: cardId,
                                  event: widget.edata,
                                  kardType: widget.kardType,
                                );
                              },
                            ),
                          );
                          await _loadAttendees();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  buildDrop(Map sels, TextEditingController mapcont) {
    return DropdownMenu(
      hintText: "Select values",
      width: MediaQuery.of(context).size.width * 0.4,
      inputDecorationTheme: const InputDecorationTheme(),
      onSelected: (value) {
        mapcont.text = "$value";
      },
      dropdownMenuEntries:
          sels.entries.map((entry) {
            return DropdownMenuEntry(value: entry.key, label: "${entry.value}");
          }).toList(),
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
      margin: const EdgeInsets.only(bottom: 24, top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONTRIBUTIONS',
                style: _T.f(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _T.grey2,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: _T.f(size: 15, weight: FontWeight.w700, color: _T.lime),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(totalPaid, currency: "TZS"),
            style: _T.f(
              size: 24,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: const Color(0xFF333333),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC9A84C),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Goal: ${formatMoney(totalPledged, currency: "TZS")}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens (Apple / Obsidian Hybrid)
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF0A0A0A);
  static const card = Color(0xFF141414);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const grey2 = Color(0xFF555555);

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
