import 'dart:ui';

import 'package:haflaway/components/fab.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/scancheck.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:intl/intl.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:shimmer/shimmer.dart';

class InCheck extends StatefulWidget {
  final String eId;
  final CheckPoint checkpoint;
  const InCheck({super.key, required this.checkpoint, required this.eId});

  @override
  State<InCheck> createState() => _InCheckState();
}

class _InCheckState extends State<InCheck> with TickerProviderStateMixin {
  List<Kard> acptcrds = [];
  bool isLoading = false;
  List<String> acIds = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DateFormat dformtr = DateFormat('d\'th\', MMMM, yyyy');
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    getCards();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (acptcrds.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  void _initTabController() {
    _tabController = TabController(length: acptcrds.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (acptcrds.isNotEmpty && !isLoading) {
      _initTabController();
    }

    return Scaffold(
      body:
          isLoading
              ? _buildShimmerLoader()
              : acptcrds.isEmpty
              ? _buildEmptyState()
              : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                secondaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          widget.checkpoint.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: const EdgeInsets.symmetric(horizontal: psm),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
              tabAlignment: TabAlignment.start,
              tabs: List.generate(acptcrds.length, (index) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(acptcrds[index].type),
                      const SizedBox(width: 4),
                      _buildCardTypeIcon(acptcrds[index].type),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          fabb(
            mini: true,
            heroTag: 'mini',
            child: Icon(Icons.pin),
            onPressed: () {},
          ),
          const SizedBox(height: psm),
          fabb(
            mini: false,
            heroTag: 'main',
            child: Icon(Icons.qr_code),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return Scanner(
                      acIds: acIds,
                      eId: widget.eId,
                      chckpntId: widget.checkpoint.id,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: scagrad),
        child: TabBarView(
          controller: _tabController,
          children: List.generate(acptcrds.length, (index) {
            return buildAttendees(lcrdId: acptcrds[index].id);
          }),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return Scanner(
                  acIds: acIds,
                  eId: widget.eId,
                  chckpntId: widget.checkpoint.id,
                );
              },
            ),
          );
        },
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          "Scan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCardTypeIcon(String type) {
    IconData iconData;

    // Map card types to appropriate icons
    switch (type.toLowerCase()) {
      case 'vip':
        iconData = Icons.star;
        break;
      case 'standard':
        iconData = Icons.card_membership;
        break;
      default:
        iconData = Icons.badge;
    }

    return Icon(iconData, size: 16);
  }

  Widget buildAttendees({required String lcrdId}) {
    return StreamBuilder(
      stream:
          firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(atcol)
              .where('cardId', isEqualTo: lcrdId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Attendee> atList =
              (snapshot.data as dynamic).docs.map<Attendee>((doc) {
                return Attendee.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                );
              }).toList();

          if (atList.isEmpty) {
            return _buildNoDataView("No attendees found for this card type");
          }

          // Attendees who have at least one status checked in
          List<Attendee> attendeesWithCheckins = [];

          // Total count of all checked-in statuses across all attendees
          int totalCheckedInStatuses = 0;

          for (var attendee in atList) {
            bool hasCheckedInStatus = false;
            int checkedStatusCount = 0;

            for (var status in attendee.checkinStatus) {
              bool isCheckedIn =
                  status['checkpoints'][widget.checkpoint.id] ?? false;

              if (isCheckedIn) {
                hasCheckedInStatus = true;
                checkedStatusCount++;
              }
            }

            if (hasCheckedInStatus) {
              attendeesWithCheckins.add(attendee);
            }

            totalCheckedInStatuses += checkedStatusCount;
          }

          return attendeesWithCheckins.isNotEmpty
              ? _buildAttendeesListView(
                attendeesWithCheckins,
                totalCheckedInStatuses,
              )
              : _buildNoDataView("No checked-in attendees for this card type");
        }

        if (snapshot.hasError) {
          return _buildErrorView();
        } else {
          return _buildListShimmer();
        }
      },
    );
  }

