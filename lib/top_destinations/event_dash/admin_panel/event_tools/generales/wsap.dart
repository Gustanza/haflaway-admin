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
  bool hasMore = true;
  bool isLoading = false;
  int pageSize = atsPageSize;
  DocumentSnapshot? lastDocument;
  List<Attendee> selectList = [];
  List<Attendee> attendeesList = [];
  String selStatus = shtates.keys.first;
  String selChannel = shannnels.keys.first;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  ScrollController scrollController = ScrollController();
  int currentPage = 1;
  int? totalPages;
  List<DocumentSnapshot> pageDocuments = []; // Track documents for each page
  @override
  void initState() {
    super.initState();
    loadAttendees();
    // Add scroll listener for pagination
    scrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMore) {
        loadMoreAttendees();
      }
    }
  }

  whereQwrBuilder({getMore}) {
    var obj = firestore.collection(ecol).doc(widget.event.id).collection(atcol);
    if (!getMore) {
      if ((selChannel == "all") && selStatus == "all") {
        return obj.orderBy("createdAt", descending: true).limit(pageSize);
      } else {
        return obj
            .where(
              "messageIndexes",
              arrayContains: "${selChannel}_${widget.campaignId}_${selStatus}",
            )
            .orderBy("messageIndexes")
            .limit(pageSize);
      }
    } else {
      if ((selChannel == "sms" || selChannel == "whatsapp") &&
          selStatus == "all") {
        return obj
            .orderBy("createdAt", descending: true)
            .startAfterDocument(lastDocument!)
            .limit(pageSize);
      } else {
        return obj
            .where(
              "messageIndexes",
              arrayContains: "${selChannel}_${widget.campaignId}_${selStatus}",
            )
            .orderBy("messageIndexes")
            .startAfterDocument(lastDocument!)
            .limit(pageSize);
      }
    }
  }

  loadAttendees() async {
    safeState(() {
      isLoading = true;
      hasMore = true;
      currentPage = 1;
      pageDocuments = [];
    });
    try {
      attendeesList = [];
      pageSize = atsPageSize;
      var invSnapshots = await whereQwrBuilder(getMore: false).get();
      var doks = invSnapshots.docs;
      if (doks.isEmpty) {
        safeState(() {
          isLoading = false;
          hasMore = false;
          totalPages = 1;
        });
        return;
      }
      lastDocument = doks.last;
      pageDocuments = [doks.last];
      attendeesList =
          doks.map<Attendee>((item) {
            return Attendee.fromMap(item.id, item.data());
          }).toList();
      safeState(() {
        isLoading = false;
        // Estimate total pages if we got a full page
        if (doks.length == pageSize) {
          totalPages = null; // Unknown, show "?"
        } else {
          totalPages = currentPage;
        }
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
      });
    }
  }

  loadMoreAttendees() async {
    safeState(() {
      isLoading = true;
      hasMore = true;
    });
    try {
      var invSnapshots = await whereQwrBuilder(getMore: true).get();
      var doks = invSnapshots.docs;
      if (doks.isEmpty) {
        safeState(() {
          isLoading = false;
          hasMore = false;
          totalPages = currentPage; // We've reached the end
        });
        return;
      }
      lastDocument = doks.last;
      pageDocuments.add(doks.last);
      var list =
          doks.map<Attendee>((item) {
            return Attendee.fromMap(item.id, item.data());
          }).toList();
      attendeesList.addAll(list);
      safeState(() {
        isLoading = false;
        currentPage++;
        // Update total pages if we got less than pageSize
        if (doks.length < pageSize) {
          totalPages = currentPage;
        }
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
      });
    }
  }

  goToPage(int targetPage) async {
    if (targetPage < 1 || (totalPages != null && targetPage > totalPages!)) {
      return;
    }
    if (targetPage == currentPage) return;

    safeState(() {
      isLoading = true;
    });

    try {
      if (targetPage > currentPage) {
        // Go forward: load more pages until we reach target
        while (currentPage < targetPage && hasMore) {
          var invSnapshots = await whereQwrBuilder(getMore: true).get();
          var doks = invSnapshots.docs;
          if (doks.isEmpty) {
            safeState(() {
              hasMore = false;
              totalPages = currentPage;
            });
            break;
          }
          lastDocument = doks.last;
          pageDocuments.add(doks.last);
          var list =
              doks.map<Attendee>((item) {
                return Attendee.fromMap(item.id, item.data());
              }).toList();
          attendeesList.addAll(list);
          safeState(() {
            currentPage++;
            if (doks.length < pageSize) {
              totalPages = currentPage;
            }
          });
        }
      } else {
        // Go backward: reset and load up to target page
        safeState(() {
          attendeesList = [];
          currentPage = 1;
          lastDocument = null;
          pageDocuments = [];
          hasMore = true;
        });

        // Load pages sequentially up to target
        for (int page = 1; page < targetPage; page++) {
          Query query;
          if (page == 1) {
            query = whereQwrBuilder(getMore: false);
          } else {
            query = whereQwrBuilder(getMore: true);
          }
          var invSnapshots = await query.get();
          var doks = invSnapshots.docs;
          if (doks.isEmpty) {
            safeState(() {
              hasMore = false;
              totalPages = currentPage;
            });
            break;
          }
          lastDocument = doks.last;
          pageDocuments.add(doks.last);
          var list =
              doks.map<Attendee>((item) {
                return Attendee.fromMap(
                  item.id,
                  item.data() as Map<String, dynamic>,
                );
              }).toList();
          if (page == 1) {
            attendeesList = list;
          } else {
            attendeesList.addAll(list);
          }
          safeState(() {
            currentPage = page + 1;
            if (doks.length < pageSize) {
              totalPages = currentPage;
            }
          });
        }
      }
      safeState(() {
        isLoading = false;
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
      });
    }
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
          bool? rezort = await Navigator.of(context).push(
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
          if (rezort != null)
            _showNotifier(
              title: "Taarifa Muhimu",
              subtitle:
                  "Ili kupata delivery status kwa ufasaha zaidi unashauriwa kusubiri angalau dakika mbili kati ya jumbe unazotuma kisha refresh kabla ya kuendelea na zoezi lingine",
              actionStr1: "Refresh Sasa",
              onTap1: () {
                loadAttendees();
                popper();
              },
            );
        },
        actionStr2: "Sitisha",
        onTap2: () {
          popper();
        },
      );
    } else {
      popper();
      bool? rezort = await Navigator.of(context).push(
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
      if (rezort != null)
        _showNotifier(
          title: "Taarifa Muhimu",
          subtitle:
              "Ili kupata delivery status kwa ufasaha zaidi unashauriwa kusubiri angalau dakika mbili kati ya jumbe unazotuma kisha refresh kabla ya kuendelea na zoezi lingine",
          actionStr1: "Refresh Sasa",
          onTap1: () {
            loadAttendees();
            popper();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          attendeesList.isNotEmpty
              ? Container(
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
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
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
                        await pushToSend(isWhatsApp: false, prefix: "sms");
                      },
                    ),
                    // const SizedBox(width: spaceTiles * 0.5),
                    FloatingActionButton(
                      heroTag: "major",
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
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
                        await pushToSend(isWhatsApp: true, prefix: "whatsapp");
                      },
                    ),
                  ],
                ),
              )
              : null,
      appBar: appBar(
        title: "Ratibu Mialikor",
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
                loadAttendees();
              },
              icon: Icon(Icons.refresh),
            ),
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
        child: Padding(
          padding: EdgeInsets.all(spaceTiles),
          child: Column(
            children: [
              Row(
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
                    loadAttendees();
                  }),
                ],
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Chaguzi: ${selectList.length} kati ya ${attendeesList.length}",
                ),
                trailing: TextButton(
                  onPressed: () {
                    if (selectList.length != attendeesList.length) {
                      selectList = attendeesList;
                    } else {
                      selectList = [];
                    }
                    safeState(() {});
                  },
                  child: Text(
                    selectList.length != attendeesList.length
                        ? "Chagua Yote"
                        : "Ondoa Yote",
                  ),
                ),
              ),
              Expanded(
                child:
                    attendeesList.isEmpty && isLoading
                        ? buildLoader()
                        : attendeesList.isEmpty && !isLoading
                        ? BuildNoDt(
                          string: "Hakuna Data",
                          isRefreshed: () async {
                            await loadAttendees();
                          },
                        )
                        : buildMialiko(),
              ),
              // Pagination Controls
              if (attendeesList.isNotEmpty) buildPaginationControls(),
            ],
          ),
        ),
      ),
    );
  }

  buildMialiko() {
    return ListView(
      padding: EdgeInsets.zero,
      controller: scrollController,
      children: [
        ...List.generate(attendeesList.length + 1, (indx) {
          if (indx == attendeesList.length) {
            if (isLoading) {
              return const Padding(
                padding: EdgeInsets.all(psm),
                child: Center(child: CupertinoActivityIndicator(radius: psm)),
              );
            } else if (!hasMore && attendeesList.isNotEmpty) {
              return const Padding(
                padding: EdgeInsets.all(psm),
                child: Center(
                  child: Text(
                    "Hakuna Data Zaidi",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            } else {
              return const SizedBox(height: psm);
            }
          }
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
              loadAttendees();
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

  Widget buildPaginationControls() {
    return Container(
      margin: EdgeInsets.only(top: spaceTiles),
      padding: EdgeInsets.symmetric(horizontal: psm, vertical: psm * 0.75),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        borderRadius: BorderRadius.circular(bsm),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          GestureDetector(
            onTap:
                currentPage > 1 && !isLoading
                    ? () => goToPage(currentPage - 1)
                    : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient:
                    currentPage > 1 && !isLoading
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
                      currentPage > 1 && !isLoading
                          ? lqassbdrColor
                          : Colors.grey.withOpacity(0.3),
                  width: bdrWidthGen,
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color:
                    currentPage > 1 && !isLoading
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
                Text(
                  "Page ",
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
                    gradient:
                        totalPages != null
                            ? primaryGrad
                            : LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.3),
                                Colors.orange.withOpacity(0.2),
                              ],
                            ),
                    borderRadius: BorderRadius.circular(bxsm),
                  ),
                  child: Text(
                    totalPages != null ? "$totalPages" : "?",
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
            onTap:
                hasMore && !isLoading ? () => goToPage(currentPage + 1) : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient:
                    hasMore && !isLoading
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
                      hasMore && !isLoading
                          ? lqassbdrColor
                          : Colors.grey.withOpacity(0.3),
                  width: bdrWidthGen,
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color:
                    hasMore && !isLoading
                        ? primaryWhite
                        : Colors.grey.withOpacity(0.5),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
