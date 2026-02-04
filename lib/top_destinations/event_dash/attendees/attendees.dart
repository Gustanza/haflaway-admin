import 'dart:io';
import 'dart:ui';
import 'package:excel/excel.dart' as exl;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/custom_popup_btn.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/wsap.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/sms/custom_camps/ccampsmain.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/attendee_card.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/importcontr.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/searchdel.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/stats.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/crtattendees.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/errorstrs.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
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
    this.title = "Ratibu Mialiko",
  });
  @override
  State<Attendees> createState() => _AttendeesState();
}

class _AttendeesState extends State<Attendees> with TickerProviderStateMixin {
  File? file;
  List<Kard> lcrds = [];
  String? _selectedKardFilter;
  List<Attendee> atList = [];
  List<Attendee> filteredList = [];
  List<Attendee> selectList = [];
  TextEditingController impname = TextEditingController();
  TextEditingController impphone = TextEditingController();
  TextEditingController impcard = TextEditingController();
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
          title: Text("Taarifa fupi"),
          onTap: showQuickStats,
        ),
        PopClickers(
          leading: Icon(Icons.mail),
          title: Text("Tuma Kadi"),
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
        PopClickers(
          leading: Icon(Icons.sms),
          title: Text("Tuma Bulk SMS"),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return AdminCampaigns(
                    event: widget.edata,
                    title: "Tuma Bulk SMS",
                    kardType: widget.kardType,
                  );
                },
              ),
            );
            _loadAttendees();
          },
        ),
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
                ? "Ongeza Mwalikwa"
                : widget.kardType == KardType.contribution
                ? "Ongeza Mchangiaji"
                : "",
          ),
          onTap: () async {
            String title =
                widget.kardType == KardType.invitation
                    ? "Invitation"
                    : "Contributor";
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
          title: Text("Pandisha Faili"),
          onTap: () {
            importFile();
          },
        ),
        if (widget.kardType == KardType.invitation)
          PopClickers(
            leading: Icon(Icons.monetization_on_sharp),
            title: Text("Pandisha Mchangiaji"),
            onTap: () {
              showSelectCard();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title:
            selectList.isEmpty
                ? "${widget.title}"
                : "Chaguzi: ${selectList.length}",
        leading: appBarActionButton(
          icon: selectList.isEmpty ? Icons.arrow_back : Icons.close,
          onTap: () {
            if (selectList.isEmpty) {
              Navigator.of(context).pop();
            } else {
              safeState(() {
                selectList = [];
              });
            }
          },
        ),
        actions: Row(
          children: [
            if (selectList.isEmpty) _buildFilterButton(),
            if (selectList.isEmpty)
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: DhaSearchDelegate(
                      edata: widget.edata,
                      kardType: widget.kardType,
                    ),
                  );
                },
              ),
            if (selectList.isNotEmpty)
              FilledButton.icon(
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  backgroundColor: WidgetStatePropertyAll(lqassgradBaseColor),
                ),
                onPressed: () {
                  delSelect();
                },
                label: Text("Delete"),
                icon: Icon(Clarity.trash_solid),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: "mini",
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(bmd * 10),
              side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
            ),
            foregroundColor: Colors.white,
            child: getMiniBuild(),
            onPressed: null,
          ),
          const SizedBox(height: spaceTiles),
          FloatingActionButton(
            heroTag: "major",
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(bmd * 10),
              side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
            ),
            foregroundColor: Colors.white,
            child: getMainBuild(),
            onPressed: null,
          ),
        ],
      ),
      body: Ccafold(
        child:
            atList.isEmpty && isLoading
                ? buildLoader()
                : atList.isEmpty && !isLoading
                ? BuildNoDt(
                  string: "No Attendees Found",
                  isRefreshed: () async {
                    await _loadAttendees();
                  },
                )
                : buildAtList(atList),
      ),
    );
  }

  buildAtList(List<Attendee> atdata) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAttendees();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(spaceTiles),
              controller: scrollController,
              itemCount: atdata.length + 1, // +1 for the loading indicator
              itemBuilder: (context, index) {
                // Show loading indicator at the end
                if (index == atdata.length) {
                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  } else if (!hasMore && atdata.isNotEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          "No more attendees to load",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox(height: 20);
                  }
                }

                // Show attendee item
                Attendee attendee = atdata[index];
                var hasKey = selectList.any((test) {
                  return test.id == attendee.id;
                });
                var campaignId =
                    widget.kardType == KardType.invitation
                        ? invCampId
                        : contrCampId;
                return buildAttendeeCard(
                  hasKey: hasKey,
                  attendee: attendee,
                  kardType: widget.kardType,
                  eventId: widget.edata.id ?? "_",
                  campaignId: campaignId,
                  onEdit: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return CreateAttendees(
                            event: widget.edata,
                            kardType: widget.kardType,
                            attendee: attendee,
                          );
                        },
                      ),
                    );
                    _loadAttendees();
                  },
                  onSelected: () {
                    if (hasKey) {
                      var tmp =
                          selectList.where((test) {
                            return test.id != attendee.id;
                          }).toList();
                      selectList = tmp;
                    } else {
                      selectList.add(attendee);
                    }
                    safeState(() {});
                  },
                  onStatusChange: (status) {
                    if (widget.kardType == KardType.contribution)
                      return _loadAttendees();
                    int index = atdata.indexWhere(
                      (element) => element.id == attendee.id,
                    );
                    if (index != -1) {
                      atdata[index].attendanceStatus = status;
                    }
                    safeState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
      debugPrint("shida: $e");
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
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: quickStats(
            eventId: widget.edata.id ?? "",
            kardType: widget.kardType,
            kards: lcrds,
          ),
        );
      },
    );
  }

  showSelectCard() {
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: psm,
              vertical: psm * 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Designate Card",
                  style: TextStyle(
                    fontSize: fsm + 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: psm),
                ...List.generate(lcrds.length, (idx) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      lqAssButton(
                        label: lcrds[idx].type,
                        onPressed: () {
                          Navigator.of(context).pop();
                          showImportContributor(kard: lcrds[idx]);
                        },
                      ),
                      if (idx < lcrds.length - 1) SizedBox(height: psm * 0.5),
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

  showImportContributor({required Kard kard}) {
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
            child: ImportContributor(kard: kard, event: widget.edata),
          ),
        );
      },
    );
  }

  importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx', 'xlsm', 'xlsb'],
    );
    if (result != null) {
      file = File(result.files.single.path!);
      var bytes = file?.readAsBytesSync();
      var excel = exl.Excel.decodeBytes(bytes!);
      var tblKey = excel.tables.keys.firstOrNull;
      var table = excel.tables[tblKey];

      var frow = table!.rows.first;
      Map<dynamic, dynamic> sels = {};
      for (var cell in frow) {
        sels[cell!.columnIndex] = cell.value;
      }
      await showMatcher(sels);
    } else {
      showToast(isGood: false, msg: genErrMsg);
    }
  }

  showMatcher(Map<dynamic, dynamic> sels) {
    if (lcrds.isEmpty) {
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
                      };
                      var carddata = lcrds.firstWhere((lcrd) {
                        return lcrd.id == impcard.text;
                      });
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ImpPreview(
                              mapp: mapp,
                              xcelFile: file!,
                              carddata: carddata,
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
    } else if (impcard.text.isEmpty) {
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