  Widget _buildAttendeesListView(
    List<Attendee> attendees,
    int totalCheckedInStatuses,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(psm),
          sliver: SliverToBoxAdapter(
            child: _buildStatsCard(attendees.length, totalCheckedInStatuses),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: psm),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              var attendee = attendees[index];
              return _buildAttendeeCard(attendee, index);
            }, childCount: attendees.length),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: psm * 2)),
      ],
    );
  }

  Widget _buildStatsCard(int attendeeCount, int totalCheckedInStatuses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryColor, Theme.of(context).primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "Check-in Stats",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Cards",
                  attendeeCount.toString(),
                  Icons.credit_card,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  "Check-ins",
                  totalCheckedInStatuses.toString(),
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeCard(Attendee attendee, int index) {
    var statuses = attendee.checkinStatus;
    int checkedInCount = getCheckedInCount(statuses);
    double progress = statuses.isEmpty ? 0 : checkedInCount / statuses.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: secondaryColor,
            primary: secondaryColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getProgressColor(progress).withOpacity(0.2),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(progress),
                        ),
                        strokeWidth: 2.5,
                      ),
                      Text(
                        checkedInCount.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(progress),
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  attendee.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "$checkedInCount/${statuses.length} slots checked in",
                      style: TextStyle(
                        color: _getProgressColor(progress),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(progress),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: List.generate(statuses.length, (index) {
                    var status = statuses[index];
                    bool isCheckedIn =
                        status['checkpoints'][widget.checkpoint.id] ?? false;

                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              isCheckedIn
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCheckedIn ? Icons.check_circle : Icons.cancel,
                          color: isCheckedIn ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        status['attendee_name'] ?? "Guest",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isCheckedIn
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCheckedIn ? "Checked in" : "Not checked",
                          style: TextStyle(
                            color: isCheckedIn ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        // ExpansionTile(
        //   initiallyExpanded: true,
        //   tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   childrenPadding: EdgeInsets.zero,
        //   leading: CircleAvatar(
        //     backgroundColor: _getProgressColor(progress).withOpacity(0.2),
        //     child: Stack(
        //       alignment: Alignment.center,
        //       children: [
        //         CircularProgressIndicator(
        //           value: progress,
        //           backgroundColor: Colors.grey.withOpacity(0.2),
        //           valueColor: AlwaysStoppedAnimation<Color>(
        //             _getProgressColor(progress),
        //           ),
        //           strokeWidth: 2.5,
        //         ),
        //         Text(
        //           checkedInCount.toString(),
        //           style: TextStyle(
        //             fontWeight: FontWeight.bold,
        //             color: _getProgressColor(progress),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        //   title: Text(
        //     attendee.fullName,
        //     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        //   ),
        //   subtitle: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       const SizedBox(height: 4),
        //       Text(
        //         "$checkedInCount/${statuses.length} slots checked in",
        //         style: TextStyle(
        //           color: _getProgressColor(progress),
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //       const SizedBox(height: 6),
        //       ClipRRect(
        //         borderRadius: BorderRadius.circular(4),
        //         child: LinearProgressIndicator(
        //           value: progress,
        //           backgroundColor: Colors.grey.withOpacity(0.2),
        //           valueColor: AlwaysStoppedAnimation<Color>(
        //             _getProgressColor(progress),
        //           ),
        //           minHeight: 4,
        //         ),
        //       ),
        //     ],
        //   ),
        //   children: [
        //     Container(
        //       decoration: BoxDecoration(
        //         color: Colors.grey[50],
        //         borderRadius: const BorderRadius.only(
        //           bottomLeft: Radius.circular(12),
        //           bottomRight: Radius.circular(12),
        //         ),
        //       ),
        //       child: Column(
        //         children: List.generate(statuses.length, (index) {
        //           var status = statuses[index];
        //           bool isCheckedIn =
        //               status['checkpoints'][widget.checkpoint.id] ?? false;

        //           return ListTile(
        //             dense: true,
        //             leading: Container(
        //               width: 32,
        //               height: 32,
        //               decoration: BoxDecoration(
        //                 color:
        //                     isCheckedIn
        //                         ? Colors.green.withOpacity(0.1)
        //                         : Colors.red.withOpacity(0.1),
        //                 borderRadius: BorderRadius.circular(8),
        //               ),
        //               child: Icon(
        //                 isCheckedIn ? Icons.check_circle : Icons.cancel,
        //                 color: isCheckedIn ? Colors.green : Colors.red,
        //                 size: 18,
        //               ),
        //             ),
        //             title: Text(
        //               status['attendee_name'] ?? "Guest",
        //               style: const TextStyle(
        //                 fontWeight: FontWeight.w500,
        //                 fontSize: 14,
        //               ),
        //             ),
        //             trailing: Container(
        //               padding: const EdgeInsets.symmetric(
        //                 horizontal: 12,
        //                 vertical: 6,
        //               ),
        //               decoration: BoxDecoration(
        //                 color:
        //                     isCheckedIn
        //                         ? Colors.green.withOpacity(0.1)
        //                         : Colors.red.withOpacity(0.1),
        //                 borderRadius: BorderRadius.circular(20),
        //               ),
        //               child: Text(
        //                 isCheckedIn ? "Checked in" : "Not checked",
        //                 style: TextStyle(
        //                   color: isCheckedIn ? Colors.green : Colors.red,
        //                   fontWeight: FontWeight.w500,
        //                   fontSize: 12,
        //                 ),
        //               ),
        //             ),
        //           );
        //         }),
        //       ),
        //     ),
        //   ],
        // ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1) {
      return Colors.green;
    } else if (progress >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Cards Available",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "There are no cards assigned to this checkpoint",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: getCards,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            "Something went wrong",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: kToolbarHeight * 2, color: Colors.white),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: psm),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: psm),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(psm),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: index == 0 ? 100 : 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  // Helper method to count checked-in statuses for an attendee
  int getCheckedInCount(List<dynamic> statuses) {
    int count = 0;
    for (var status in statuses) {
      bool isChecked = status['checkpoints'][widget.checkpoint.id] ?? false;
      if (isChecked) {
        count++;
      }
    }
    return count;
  }

  getCards() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      var csnaps =
          await firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(cardcol)
              .where(crdClrnc, arrayContains: widget.checkpoint.id)
              .get();
      var cdcs = csnaps.docs;
      if (cdcs.isNotEmpty) {
        acptcrds =
            cdcs.map<Kard>((cdc) {
              return Kard.fromMap(cdc.id, cdc.data());
            }).toList();

        acIds = cdcs.map((cdc) => cdc.id).toList();
      }
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}
