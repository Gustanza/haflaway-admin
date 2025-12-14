import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/send_previewer.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/send_search_deleg.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/crtattendees.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/gen_constants.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/components/attendee_card.dart';
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
      if ((selChannel == "sms" || selChannel == "whatsapp") &&
          selStatus == "all") {
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
    });
    try {
      attendeesList = [];
      pageSize = attendeesList.isEmpty ? atsPageSize : atStatesList.length;
      var invSnapshots = await whereQwrBuilder(getMore: false).get();
      var doks = invSnapshots.docs;
      if (doks.isEmpty) {
        safeState(() {
          isLoading = false;
          hasMore = false;
        });
        return;
      }
      lastDocument = doks.last;
      attendeesList =
          doks.map<Attendee>((item) {
            return Attendee.fromMap(item.id, item.data());
          }).toList();
      safeState(() {
        isLoading = false;
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
        });
        return;
      }
      lastDocument = doks.last;
      var list =
          doks.map<Attendee>((item) {
            return Attendee.fromMap(item.id, item.data());
          }).toList();
      attendeesList.addAll(list);
      safeState(() {
        isLoading = false;
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
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
            child: Padding(
              padding: const EdgeInsets.all(psm * 0.5),
              child: Brand(Brands.wechat),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return SendPreviewer(
                      isWhatsApp: false,
                      event: widget.event,
                      kardType: widget.kardType,
                      senderList: selectList,
                      campaignId: widget.campaignId,
                    );
                  },
                ),
              );
            },
          ),
          FloatingActionButton(
            heroTag: "major",
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(bmd * 10),
              side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
            ),
            foregroundColor: Colors.white,
            child: Brand(Brands.whatsapp),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return SendPreviewer(
                      isWhatsApp: true,
                      event: widget.event,
                      kardType: widget.kardType,
                      senderList: selectList,
                      campaignId: widget.campaignId,
                    );
                  },
                ),
              );
            },
          ),
        ],
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
                  onPressed: () {},
                  child: Text("Chagua Zote"),
                ),
              ),
              Expanded(
                child:
                    attendeesList.isEmpty && isLoading
                        ? buildLoader()
                        : attendeesList.isEmpty && !isLoading
                        ? BuildNoDt(
                          string: "No Attendees Found",
                          isRefreshed: () async {
                            await loadAttendees();
                          },
                        )
                        : buildMialiko(),
              ),
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
      child: DropdownMenu(
        width: double.maxFinite,
        showTrailingIcon: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(bsm)),
        ),
        initialSelection: shanns.entries.first.key,
        onSelected: onSelected,
        dropdownMenuEntries:
            shanns.entries.map<DropdownMenuEntry>((e) {
              return DropdownMenuEntry(value: e.key, label: e.value);
            }).toList(),
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

  popper() {
    Navigator.of(context).pop();
  }
}
