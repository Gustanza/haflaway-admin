import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/send_previewer.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/send_search_deleg.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/crtattendees.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/gen_constants.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/attendee_card.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:icons_plus/icons_plus.dart';

class InvitesIssuers extends StatefulWidget {
  final Event event;
  final KardType kardType;
  final String campaignId;
  const InvitesIssuers({
    super.key,
    required this.event,
    required this.kardType,
    required this.campaignId,
  });

  @override
  State<InvitesIssuers> createState() => _InvitesIssuersState();
}

class _InvitesIssuersState extends State<InvitesIssuers> {
  int totalDocs = 0;
  int maxpgno = 1;
  int pageSize = atsPageSize;
  List<Attendee> selectList = [];
  String selStatus = shtates.keys.first;
  String selChannel = shannnels.keys.first;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  int currentPage = 1;

  // Cursor stack: stores the last document of each page for backward navigation
  // Index 0 = last doc of page 1, Index 1 = last doc of page 2, etc.
  List<DocumentSnapshot?> pageCursors = [];

  // Current stream for the active page
  Stream<QuerySnapshot>? currentStream;

  // Track last document from current stream for forward navigation
  DocumentSnapshot? currentPageLastDoc;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _loadTotalCount();
  }

  void _initializeStream() {
    currentStream = _buildStreamForPage(currentPage);
  }

  void _loadTotalCount() async {
    try {
      var obj = firestore
          .collection(ecol)
          .doc(widget.event.id)
          .collection(atcol);
      AggregateQuerySnapshot aqs = await obj.count().get();
      if (mounted) {
        setState(() {
          totalDocs = aqs.count ?? 0;
          maxpgno = (totalDocs / pageSize).ceil();
          if (maxpgno == 0) maxpgno = 1;
        });
      }
    } catch (e) {
      debugPrint("Count error: $e");
    }
  }

  Stream<QuerySnapshot> _buildStreamForPage(int page) {
    var obj = firestore.collection(ecol).doc(widget.event.id).collection(atcol);
    Query query;
    query = obj.orderBy("createdAt", descending: true);
    // For page 1, no cursor needed
    // For page 2+, use cursor from previous page (stored at index page-2)
    if (page > 1 && pageCursors.length >= (page - 1)) {
      DocumentSnapshot? cursor = pageCursors[page - 2];
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }
    }

    return query.limit(pageSize).snapshots();
  }

  void goToNextPage(QuerySnapshot currentSnapshot) {
    if (currentSnapshot.docs.isEmpty) return;

    // Store the last document of current page in cursor stack
    DocumentSnapshot lastDoc = currentSnapshot.docs.last;

    // If we're on a new page we haven't visited, add its cursor
    if (currentPage == pageCursors.length + 1) {
      pageCursors.add(lastDoc);
    } else {
      // Update existing cursor for current page
      if (currentPage > 1) {
        pageCursors[currentPage - 1] = lastDoc;
      }
    }

    // Navigate to next page
    setState(() {
      currentPage++;
      currentStream = _buildStreamForPage(currentPage);
      currentPageLastDoc = null; // Reset for new page
    });
  }

  void goToPreviousPage() {
    if (currentPage <= 1) return;

    // Remove cursors beyond current page (cleanup)
    if (pageCursors.length >= currentPage) {
      pageCursors = pageCursors.sublist(0, currentPage - 1);
    }

    // Navigate to previous page
    setState(() {
      currentPage--;
      currentStream = _buildStreamForPage(currentPage);
      currentPageLastDoc = null; // Reset for new page
    });
  }

  pushToSend({String? prefix, bool? isWhatsApp}) async {
    if (selectList.isEmpty)
      return showToast(isGood: false, msg: "Chagua Walengwa");
    int replen =
        selectList.where((selItem) {
          var pattern = "${prefix}_${widget.campaignId}";
          List msgIndxs = selItem.messageIndexes ?? [];
          for (var msgIndx in msgIndxs) {
            if (msgIndx.startsWith(pattern)) {
              return true;
            }
          }
          return false;
        }).length;
    if (replen > 0) {
      _showNotifier(
        title: "Ujumbe Muhimu",
        subtitle:
            "Inaonyesha jumla ya waalikwa $replen washatumiwa ujumbe wa aina hii, Je unahitaji kurudia kutuma tena?",
        actionStr1: "Rudia Kutuma",
        onTap1: () async {
          popper();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return SendPreviewer(
                  isWhatsApp: isWhatsApp ?? false,
                  event: widget.event,
                  kardType: widget.kardType,
                  senderList: selectList,
                  campaignId: widget.campaignId,
                );
              },
            ),
          );
        },
        actionStr2: "Sitisha",
        onTap2: () {
          popper();
        },
      );
    } else {
      // popper();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return SendPreviewer(
              isWhatsApp: isWhatsApp ?? false,
              event: widget.event,
              kardType: widget.kardType,
              senderList: selectList,
              campaignId: widget.campaignId,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: currentStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return Container(
              // color: Colors.red,
              margin: const EdgeInsets.only(bottom: psm * 4.25),
              padding: EdgeInsets.symmetric(horizontal: psm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: "mini",
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(bmd * 10),
                      side: BorderSide(
                        color: lqassbdrColor,
                        width: bdrWidthGen,
                      ),
                    ),
                    foregroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(psm * 0.5),
                      child: Brand(Brands.wechat),
                    ),
                    onPressed: () async {
                      pushToSend(isWhatsApp: false, prefix: "sms");
                    },
                  ),
                  // const SizedBox(width: spaceTiles * 0.5),
                  FloatingActionButton(
                    heroTag: "major",
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(bmd * 10),
                      side: BorderSide(
                        color: lqassbdrColor,
                        width: bdrWidthGen,
                      ),
                    ),
                    foregroundColor: Colors.white,
                    child: Brand(Brands.whatsapp),
                    onPressed: () async {
                      pushToSend(isWhatsApp: true, prefix: "whatsapp");
                    },
                  ),
                ],
              ),
            );
          }
          return SizedBox.shrink();
        },
      ),
      appBar: appBar(
        title: "Ratibu Mialiko",
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            popper();
          },
        ),
        actions: Row(
          children: [
            IconButton(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: SendSearchDelegate(
                    event: widget.event,
                    kardType: widget.kardType,
                    campaignId: widget.campaignId,
                  ),
                );
              },
              icon: Icon(Icons.search),
            ),
          ],
        ),
      ),
      body: Ccafold(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(spaceTiles),
              child: Row(
                children: [
                  buildDropDwn(shannnels, (value) {
                    safeState(() {
                      safeState(() {
                        selChannel = value;
                      });
                    });
                  }),
                  const SizedBox(width: spaceTiles),
                  buildDropDwn(shtates, (value) {
                    safeState(() {
                      selStatus = value;
                    });
                  }),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spaceTiles),
              child: StreamBuilder<QuerySnapshot>(
                stream: currentStream,
                builder: (context, snapshot) {
                  int totalCount =
                      snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Chaguzi: ${selectList.length} kati ya $totalCount",
                    ),
                    trailing: StreamBuilder<QuerySnapshot>(
                      stream: currentStream,
                      builder: (context, snapshot) {
                        int totalCount =
                            snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return TextButton(
                          onPressed: () {
                            if (selectList.length != totalCount) {
                              // Select all from current page
                              List<Attendee> currentPageAttendees =
                                  snapshot.hasData
                                      ? snapshot.data!.docs.map<Attendee>((
                                        doc,
                                      ) {
                                        return Attendee.fromMap(
                                          doc.id,
                                          doc.data() as Map<String, dynamic>,
                                        );
                                      }).toList()
                                      : [];
                              selectList = currentPageAttendees;
                            } else {
                              selectList = [];
                            }
                            safeState(() {});
                          },
                          child: Text(
                            selectList.length != totalCount
                                ? "Chagua Yote"
                                : "Ondoa Yote",
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(spaceTiles),
                child: StreamBuilder<QuerySnapshot>(
                  stream: currentStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return buildLoader();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return BuildNoDt(
                        string: "Hakuna Data",
                        isRefreshed: () async {},
                      );
                    }

                    // Store last document for forward navigation
                    QuerySnapshot querySnapshot = snapshot.data!;
                    if (querySnapshot.docs.isNotEmpty) {
                      currentPageLastDoc = querySnapshot.docs.last;
                    }

                    // Convert to Attendee list
                    List<Attendee> attendeesList =
                        querySnapshot.docs
                            .where((t) {
                              Attendee attendee = Attendee.fromMap(
                                t.id,
                                t.data() as Map<String, dynamic>,
                              );

                              if (selStatus == "unsent") {
                                var dhakey =
                                    "${selChannel}_${widget.campaignId}";
                                return attendee.messageIndexes?.every((indx) {
                                      return !indx.startsWith(dhakey);
                                    }) ??
                                    false;
                              }
                              var thkey =
                                  "${selChannel}_${widget.campaignId}_${selStatus}";
                              return attendee.messageIndexes?.contains(thkey) ??
                                  false;
                            })
                            .map<Attendee>((doc) {
                              return Attendee.fromMap(
                                doc.id,
                                doc.data() as Map<String, dynamic>,
                              );
                            })
                            .toList();

                    return buildMialiko(attendeesList: attendeesList);
                  },
                ),
              ),
            ),
            // Pagination Controls
            StreamBuilder<QuerySnapshot>(
              stream: currentStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  return buildPaginationControls(snapshot.data!);
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  buildMialiko({required List<Attendee> attendeesList}) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ...List.generate(attendeesList.length, (indx) {
          Attendee attendee = attendeesList[indx];
          var hasKey = selectList.any((test) {
            return test.id == attendee.id;
          });
          return buildAttendeeCard(
            hasKey: hasKey,
            attendee: attendee,
            kardType: widget.kardType,
            eventId: widget.event.id ?? "_",
            campaignId: widget.campaignId,
            onEdit: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return CreateAttendees(
                      event: widget.event,
                      kardType: widget.kardType,
                      attendee: attendee,
                    );
                  },
                ),
              );
            },
            onSelected: () {
              if (hasKey) {
                var tmp =
                    selectList.where((selItem) {
                      return selItem.id != attendee.id;
                    }).toList();
                selectList = tmp;
              } else {
                selectList.add(attendee);
              }
              safeState(() {});
            },
            onStatusChange: (status) {
              int index = attendeesList.indexWhere(
                (element) => element.id == attendee.id,
              );
              if (index != -1) {
                attendeesList[index].attendanceStatus = status;
              }
              safeState(() {});
            },
          );
        }),
      ],
    );
  }

  buildDropDwn(Map shanns, Function(dynamic) onSelected) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(bsm),
        child: DropdownMenu(
          width: double.maxFinite,
          showTrailingIcon: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: lqassgradBaseColor,
            border: InputBorder.none,
          ),
          initialSelection: shanns.entries.first.key,
          onSelected: onSelected,
          dropdownMenuEntries:
              shanns.entries.map<DropdownMenuEntry>((e) {
                return DropdownMenuEntry(value: e.key, label: e.value);
              }).toList(),
        ),
      ),
    );
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  _showNotifier({
    String? title,
    String? subtitle,
    String? actionStr1,
    String? actionStr2,
    Function()? onTap1,
    Function()? onTap2,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Padding(
            padding: const EdgeInsets.all(psm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(psm * 0.75),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, size: 32, color: Colors.blue),
                ),
                SizedBox(height: psm * 0.75),
                Text(
                  "$title",
                  style: TextStyle(
                    fontSize: fsm + 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(thickness: 0.25),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: psm * 0.5),
                  child: Text(
                    "$subtitle",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: fsm + 1),
                  ),
                ),
                Divider(thickness: 0.25),
                SizedBox(height: psm * 0.25),
                lqAssButton(label: "$actionStr1", onPressed: onTap1),
                if (actionStr2 != null) SizedBox(height: spaceTiles),
                if (actionStr2 != null)
                  lqAssButton(label: "$actionStr2", onPressed: onTap2),
                const SizedBox(height: psm * 0.5),
              ],
            ),
          ),
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }

  Widget buildPaginationControls(QuerySnapshot snapshot) {
    bool hasMore = snapshot.docs.length == pageSize;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: psm, vertical: psm * 0.75),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        // borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          GestureDetector(
            onTap: currentPage > 1 ? () => goToPreviousPage() : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient:
                    currentPage > 1
                        ? primaryGrad
                        : LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.2),
                          ],
                        ),
                borderRadius: BorderRadius.circular(bsm),
                border: Border.all(
                  color:
                      currentPage > 1
                          ? lqassbdrColor
                          : Colors.grey.withOpacity(0.3),
                  width: bdrWidthGen,
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color:
                    currentPage > 1
                        ? primaryWhite
                        : Colors.grey.withOpacity(0.5),
                size: 28,
              ),
            ),
          ),
          SizedBox(width: psm * 1.5),
          // Page Display
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: psm * 1.5,
              vertical: psm * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: secscagrad,
              borderRadius: BorderRadius.circular(bsm),
              border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: psm * 0.75),
                  decoration: BoxDecoration(
                    gradient: primaryGrad,
                    borderRadius: BorderRadius.circular(bxsm),
                  ),
                  child: Text(
                    "$currentPage",
                    style: TextStyle(
                      fontSize: fsm + 2,
                      color: primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  " of ",
                  style: TextStyle(
                    fontSize: fsm + 1,
                    color: mWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: psm * 0.75),
                  decoration: BoxDecoration(
                    gradient: primaryGrad,
                    borderRadius: BorderRadius.circular(bxsm),
                  ),
                  child: Text(
                    "${maxpgno}",
                    style: TextStyle(
                      fontSize: fsm + 2,
                      color: primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: psm * 1.5),
          // Next Button
          GestureDetector(
            onTap: hasMore ? () => goToNextPage(snapshot) : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient:
                    hasMore
                        ? primaryGrad
                        : LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.2),
                          ],
                        ),
                borderRadius: BorderRadius.circular(bsm),
                border: Border.all(
                  color: hasMore ? lqassbdrColor : Colors.grey.withOpacity(0.3),
                  width: bdrWidthGen,
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: hasMore ? primaryWhite : Colors.grey.withOpacity(0.5),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
