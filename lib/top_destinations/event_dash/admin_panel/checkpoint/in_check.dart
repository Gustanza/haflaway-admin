import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/scancheck.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:intl/intl.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';

class InCheckWrapper extends StatelessWidget {
  final String eId;
  final CheckPoint checkpoint;
  const InCheckWrapper({
    super.key,
    required this.checkpoint,
    required this.eId,
  });

  @override
  Widget build(BuildContext context) {
    List<Kard> acptcrds = [];
    List acIds = [];
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection(ecol)
              .doc(eId)
              .collection(cardcol)
              .where(crdClrnc, arrayContains: checkpoint.id)
              .snapshots(),
      builder: (context, snapshots) {
        if (snapshots.hasData) {
          var cdcs = (snapshots.data as dynamic).docs;
          if (cdcs.isNotEmpty) {
            acptcrds =
                cdcs.map<Kard>((cdc) {
                  return Kard.fromMap(cdc.id, cdc.data());
                }).toList();
            if (acptcrds.isEmpty) {
              return buildGlassEmptyState();
            }
            acIds = cdcs.map((cdc) => cdc.id).toList();
          } else {
            return buildGlassEmptyState();
          }
          return InCheck(
            eId: eId,
            checkpoint: checkpoint,
            acptcrds: acptcrds,
            acIds: acIds,
          );
        } else if (snapshots.hasError) {
          return buildErrorState();
        } else {
          return buildShimmerLoader();
        }
      },
    );
  }
}

class InCheck extends StatefulWidget {
  final String eId;
  final CheckPoint checkpoint;
  final List<Kard> acptcrds;
  final List acIds;
  const InCheck({
    super.key,
    required this.checkpoint,
    required this.eId,
    this.acptcrds = const [],
    this.acIds = const [],
  });

  @override
  State<InCheck> createState() => _InCheckState();
}

class _InCheckState extends State<InCheck> with TickerProviderStateMixin {
  bool isLoading = false;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DateFormat dformtr = DateFormat('d\'th\', MMMM, yyyy');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.acptcrds.length,
      child: Scaffold(
        backgroundColor: scaback,
        appBar: appBar(
          title: "Checkins",
          leading: buildActionButton(
            icon: Icons.arrow_back,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          actions: buildActionButton(icon: Icons.bar_chart, onTap: () {}),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildFloatingBtn(
              mini: true,
              heroTag: "mini",
              iconData: Icons.pin,
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return PinPutty(
                      eId: widget.eId,
                      chckpntId: widget.checkpoint.id,
                    );
                  },
                );
              },
            ),
            SizedBox(height: psm * 0.5),
            buildFloatingBtn(
              mini: false,
              heroTag: "major",
              iconData: Icons.qr_code,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return Scanner(
                        acIds: widget.acIds,
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
        body: Ccafold(
          child: Column(
            children: [
              TabBar(
                dividerHeight: 0.00001,
                isScrollable: true,
                labelColor: Colors.white,
                indicatorColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                ),
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                tabs: List.generate(widget.acptcrds.length, (index) {
                  return Tab(child: Text(widget.acptcrds[index].type));
                }),
              ),
              Expanded(
                child: TabBarView(
                  children: List.generate(widget.acptcrds.length, (index) {
                    return buildAttendees(lcrdId: widget.acptcrds[index].id);
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAttendees({required String lcrdId}) {
    return StreamBuilder(
      stream:
          firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(atcol)
              .where('cards.invitation.templateCardId', isEqualTo: lcrdId)
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
            return buildNoDataView("No attendees found for this card type");
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
              : buildNoDataView("No checked-in attendees for this card type");
        }

        if (snapshot.hasError) {
          return buildErrorState();
        } else {
          return buildListShimmer();
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
        gradient: lqassgrad,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lqassbdrColor, width: 0.5),
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
        gradient: lqassgrad,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lqassbdrColor, width: 0.5),
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
                gradient: lqassgrad,
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
}
