import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
  TextEditingController channelCon = TextEditingController();
  TextEditingController statusCon = TextEditingController();
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  ScrollController _scrollController = ScrollController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    channelCon.text = shannnels[selChannel] ?? "";
    statusCon.text = shtates[selStatus] ?? "";
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
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

            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _loadAttendees();
                      },
                      color: _T.lime,
                      backgroundColor: _T.card,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _buildPremiumField(
                                  controller: channelCon,
                                  label: 'CHANNEL',
                                  hint: 'Select Channel',
                                  onTap: showSelectChannel,
                                ),
                                const SizedBox(width: 12),
                                _buildPremiumField(
                                  controller: statusCon,
                                  label: 'STATUS',
                                  hint: 'Select Status',
                                  onTap: showSelectStatus,
                                ),
                              ],
                            ),
                          ),
                          if (attendeeList.isEmpty && isLoading)
                            Expanded(
                              child: Center(
                                child: CupertinoActivityIndicator(
                                  color: _T.lime,
                                ),
                              ),
                            )
                          else if (attendeeList.isEmpty && !isLoading)
                            Expanded(child: buildEmptyState())
                          else
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: buildMialiko(
                                  attendeesList: attendeeList,
                                ),
                              ),
                            ),
                        ],
                      ),
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

  Widget _topBar() {
    bool isSel = selectList.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (isSel) {
                safeState(() => selectList.clear());
              } else {
                popper();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSel
                      ? Icons.close_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  color: _T.lime,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isSel ? "Selections: ${selectList.length}" : "Ratibu Mialiko",
                  style: _T.f(size: 15, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (isSel)
            GestureDetector(
              onTap: () {
                if (selectList.length < attendeeList.length) {
                  selectList = List.from(attendeeList);
                } else {
                  selectList.clear();
                }
                safeState(() {});
              },
              child: Text(
                selectList.length < attendeeList.length
                    ? "Select All"
                    : "Remove All",
                style: _T.f(size: 14, color: _T.lime, weight: FontWeight.w600),
              ),
            )
          else ...[
            IconButton(
              onPressed: () {
                _loadAttendees();
                showToast(isGood: true, msg: "Refreshing...");
              },
              icon: const Icon(Icons.refresh_rounded, color: _T.lime, size: 22),
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
              icon: const Icon(Icons.search_rounded, color: _T.lime, size: 22),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _T.f(size: 10, weight: FontWeight.w700, color: _T.grey2),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? hint : controller.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _T.f(
                        size: 13,
                        color: controller.text.isEmpty ? _T.grey3 : _T.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _T.lime,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  showSelectChannel() {
    Map channels = getSenderChannels(campaignId: widget.campaignId);
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return modalBtmSheet(
          bdrdm: 28,
          child: _buildSelectionSheet(
            title: "Select Channel",
            items: channels,
            currentValue: selChannel,
            onSelected: (val) {
              safeState(() {
                selChannel = val;
                channelCon.text = channels[val] ?? "";
                _loadAttendees();
              });
            },
          ),
        );
      },
    );
  }

  showSelectStatus() {
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return modalBtmSheet(
          bdrdm: 28,
          child: _buildSelectionSheet(
            title: "Select Status",
            items: shtates,
            currentValue: selStatus,
            onSelected: (val) {
              safeState(() {
                selStatus = val;
                statusCon.text = shtates[val] ?? "";
                _loadAttendees();
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectionSheet({
    required String title,
    required Map items,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: _T.grey2.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        _T.f(size: 20, weight: FontWeight.w800).toText(title),
        const SizedBox(height: 16),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children:
                items.entries.map<Widget>((e) {
                  bool isSel = currentValue == e.key;
                  return GestureDetector(
                    onTap: () {
                      onSelected(e.key);
                      popper();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isSel
                                ? _T.lime.withOpacity(0.1)
                                : _T.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSel ? _T.lime : _T.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _T
                              .f(
                                size: 16,
                                color: isSel ? _T.lime : _T.white,
                                weight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                              )
                              .toText(e.value),
                          if (isSel)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _T.lime,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens (Apple / Obsidian Hybrid)
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF0A0A0A);
  static const card = Color(0xFF141414);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);
  static const grey2 = Color(0xFF555555);
  static const grey3 = Color(0xFF333333);

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

extension _TText on TextStyle {
  Widget toText(String data) => Text(data, style: this);
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
