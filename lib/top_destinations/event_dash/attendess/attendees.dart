import 'dart:io';
import 'dart:ui';
import 'package:excel/excel.dart' as exl;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/services/strg_service.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/components/importcontr.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/components/searchdel.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/components/stats.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/crtattendees.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/view_card.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/errorstrs.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'imp_preview.dart';

class Attendees extends StatefulWidget {
  final Event edata;
  final KardType kardType;
  final String title;
  const Attendees({
    super.key,
    required this.edata,
    required this.kardType,
    this.title = "Invitations",
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
  // Attendance status filters
  String _attendanceFilter = "All";
  final List<String> _filters = [
    "All",
    "Confirmed",
    "Not Confirmed",
    "Declined",
    "Call Made",
  ];

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
          .doc(widget.edata.id)
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
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions: Row(
          children: [
            buildPop(
              list: atActnlist(kardType: widget.kardType),
              icon: Clarity.ellipsis_vertical_line,
              onTap: (value) async {
                switch (value) {
                  case atActnCrt:
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
                    break;
                  case atActnSelAll:
                    selectAll();
                    break;
                  case atActnDel:
                    delSelect();
                    break;
                  case atActnDwn:
                    downCards();
                    break;
                  case atActnImprtFile:
                    importFile();
                    break;
                  case atActnImprtCont:
                    showSelectCard();
                    // showImportContributor();
                    break;
                  default:
                }
              },
            ),
            appBarActionButton(
              icon: Icons.bar_chart,
              onTap: () {
                showQuickStats();
              },
            ),
            const SizedBox(width: psm),
            appBarActionButton(
              icon: Icons.search,
              onTap: () {
                showSearch(
                  context: context,
                  delegate: DhaSearchDelegate(
                    edata: widget.edata,
                    kardType: widget.kardType,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
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
          const SizedBox(height: psm * 0.5),
          _buildKardFilterChips(),
          _buildStatusFilterChips(),
          const SizedBox(height: psm * 0.5),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(0),
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

  // Build status filter chips
  Widget _buildStatusFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: psm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            _filters.map((filter) {
              bool isSelected = _attendanceFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  showCheckmark: false,
                  shape: filShape(),
                  onSelected: (selected) {
                    setState(() {
                      _attendanceFilter = filter;
                    });
                    _loadAttendees();
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildKardFilterChips() {
    if (lcrds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: psm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // All cards filter option
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: const Text("All Cards"),
              selected: _selectedKardFilter == null,
              showCheckmark: false,
              shape: filShape(),
              onSelected: (selected) {
                setState(() {
                  _selectedKardFilter = null;
                });
                _loadAttendees();
              },
            ),
          ),
          // Individual card filters
          ...lcrds.map((kard) {
            bool isSelected = _selectedKardFilter == kard.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(kard.type),
                selected: isSelected,
                showCheckmark: false,
                shape: filShape(),
                onSelected: (selected) {
                  setState(() {
                    _selectedKardFilter = selected ? kard.id : null;
                  });
                  _loadAttendees();
                },
              ),
            );
          }).toList(),
        ],
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
        margin: EdgeInsets.only(left: psm, right: psm, bottom: psm * 0.75),
        decoration: BoxDecoration(
          gradient: lqassgrad,
          border:
              !hasKey
                  ? lqassbdr
                  : Border.all(color: Colors.redAccent, width: bdrWidthGen),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(psm),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                children: [
                  // first child
                  Stack(
                    children: [
                      Hero(
                        tag: "avatar-${attendee.id}",
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              size: 28,
                              Icons.account_circle,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      if (messageCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                messageCount > 99 ? "99+" : "$messageCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // second child
                  const SizedBox(width: psm),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fullname,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fsm + 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.event, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    crdnm,
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                // const SizedBox(width: psm * 2),
                                TextButton(
                                  onPressed: () {
                                    var vcrd =
                                        attendee.cards[widget.kardType.name];
                                    if (vcrd != null) {
                                      AttributeCard attrCrd =
                                          AttributeCard.fromMap(map: vcrd);
                                      try {
                                        launchUrl(Uri.parse(attrCrd.url ?? ""));
                                      } catch (e) {
                                        showToast(isGood: false, msg: "$e");
                                      }
                                    } else {
                                      showToast(
                                        isGood: false,
                                        msg: "Unable to View",
                                      );
                                    }
                                  },
                                  child: Icon(
                                    Clarity.eye_show_line,
                                    size: icnmd,
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                Icon(Clarity.mobile_phone_line, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  attendee.phone,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: psm * 2),
                                Transform.scale(
                                  scale: 0.75,
                                  child: IconButton.outlined(
                                    onPressed: () {
                                      callNumber(attendee.phone);
                                    },
                                    icon: const Icon(Icons.call, size: icnsm),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: IconButton.outlined(
                                    onPressed: () async {
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
                                    icon: const Icon(Icons.edit, size: icnsm),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: psm * 0.5),
                      ],
                    ),
                  ),
                ],
              ),

              _buildAttendanceControls(attendee),
            ],
          ),
        ),
      ),
    );
  }

  // Build attendance controls
  Widget _buildAttendanceControls(Attendee attendee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        border: lqassbdr,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusButton(
            attendee,
            "Confirmed",
            Icons.check_circle,
            Colors.green,
            attendee.attendanceStatus == "Confirmed",
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            attendee,
            "Not Confirmed",
            Icons.schedule,
            Colors.grey,
            attendee.attendanceStatus == "Not Confirmed" ||
                attendee.attendanceStatus == null,
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            attendee,
            "Declined",
            Icons.cancel,
            Colors.red,
            attendee.attendanceStatus == "Declined",
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            attendee,
            "Call Made",
            Icons.call_made,
            Colors.teal,
            attendee.attendanceStatus == "Call Made",
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
    return InkWell(
      onTap: () {
        // Vibrate for haptic feedback
        HapticFeedback.mediumImpact();
        _updateAttendanceStatus(attendee, status);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : color),
            if (isActive) const SizedBox(width: 4),
            if (isActive)
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
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

  downCards() async {
    if (selectList.isEmpty) {
      showToast(isGood: false, msg: "No attendee(s) selected");
      return;
    }
    List<Attendee> lList = selectList;
    await StorageService.fetchFile(
      kardtype: widget.kardType,
      atList: lList,
      fdbck: (p0) {
        showToast(isGood: true, msg: p0);
      },
    );
  }

  delSelect() async {
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
            child: ImportContributor(kard: kard, evId: widget.edata.id ?? ""),
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
                              eId: widget.edata.id ?? "",
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
