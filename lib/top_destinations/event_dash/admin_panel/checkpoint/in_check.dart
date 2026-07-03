import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/services/checkpoint_db.dart';
import 'package:haflaway/services/checkpoint_sync.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/components/searchAtt.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart'
    show PinPutty;
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/scancheck.dart';
import 'package:haflaway/utils/dimensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF111114);
  static const card = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const sep = Color(0xFF2C2C2E);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const lbl1 = Color(0xFFEEEEF0);
  static const lbl2 = Color(0xFFAEAEB2);
  static const lbl3 = Color(0xFF8E8E93);
  static const lbl4 = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// InCheckWrapper  —  resolves accepted card types before entering InCheck
// ─────────────────────────────────────────────────────────────────────────────

class InCheckWrapper extends StatelessWidget {
  final String eId;
  final CheckPoint checkpoint;
  const InCheckWrapper({
    super.key,
    required this.checkpoint,
    required this.eId,
  });

  Widget _shell(BuildContext context, Widget body) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -80,
              child: _GusOrb(size: 280, color: _T.lime, opacity: 0.10),
            ),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _T.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _T.sep, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _T.lime,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Back',
                                style: _T.f(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: _T.lbl1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: psm),
                Expanded(child: body),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
              return _shell(context, const _EmptyCheckpoints());
            }
            acIds = cdcs.map((cdc) => cdc.id).toList();
          } else {
            return _shell(context, const _EmptyCheckpoints());
          }
          return InCheck(
            eId: eId,
            checkpoint: checkpoint,
            acptcrds: acptcrds,
            acIds: acIds,
          );
        } else if (snapshots.hasError) {
          return _shell(context, const _ErrorState());
        } else {
          return _shell(
            context,
            const Center(child: CupertinoActivityIndicator(color: _T.lime)),
          );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InCheck
// ─────────────────────────────────────────────────────────────────────────────

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
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final CheckpointSyncService _sync;
  bool _checkingLocal = true;
  bool _needsDownload = false;

  @override
  void initState() {
    super.initState();
    _sync = CheckpointSyncService(eId: widget.eId);
    _sync.addListener(_onSyncChanged);
    _initSync();
  }

  Future<void> _initSync() async {
    final count = await CheckpointLocalDB.instance.count(widget.eId);
    if (!mounted) return;
    if (count == 0) {
      setState(() {
        _checkingLocal = false;
        _needsDownload = true;
      });
    } else {
      setState(() {
        _checkingLocal = false;
        _needsDownload = false;
      });
      _sync.startAutoSync();
    }
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startDownload() async {
    final ok = await _sync.downloadAll();
    if (!mounted) return;
    if (ok) {
      setState(() => _needsDownload = false);
      _sync.startAutoSync();
    }
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    _sync.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DefaultTabController(
        length: widget.acptcrds.length,
        child: Scaffold(
          backgroundColor: _T.bg,
          body: Stack(
            children: [
              const Positioned(
                top: -80,
                right: -80,
                child: _GusOrb(size: 280, color: _T.lime, opacity: 0.10),
              ),
              const Positioned(
                bottom: -40,
                left: -80,
                child: _GusOrb(size: 220, color: _T.lime, opacity: 0.06),
              ),

              // Main column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_topBar(), _titleBlock()],
                    ),
                  ),
                  _tabHeader(),
                  Expanded(
                    child: TabBarView(
                      children: List.generate(widget.acptcrds.length, (i) {
                        return _buildAttendees(lcrdId: widget.acptcrds[i].id);
                      }),
                    ),
                  ),
                ],
              ),

              // FABs — bottom-right, clear of system bar
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PIN entry — secondary
                    GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder:
                              (context) => PinPutty(
                                eId: widget.eId,
                                chckpntId: widget.checkpoint.id,
                              ),
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _T.card2,
                          shape: BoxShape.circle,
                          border: Border.all(color: _T.sep, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pin_rounded,
                          color: _T.lbl2,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // QR scanner — primary
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => Scanner(
                                  acIds: widget.acIds,
                                  eId: widget.eId,
                                  chckpntId: widget.checkpoint.id,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _T.lime,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _T.lime.withValues(alpha: 0.40),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Download gate — blocks interaction until data is local
              if (_checkingLocal || _needsDownload)
                _DownloadGate(
                  isChecking: _checkingLocal,
                  sync: _sync,
                  onDownload: _startDownload,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _T.lime,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Back',
                    style: _T.f(
                      size: 13,
                      weight: FontWeight.w500,
                      color: _T.lbl1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Sync status chip
          if (!_needsDownload && !_checkingLocal) ...[
            _SyncChip(sync: _sync),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () {
              showSearch(
                context: context,
                delegate: CheckPnSearchDelegate(
                  eId: widget.eId,
                  kardType: KardType.invitation,
                  checkpnId: widget.checkpoint.id,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_rounded, color: _T.lime, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Search',
                    style: _T.f(
                      size: 13,
                      weight: FontWeight.w500,
                      color: _T.lbl1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Title block ───────────────────────────────────────────────────────────

  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check-ins',
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          if (widget.checkpoint.name.isNotEmpty)
            Text(widget.checkpoint.name, style: _T.f(size: 14, color: _T.lbl3)),
        ],
      ),
    );
  }

  // ── Tab header ────────────────────────────────────────────────────────────

  Widget _tabHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _T.sep, width: 0.8)),
      ),
      child: TabBar(
        dividerHeight: 0,
        isScrollable: true,
        labelColor: _T.lime,
        unselectedLabelColor: _T.lbl3,
        indicatorColor: _T.lime,
        indicatorWeight: 2.5,
        labelStyle: _T.f(size: 13, weight: FontWeight.w600, color: _T.lime),
        unselectedLabelStyle: _T.f(size: 13, color: _T.lbl3),
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: List.generate(widget.acptcrds.length, (i) {
          return Tab(child: Text(widget.acptcrds[i].type));
        }),
      ),
    );
  }

  // ── Attendees tab content ─────────────────────────────────────────────────

  Widget _buildAttendees({required String lcrdId}) {
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
            return _buildNoData("No attendees found for this card type");
          }

          List<Attendee> attendeesWithCheckins = [];
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

            if (hasCheckedInStatus) attendeesWithCheckins.add(attendee);
            totalCheckedInStatuses += checkedStatusCount;
          }

          return attendeesWithCheckins.isNotEmpty
              ? _buildAttendeesListView(
                attendeesWithCheckins,
                totalCheckedInStatuses,
              )
              : _buildNoData("No checked-in attendees for this card type");
        }

        if (snapshot.hasError) return const _ErrorState();
        return const Center(child: CupertinoActivityIndicator(color: _T.lime));
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          sliver: SliverToBoxAdapter(
            child: _buildStatsCard(attendees.length, totalCheckedInStatuses),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildAttendeeCard(attendees[i]),
              childCount: attendees.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────

  Widget _buildStatsCard(int attendeeCount, int totalCheckedInStatuses) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _T.lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: _T.lime,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'CHECK-IN STATS',
                style: _T.f(
                  size: 11,
                  weight: FontWeight.w700,
                  color: _T.lbl3,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  'Cards',
                  attendeeCount.toString(),
                  Icons.credit_card_outlined,
                ),
              ),
              Container(width: 1, height: 44, color: _T.sep),
              Expanded(
                child: _statItem(
                  'Check-ins',
                  totalCheckedInStatuses.toString(),
                  Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _T.lbl3, size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          style: _T.f(
            size: 30,
            weight: FontWeight.w800,
            color: _T.white,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: _T.f(size: 12, color: _T.lbl3)),
      ],
    );
  }

  // ── Attendee card ─────────────────────────────────────────────────────────

  Widget _buildAttendeeCard(Attendee attendee) {
    final statuses = attendee.checkinStatus;
    final checkedInCount = getCheckedInCount(statuses);
    final progress = statuses.isEmpty ? 0.0 : checkedInCount / statuses.length;
    final statusColor = _getProgressColor(progress);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: _T.sep,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        strokeWidth: 3,
                      ),
                      Text(
                        checkedInCount.toString(),
                        style: _T.f(
                          size: 13,
                          weight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendee.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _T.f(
                          size: 15,
                          weight: FontWeight.w600,
                          color: _T.lbl1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$checkedInCount/${statuses.length} slots checked in',
                        style: _T.f(size: 12, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status rows
          if (statuses.isNotEmpty) ...[
            const Divider(height: 1, thickness: 0.8, color: _T.sep),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: Container(
                color: _T.card2,
                child: Column(
                  children: List.generate(statuses.length, (i) {
                    final status = statuses[i];
                    final isIn =
                        status['checkpoints'][widget.checkpoint.id] ?? false;
                    return _statusRow(
                      name: status['attendee_name'] ?? 'Guest',
                      isCheckedIn: isIn,
                      isLast: i == statuses.length - 1,
                    );
                  }),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow({
    required String name,
    required bool isCheckedIn,
    required bool isLast,
  }) {
    final rowColor =
        isCheckedIn
            ? const Color(0xFF30D158) // system green
            : const Color(0xFFFF453A); // system red

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rowColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCheckedIn
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: rowColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.f(
                    size: 13,
                    weight: FontWeight.w500,
                    color: _T.lbl1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: rowColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCheckedIn ? 'Checked in' : 'Not checked',
                  style: _T.f(
                    size: 11,
                    weight: FontWeight.w600,
                    color: rowColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 0.5,
            color: _T.sep,
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }

  // ── No-data inline state ──────────────────────────────────────────────────

  Widget _buildNoData(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: const Icon(
              Icons.person_off_outlined,
              size: 28,
              color: _T.lbl4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: _T.f(size: 14, color: _T.lbl3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _getProgressColor(double progress) {
    if (progress >= 1) return const Color(0xFF30D158);
    if (progress >= 0.5) return const Color(0xFFFF9F0A);
    return const Color(0xFFFF453A);
  }

  int getCheckedInCount(List<dynamic> statuses) {
    int count = 0;
    for (var status in statuses) {
      if (status['checkpoints'][widget.checkpoint.id] ?? false) count++;
    }
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync status chip
// ─────────────────────────────────────────────────────────────────────────────

class _SyncChip extends StatelessWidget {
  final CheckpointSyncService sync;
  const _SyncChip({required this.sync});

  @override
  Widget build(BuildContext context) {
    final Color dot;
    final String label;

    switch (sync.status) {
      case SyncStatus.syncing:
        dot = _T.lime;
        label = 'Syncing…';
      case SyncStatus.synced:
        final ago = sync.lastSynced != null
            ? DateTime.now().difference(sync.lastSynced!).inSeconds
            : 0;
        dot = const Color(0xFF30D158);
        label = ago < 5 ? 'Synced' : '${ago}s ago';
      case SyncStatus.error:
        dot = const Color(0xFFFF453A);
        label = 'Offline';
      default:
        dot = _T.lbl4;
        label = 'Sync';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sync.status == SyncStatus.syncing)
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(dot),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dot.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 5),
          Text(label, style: _T.f(size: 11, weight: FontWeight.w500, color: _T.lbl2)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Download gate overlay
// ─────────────────────────────────────────────────────────────────────────────

class _DownloadGate extends StatelessWidget {
  final bool isChecking;
  final CheckpointSyncService sync;
  final VoidCallback onDownload;

  const _DownloadGate({
    required this.isChecking,
    required this.sync,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = sync.status == SyncStatus.downloading;
    final isError = sync.status == SyncStatus.error;

    return Positioned.fill(
      child: Container(
        color: _T.bg.withValues(alpha: 0.96),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _T.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _T.lime.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: isChecking || isDownloading
                      ? const Center(
                          child: CupertinoActivityIndicator(color: _T.lime),
                        )
                      : const Icon(
                          Icons.download_rounded,
                          color: _T.lime,
                          size: 28,
                        ),
                ),
                const SizedBox(height: 20),

                if (isChecking) ...[
                  Text(
                    'Checking local data…',
                    style: _T.f(size: 16, weight: FontWeight.w600, color: _T.lbl1),
                  ),
                ] else if (isDownloading) ...[
                  Text(
                    'Downloading attendees',
                    style: _T.f(size: 16, weight: FontWeight.w700, color: _T.lbl1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sync.downloadTotal > 0
                        ? '${sync.downloadDone} of ${sync.downloadTotal}'
                        : '${sync.downloadDone} downloaded…',
                    style: _T.f(size: 13, color: _T.lbl3),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sync.downloadTotal > 0
                          ? sync.downloadDone / sync.downloadTotal
                          : null,
                      backgroundColor: _T.sep,
                      valueColor: const AlwaysStoppedAnimation<Color>(_T.lime),
                      minHeight: 4,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Download Required',
                    style: _T.f(size: 18, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Search works instantly once attendee data is saved on this device. Data syncs automatically every 15 seconds while online.',
                    style: _T.f(size: 13, color: _T.lbl3, height: 1.55),
                    textAlign: TextAlign.center,
                  ),
                  if (isError) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Could not connect. Check your network and try again.',
                      style: _T.f(size: 12, color: Color(0xFFFF453A)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: onDownload,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _T.lime,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _T.lime.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download_rounded, color: Colors.black, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isError ? 'Retry Download' : 'Download Now',
                            style: _T.f(size: 15, weight: FontWeight.w700, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared empty / error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCheckpoints extends StatelessWidget {
  const _EmptyCheckpoints();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 32,
              color: _T.lbl4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No checkpoints available',
            style: _T.f(size: 16, weight: FontWeight.w600, color: _T.lbl1),
          ),
          const SizedBox(height: 6),
          Text(
            'Assign card types to this checkpoint first',
            style: _T.f(size: 13, color: _T.lbl3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _T.lime.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: _T.lime.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: _T.lime, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: _T.f(
              size: 17,
              weight: FontWeight.w700,
              color: _T.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text('Could not load data', style: _T.f(size: 13, color: _T.lbl3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient orb
// ─────────────────────────────────────────────────────────────────────────────

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
        color: color.withValues(alpha: opacity),
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
