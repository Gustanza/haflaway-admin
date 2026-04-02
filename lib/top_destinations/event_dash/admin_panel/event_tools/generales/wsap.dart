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
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
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
import 'dart:ui';

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
  bool hasMore = true;
  bool isLoading = false;
  int pageSize = atsPageSize;
  List<Attendee> selectList = [];
  List<Attendee> attendeeList = [];
  String selStatus = shtates.keys.first;
  String selChannel = shannnels.keys.first;
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  ScrollController _scrollController = ScrollController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAttendees();
    _scrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMore) {
        _loadMoreAttendees();
      }
    }
  }

  _loadAttendees() async {
    try {
      safeState(() {
        hasMore = true;
        isLoading = true;
        selectList.clear();
      });
      var snapshot =
          await firestore
              .collection(ecol)
              .doc(widget.event.id)
              .collection(atcol)
              .where(
                "messageIndexes",
                arrayContains:
                    "${selChannel}_${widget.campaignId}_${selStatus}",
              )
              .orderBy("createdAt", descending: true)
              .limit(pageSize)
              .get();
      var docs = snapshot.docs;
      if (docs.isEmpty) {
        return safeState(() {
          hasMore = false;
          isLoading = false;
          attendeeList = [];
        });
      }
      lastDocument = docs.last;
      attendeeList =
          docs.map<Attendee>((e) {
            return Attendee.fromMap(e.id, e.data());
          }).toList();
      safeState(() {
        hasMore = true;
        isLoading = false;
      });
    } catch (e) {
      safeState(() {
        hasMore = true;
        isLoading = false;
      });
    }
  }

  _loadMoreAttendees() async {
    try {
      safeState(() {
        hasMore = true;
        isLoading = true;
      });
      var snapshot =
          await firestore
              .collection(ecol)
              .doc(widget.event.id)
              .collection(atcol)
              .where(
                "messageIndexes",
                arrayContains:
                    "${selChannel}_${widget.campaignId}_${selStatus}",
              )
              .orderBy("createdAt", descending: true)
              .startAfterDocument(lastDocument!)
              .limit(pageSize)
              .get();
      var docs = snapshot.docs;
      if (docs.isEmpty) {
        return safeState(() {
          hasMore = false;
          isLoading = false;
        });
      }
      lastDocument = docs.last;
      List<Attendee> tmpList =
          docs.map<Attendee>((e) {
            return Attendee.fromMap(e.id, e.data());
          }).toList();
      attendeeList.addAll(tmpList);
      safeState(() {
        hasMore = true;
        isLoading = false;
      });
    } catch (e) {
      safeState(() {
        hasMore = true;
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
          bool? didDispatch = await Navigator.of(context).push(
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
          // debugPrint("Abjectory: $didDispatch");
          if (didDispatch ?? false) {
            stallAndRefresh();
          }
        },
        actionStr2: "Sitisha",
        onTap2: () {
          popper();
        },
      );
    } else {
      bool? didDispatch = await Navigator.of(context).push(
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
      // debugPrint("Abjectory: $didDispatch");
      if (didDispatch ?? false) {
        stallAndRefresh();
      }
    }
  }

  stallAndRefresh() async {
    // Clear selections immediately
    selectList.clear();
    safeState(() {});

    // Show the beautiful loading dialog
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return _RefreshLoadingDialog(
          onRefreshComplete: () async {
            // Actually load the refreshed data (already waited 10 seconds)
            await _loadAttendees();
            // Close dialog after completion
            if (mounted && Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        // color: Colors.red,
        margin: const EdgeInsets.only(bottom: psm),
        padding: EdgeInsets.symmetric(horizontal: psm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (selChannel == shannnels.keys.first)
              FloatingActionButton(
                // mini: true,
                heroTag: "mini",
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(bmd * 10),
                  side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
                ),
                foregroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(psm * 0.5),
                  child: Brand(Brands.messages),
                ),
                onPressed: () async {
                  pushToSend(isWhatsApp: false, prefix: "sms");
                },
              ),
            // const SizedBox(width: spaceTiles * 0.5),
            if (selChannel == shannnels.keys.last)
              FloatingActionButton(
                heroTag: "major",
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(bmd * 10),
                  side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
                ),
                foregroundColor: Colors.white,
                child: Brand(Brands.whatsapp),
                onPressed: () async {
                  pushToSend(isWhatsApp: true, prefix: "whatsapp");
                },
              ),
          ],
        ),
      ),
      appBar: appBar(
        title:
            selectList.isEmpty
                ? "Ratibu Mialiko"
                : "Chaguzi: ${selectList.length}",
        leading: buildActionButton(
          icon: selectList.isEmpty ? Icons.arrow_back : Icons.close,
          onTap: () {
            if (selectList.isEmpty) {
              popper();
            } else {
              safeState(() {
                selectList.clear();
              });
            }
          },
        ),
        actions: Row(
          children: [
            if (selectList.isEmpty)
              IconButton(
                onPressed: () {
                  _loadAttendees();
                  showToast(isGood: true, msg: "Inahuisha Data");
                },
                icon: Icon(Icons.refresh),
              ),
            if (selectList.isEmpty)
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
            if (selectList.isNotEmpty)
              TextButton(
                onPressed: () {
                  if (selectList.length < attendeeList.length) {
                    selectList = List.from(attendeeList);
                  } else {
                    selectList = [];
                  }
                  safeState(() {});
                },
                child: Text(
                  selectList.length < attendeeList.length
                      ? "Chagua Zote"
                      : "Ondoa Zote",
                ),
              ),
          ],
        ),
      ),
      body: Ccafold(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadAttendees();
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: spaceTiles,
                  right: spaceTiles,
                  top: spaceTiles,
                ),
                child: Row(
                  children: [
                    buildDropDwn(
                      getSenderChannels(campaignId: widget.campaignId),
                      (value) {
                        safeState(() {
                          selChannel = value;
                          _loadAttendees();
                        });
                      },
                    ),
                    const SizedBox(width: spaceTiles),
                    buildDropDwn(shtates, (value) {
                      selStatus = value;
                      _loadAttendees();
                    }),
                  ],
                ),
              ),
              if (attendeeList.isEmpty && isLoading)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(spaceTiles),
                    child: buildLoader(),
                  ),
                ),
              if (attendeeList.isEmpty && !isLoading)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(spaceTiles),
                    child: buildEmptyState(),
                  ),
                ),
              if (attendeeList.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(spaceTiles),
                    child: buildMialiko(attendeesList: attendeeList),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  buildMialiko({required List<Attendee> attendeesList}) {
    return ListView.builder(
      itemCount: attendeesList.length + 1,
      controller: _scrollController,
      itemBuilder: (context, indx) {
        if (indx == attendeesList.length) {
          if (isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CupertinoActivityIndicator()),
            );
          } else if (!hasMore && attendeesList.isNotEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "Hakuna Data",
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
      },
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
}

// Beautiful animated refresh loading dialog
class _RefreshLoadingDialog extends StatefulWidget {
  final Future<void> Function() onRefreshComplete;

  const _RefreshLoadingDialog({required this.onRefreshComplete});

  @override
  State<_RefreshLoadingDialog> createState() => _RefreshLoadingDialogState();
}

class _RefreshLoadingDialogState extends State<_RefreshLoadingDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _progressController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  bool _isComplete = false;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the icon
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // Rotation animation
    _rotateController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Progress animation
    _progressController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );

    // Scale animation for success
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start the refresh process
    _startRefresh();
  }

  void _startRefresh() async {
    // Start progress animation
    _progressController.forward();

    // Countdown
    for (int i = 10; i > 0; i--) {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown = i - 1;
        });
      }
    }

    // Complete the refresh
    if (mounted) {
      setState(() {
        _isComplete = true;
      });

      // Animate success
      _scaleController.forward();

      // Wait a moment to show success
      await Future.delayed(Duration(milliseconds: 800));

      // Call the refresh completion callback
      await widget.onRefreshComplete();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _progressController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: glassDialog(
        child: Container(
          padding: EdgeInsets.all(psm * 2),
          decoration: BoxDecoration(
            gradient: secscagrad,
            borderRadius: BorderRadius.circular(bmd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon Container
              AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseAnimation,
                  _rotateAnimation,
                  _scaleAnimation,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        _isComplete
                            ? _scaleAnimation.value
                            : _pulseAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            _isComplete
                                ? LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.3),
                                    Colors.greenAccent.withOpacity(0.2),
                                  ],
                                )
                                : primaryGrad,
                        border: Border.all(color: lqassbdrColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (_isComplete ? Colors.green : primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            _isComplete
                                ? Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.greenAccent,
                                  size: 50,
                                )
                                : Transform.rotate(
                                  angle: _rotateAnimation.value * 2 * 3.14159,
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    color: primaryWhite,
                                    size: 45,
                                  ),
                                ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: psm * 2),

              // Title
              Text(
                _isComplete ? "Data Imefreshwa!" : "Inahifadhi Data...",
                style: TextStyle(
                  fontSize: fsm + 4,
                  fontWeight: FontWeight.bold,
                  color: primaryWhite,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: psm),

              // Progress Bar
              if (!_isComplete) ...[
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 200 * _progressAnimation.value,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: primaryGrad,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: psm * 0.5),
                Text(
                  "Subiri sekunde $_countdown...",
                  style: TextStyle(
                    fontSize: fsm - 1,
                    color: mWhite,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                Text(
                  "Data mpya imepakuliwa kwa ufanisi",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fsm, color: mWhite),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
