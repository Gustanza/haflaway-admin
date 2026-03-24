import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/searchdel.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/stats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/public_search_del.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PubAttendees extends StatefulWidget {
  final String eventId;
  final KardType kardType;
  final String title;
  const PubAttendees({
    super.key,
    required this.eventId,
    required this.kardType,
    this.title = "Mialiko Yote",
  });
  @override
  State<PubAttendees> createState() => _PubAttendeesState();
}

class _PubAttendeesState extends State<PubAttendees>
    with TickerProviderStateMixin {
  Uint8List? xcelBytes;
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
  final int pageSize = 20;
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;
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
      if (!isLoading && hasMore && scont.text.isEmpty) {
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
          .doc(widget.eventId)
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
          .doc(widget.eventId)
          .collection(atcol)
          .where("attendanceStatus", isEqualTo: _attendanceFilter)
          .orderBy("attendanceStatus")
          .limit(pageSize);
    } else if (_selectedKardFilter != null && _attendanceFilter == "All") {
      return firestore
          .collection(ecol)
          .doc(widget.eventId)
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
          .doc(widget.eventId)
          .collection(atcol)
          .orderBy("createdAt", descending: true)
          .limit(pageSize);
    }
  }

  mQwrBuilder() {
    if (_selectedKardFilter != null && _attendanceFilter != "All") {
      return firestore
          .collection(ecol)
          .doc(widget.eventId)
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
          .doc(widget.eventId)
          .collection(atcol)
          .where("attendanceStatus", isEqualTo: _attendanceFilter)
          .orderBy("attendanceStatus")
          .startAfterDocument(lastDocument!)
          .limit(pageSize);
    } else if (_selectedKardFilter != null && _attendanceFilter == "All") {
      return firestore
          .collection(ecol)
          .doc(widget.eventId)
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
          .doc(widget.eventId)
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

  // Update attendance status
  Future<void> _updateAttendanceStatus(Attendee attendee, String status) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Perform the update
      await firestore
          .collection(ecol)
          .doc(widget.eventId)
          .collection(atcol)
          .doc(attendee.id)
          .update({"attendanceStatus": status});

      // Update local state
      int index = atList.indexWhere((element) => element.id == attendee.id);
      if (index != -1) {
        atList[index].attendanceStatus = status;
      }

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      showToast(isGood: true, msg: "Attendance status updated to $status");

      // Trigger UI refresh
      setState(() {});
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      showToast(isGood: false, msg: "Error updating attendance status: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAttendees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "${widget.title}",
        // leading: appBarActionButton(
        //   icon: Icons.arrow_back,
        //   onTap: () {
        //     Navigator.of(context).pop();
        //   },
        // ),
        actions: Row(
          children: [
            // Elegant filter button with active filter indicator
            _buildFilterButton(),
            IconButton(
              icon: Icon(Icons.bar_chart),
              onPressed: () {
                showQuickStats();
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: PubSearchDelegate(
                    eventId: widget.eventId,
                    kardType: widget.kardType,
                  ),
                );
              },
            ),
          ],
        ),
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
              padding: EdgeInsets.only(top: spaceTiles),
              controller: scrollController,
              itemCount: atdata.length + 1, // +1 for the loading indicator
              itemBuilder: (context, index) {
                // Show loading indicator at the end
                if (index == atdata.length) {
                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
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
                return _buildAttendeeCard(atdata[index]);
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

  // Build attendee card
  Widget _buildAttendeeCard(Attendee attendee) {
    var fullname = attendee.fullName;
    var attrCrdMap = attendee.cards[widget.kardType.name];
    AttributeCard? attributeCard;
    attributeCard =
        attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
    String crdnm =
        attributeCard != null ? attributeCard.name ?? "Not Set" : "Not Set";

    var hasKey = selectList.any((test) {
      return test.id == attendee.id;
    });

    // Calculate message count if messages property exists
    int messageCount = 0;
    messageCount = (attendee.messages).length;

    return GestureDetector(
      onTap: () {
        // Toggle selection on tap
        if (hasKey) {
          var tmp =
              selectList.where((test) {
                return test.id != attendee.id;
              }).toList();
          selectList = tmp;
        } else {
          selectList.add(attendee);
        }
        setState(() {});
      },
      child: Container(
        margin: EdgeInsets.only(left: psm, right: psm, bottom: psm * 0.5),
        decoration: BoxDecoration(
          gradient: lqassgrad,
          border:
              !hasKey
                  ? lqassbdr
                  : Border.all(color: Colors.redAccent, width: bdrWidthGen),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(psm * 0.625),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Avatar, Name, Actions
              Row(
                children: [
                  // Avatar with message badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: "avatar-${attendee.id}",
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_circle,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      if (messageCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: EdgeInsets.all(messageCount > 9 ? 3 : 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              messageCount > 99 ? "99+" : "$messageCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: psm * 0.5),
                  // Name and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullname,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fsm + 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: psm * 0.25),
                        // Card name and phone in compact row
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            SizedBox(width: 4),
                            Text(
                              crdnm,
                              style: TextStyle(
                                fontSize: fsm - 1,
                                overflow: TextOverflow.ellipsis,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                            ),
                            SizedBox(width: psm),
                            Icon(
                              Clarity.mobile_phone_line,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                attendee.phone,
                                style: TextStyle(
                                  fontSize: fsm - 1,
                                  overflow: TextOverflow.ellipsis,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: psm * 0.375),
                        // Delivery status indicators - SMS & WhatsApp
                        _buildDeliveryStatusIndicators(attendee),
                      ],
                    ),
                  ),
                  // Action buttons - compact
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View card button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            var vcrd = attendee.cards[widget.kardType.name];
                            if (vcrd != null) {
                              AttributeCard attrCrd = AttributeCard.fromMap(
                                map: vcrd,
                              );
                              try {
                                launchUrl(Uri.parse(attrCrd.url ?? ""));
                              } catch (e) {
                                showToast(isGood: false, msg: "$e");
                              }
                            } else {
                              showToast(isGood: false, msg: "Unable to View");
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Clarity.eye_show_line,
                              size: icnsm + 2,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                      // Call button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => callNumber(attendee.phone),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.call,
                              size: icnsm + 2,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                      // Edit button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {},
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit,
                              size: icnsm + 2,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: psm * 0.5),
              // Attendance controls - compact
              _buildAttendanceControls(attendee),
            ],
          ),
        ),
      ),
    );
  }

  // Build delivery status indicators for SMS and WhatsApp
  Widget _buildDeliveryStatusIndicators(Attendee attendee) {
    // Placeholder values - will be replaced with actual data later
    String smsStatus =
        "delivered"; // Placeholder: "delivered", "pending", "failed", "sent"
    String whatsappStatus =
        "read"; // Placeholder: "delivered", "read", "sent", "failed", "pending"

    return Row(
      children: [
        // SMS Status Indicator
        _buildStatusChip(
          icon: Icons.sms_outlined,
          label: "SMS",
          status: smsStatus,
        ),
        SizedBox(width: psm * 0.5),
        // WhatsApp Status Indicator
        _buildStatusChip(
          icon: Icons.chat_bubble_outline,
          label: "WhatsApp",
          status: whatsappStatus,
        ),
      ],
    );
  }

  // Build individual status chip
  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required String status,
  }) {
    // Determine status color and styling based on status text
    Color statusColor;
    Color backgroundColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case "delivered":
      case "read":
        statusColor = Colors.greenAccent;
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        statusIcon = Icons.check_circle;
        break;
      case "sent":
        statusColor = Colors.lightBlueAccent;
        backgroundColor = Colors.blue.withValues(alpha: 0.2);
        statusIcon = Icons.send;
        break;
      case "pending":
      case "queued":
        statusColor = Colors.orangeAccent;
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        statusIcon = Icons.schedule;
        break;
      case "failed":
      case "undelivered":
        statusColor = Colors.redAccent;
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey.shade400;
        backgroundColor = Colors.grey.withValues(alpha: 0.2);
        statusIcon = Icons.help_outline;
    }

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: psm * 0.375,
          vertical: psm * 0.3,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: statusColor),
            SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 5),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 9, color: statusColor),
                  SizedBox(width: 3),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
                      height: 1,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build attendance controls
  Widget _buildAttendanceControls(Attendee attendee) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: psm * 0.5,
        vertical: psm * 0.375,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusButton(
            attendee,
            atconfstate,
            Icons.check_circle,
            Colors.green,
            attendee.attendanceStatus == atconfstate,
          ),
          _buildStatusButton(
            attendee,
            atnotconfstate,
            Icons.schedule,
            Colors.grey,
            attendee.attendanceStatus == atnotconfstate ||
                attendee.attendanceStatus == null,
          ),
          _buildStatusButton(
            attendee,
            atdeclstate,
            Icons.cancel,
            Colors.red,
            attendee.attendanceStatus == atdeclstate,
          ),
          _buildStatusButton(
            attendee,
            atcallstate,
            Icons.call_made,
            Colors.teal,
            attendee.attendanceStatus == atcallstate,
          ),
          _buildStatusButton(
            attendee,
            atunreachablestate,
            Icons.cloud_off_outlined,
            Colors.orange,
            attendee.attendanceStatus == atunreachablestate,
          ),
        ],
      ),
    );
  }

  // Build status button
  Widget _buildStatusButton(
    Attendee attendee,
    String status,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          _updateAttendanceStatus(attendee, status);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: psm * 0.375),
          margin: EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.3),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : color.withValues(alpha: 0.7),
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
              .doc(widget.eventId)
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

  showQuickStats() {
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: quickStats(
            eventId: widget.eventId,
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
                      lqAssButton(label: lcrds[idx].type, onPressed: () {}),
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
