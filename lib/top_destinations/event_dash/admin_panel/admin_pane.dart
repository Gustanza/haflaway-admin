import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/in_check.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/inv_editor.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/gallery/event_gallery.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/settings/event_settings.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/users_perms/users.dart';
import 'package:haflaway/top_destinations/event_dash/cards/cards.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/attendees.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark, not pitch-black
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  // Backgrounds — lifted from 0x0A to give real depth layers
  static const bg = Color(0xFF111114); // page canvas
  static const card = Color(0xFF1C1C1E); // Apple systemGray6 dark surface
  static const card2 = Color(0xFF28282C); // elevated card
  static const card3 = Color(0xFF3A3A3C); // interactive / pressed

  // Borders & separators
  static const sep = Color(0xFF2C2C2E); // Apple separator dark

  // Accent — golden amber
  static const lime = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210); // warm amber dim

  // Text hierarchy (matches Apple HIG dark)
  static const white = Color(0xFFFFFFFF);
  static const lbl1 = Color(0xFFEEEEF0); // primary label
  static const lbl2 = Color(0xFFAEAEB2); // secondary label
  static const lbl3 = Color(0xFF8E8E93); // tertiary label
  static const lbl4 = Color(0xFF48484A); // quaternary / disabled

  // ── Typography ─────────────────────────────────────────────────────────────
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
// AdminPanel
// ─────────────────────────────────────────────────────────────────────────────

class AdminPanel extends StatefulWidget {
  final Event eventO;
  final bool isAdmin;
  const AdminPanel({super.key, required this.eventO, required this.isAdmin});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  Event? event;
  bool isLoading = false;
  bool hasError = false;
  int invsCount = 0;
  int contsCount = 0;
  int adminsCount = 0;
  int scannersCount = 0;
  int contactsCount = 0;
  int cardTempsNo = 0;
  int evMsgTmpCount = 0;
  int galleryCount = 0;
  List<CheckPoint> checkpoints = [];

  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    safeState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final eventRef = firestore.collection(ecol).doc(widget.eventO.id);
      final attsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(atcol);
      final cardsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(cardcol);
      final msgsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(evMsgTmpCol);
      final checkPointsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(echecksub);
      final galleryRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(egalsub);

      final result = await Future.wait([
        eventRef.get(),
        attsRef.get(),
        cardsRef.count().get(),
        msgsRef.count().get(),
        checkPointsRef.get(),
        galleryRef.count().get(),
      ]);

      final eventSnapshot = result[0] as DocumentSnapshot<Map<String, dynamic>>;
      final attsSnapshot = result[1] as QuerySnapshot<Map<String, dynamic>>;
      final crdsSnapshot = result[2] as AggregateQuerySnapshot;
      final msgsSnapshot = result[3] as AggregateQuerySnapshot;
      final checkPnsSnapshot = result[4] as QuerySnapshot<Map<String, dynamic>>;
      final galSnapshot = result[5] as AggregateQuerySnapshot;

      invsCount =
          attsSnapshot.docs
              .where(
                (t) => Attendee.fromMap(
                  t.id,
                  t.data(),
                ).cards.containsKey(KardType.invitation.name),
              )
              .length;
      contsCount =
          attsSnapshot.docs
              .where(
                (t) => Attendee.fromMap(
                  t.id,
                  t.data(),
                ).cards.containsKey(KardType.contribution.name),
              )
              .length;
      contactsCount =
          attsSnapshot.docs
              .where(
                (t) => Attendee.fromMap(
                  t.id,
                  t.data(),
                ).cards.containsKey(KardType.contact.name),
              )
              .length;
      checkpoints =
          checkPnsSnapshot.docs.map<CheckPoint>((el) {
            return CheckPoint.fromMap(el.id, el.data());
          }).toList();

      event = Event.fromMap(eventSnapshot.id, eventSnapshot.data()!);
      cardTempsNo = crdsSnapshot.count ?? 0;
      evMsgTmpCount = msgsSnapshot.count ?? 0;
      galleryCount = galSnapshot.count ?? 0;
      adminsCount = event?.adminsIds?.length ?? 0;
      scannersCount = event?.usersIds?.length ?? 0;

      safeState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
        hasError = true;
      });
      debugPrint('AdminPanel error: $e');
    }
  }

  String _formattedDate() {
    try {
      if (event?.startDate != null) {
        return DateFormat(
          'EEE, MMM d · h:mm a',
        ).format(DateTime.parse(event!.startDate!));
      }
    } catch (_) {}
    return '';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (hasError) return _buildErrorScaffold();
    if (isLoading && event == null) return _buildLoadingScaffold();
    return _buildMainScaffold();
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoadingScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              const Expanded(
                child: Center(
                  child: CupertinoActivityIndicator(color: _T.lime),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main scaffold ─────────────────────────────────────────────────────────

  Widget _buildMainScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            // Ambient orbs — slightly brighter so they're visible against the new bg
            const Positioned(
              top: -80,
              right: -80,
              child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
            ),
            const Positioned(
              bottom: -40,
              left: -80,
              child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
            ),

            RefreshIndicator(
              onRefresh: loadData,
              color: _T.lime,
              backgroundColor: _T.card2,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_topBar(), _heroBlock()],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _miniStatRow()),
                  SliverToBoxAdapter(child: _checkpointsSection()),
                  SliverToBoxAdapter(child: _toolsSection()),
                  SliverToBoxAdapter(child: _gallerySection()),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 32,
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

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          // Back button — pill style
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
          // Menu button
          PopupMenuButton<int>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: const Icon(
                CupertinoIcons.ellipsis,
                color: _T.lbl2,
                size: 18,
              ),
            ),
            color: _T.card2,
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _T.sep, width: 0.8),
            ),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.pencil,
                          color: _T.lbl2,
                          size: 17,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Edit Event',
                          style: _T.f(size: 14, color: _T.lbl1),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.settings,
                          color: _T.lbl2,
                          size: 17,
                        ),
                        const SizedBox(width: 10),
                        Text('Settings', style: _T.f(size: 14, color: _T.lbl1)),
                      ],
                    ),
                  ),
                ],
            onSelected: (value) async {
              if (value == 1) {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateEvent(event: event)),
                );
                loadData();
              } else if (value == 2) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventSettings(event: event),
                  ),
                );
                loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Hero block ────────────────────────────────────────────────────────────

  Widget _heroBlock() {
    final title = event?.title ?? widget.eventO.title ?? '';
    final date = _formattedDate();
    final loc = event?.location ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIVE NOW badge — with pulsing dot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _T.lime.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _T.lime,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE NOW',
                  style: _T.f(
                    size: 10,
                    weight: FontWeight.w800,
                    color: _T.lime,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Big event title
          Text(
            title,
            style: _T.f(
              size: 30,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.8,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 16),

          // Meta row — date + location
          if (date.isNotEmpty || loc.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Column(
                children: [
                  if (date.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: _T.lime,
                        ),
                        const SizedBox(width: 8),
                        Text(date, style: _T.f(size: 13, color: _T.lbl2)),
                      ],
                    ),
                  if (date.isNotEmpty && loc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 0.5, color: _T.sep),
                    ),
                  if (loc.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: _T.lime,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc,
                            style: _T.f(size: 13, color: _T.lbl2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Contributions big card ────────────────────────────────────────────────

  Widget _contributionsCard() {
    var pl = event?.totalPledge ?? 0.0;
    var py = event?.totalPayment ?? 0.0;
    double pct = (py / pl);
    if (pct.isNaN || pct.isInfinite) pct = 0.0;

    return GestureDetector(
      onTap: () async {
        try {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => Attendees(
                    edata: event!,
                    kardType: KardType.contribution,
                    title: 'Manage Contributions',
                  ),
            ),
          );
          loadData();
        } catch (e) {
          showToast(isGood: false, msg: e.toString());
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.sep, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _T.lime.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _T.lime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: _T.lime,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'CONTRIBUTIONS',
                      style: _T.f(
                        size: 11,
                        weight: FontWeight.w700,
                        color: _T.lbl3,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _T.limeDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _T.lime.withValues(alpha: 0.3),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    '${(pct * 100).round()}%',
                    style: _T.f(
                      size: 13,
                      weight: FontWeight.w800,
                      color: _T.lime,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${formatMoney(event?.totalPayment, currency: "TZS")}',
              style: _T.f(
                size: 28,
                weight: FontWeight.w800,
                color: _T.white,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar — gradient fill
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 6, color: _T.card3),
                  FractionallySizedBox(
                    widthFactor: pct.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_T.lime.withValues(alpha: 0.7), _T.lime],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal: ${formatMoney(event?.totalPledge ?? 0.0, currency: 'TZS')}',
                  style: _T.f(size: 12, color: _T.lbl3),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _T.lbl4,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Mini stat row: Invitations + Admins side by side ─────────────────────

  Widget _miniStatRow() {
    return Column(
      children: [
        _contributionsCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _miniStatCard(
                  label: 'INVITATIONS',
                  value: '$invsCount',
                  sub: 'sent',
                  icon: Icons.confirmation_number_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => Attendees(
                              edata: event!,
                              kardType: KardType.invitation,
                            ),
                      ),
                    );
                    loadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStatCard(
                  label: 'ADMINS',
                  value: '$adminsCount',
                  sub: 'active',
                  icon: Icons.people_alt_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Users(eId: event?.id ?? ''),
                      ),
                    );
                    loadData();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label + icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: _T.f(
                    size: 10,
                    weight: FontWeight.w700,
                    color: _T.lbl3,
                    letterSpacing: 1.1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _T.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _T.lime, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Big number
            Text(
              value,
              style: _T.f(
                size: 42,
                weight: FontWeight.w800,
                color: _T.white,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(sub, style: _T.f(size: 12, color: _T.lbl3)),
          ],
        ),
      ),
    );
  }

  // ── Checkpoints section ───────────────────────────────────────────────────

  Widget _checkpointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'SCAN CHECKPOINTS',
          action: 'Add new',
          onAction: () => _openChkpnSheet(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              checkpoints.isEmpty
                  ? _emptyCheckpoints()
                  : Column(
                    children: List.generate(checkpoints.length, (idx) {
                      CheckPoint checkpoint = checkpoints[idx];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: idx < checkpoints.length - 1 ? 8 : 0,
                        ),
                        child: _checkpointRow(
                          checkpoint: checkpoint,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => InCheckWrapper(
                                      checkpoint: checkpoint,
                                      eId: event?.id ?? "",
                                    ),
                              ),
                            );
                          },
                          onEdit: () => _openChkpnSheet(checkpoint: checkpoint),
                          onDelete: () => _deleteCheckpoint(checkpoint),
                        ),
                      );
                    }),
                  ),
        ),
        // const SizedBox(height: 8),
      ],
    );
  }

  Widget _emptyCheckpoints() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 32, color: _T.lbl4),
            const SizedBox(height: 10),
            Text('No checkpoints yet', style: _T.f(size: 14, color: _T.lbl3)),
          ],
        ),
      ),
    );
  }

  Widget _checkpointRow({
    required CheckPoint checkpoint,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                color: _T.lime,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                checkpoint.name,
                style: _T.f(size: 15, weight: FontWeight.w500, color: _T.lbl1),
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _T.card2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.ellipsis,
                  color: _T.lbl3,
                  size: 15,
                ),
              ),
              color: _T.card2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _T.sep, width: 0.8),
              ),
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.pencil,
                            color: _T.lbl2,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Text('Edit', style: _T.f(size: 14, color: _T.lbl1)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.trash,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: _T.f(size: 14, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChkpnSheet({CheckPoint? checkpoint}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: _T.bg.withValues(alpha: 0.72),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.13),
                        width: 0.8,
                      ),
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.13),
                        width: 0.8,
                      ),
                      right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.13),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: ChkpnForm(
                    eId: event?.id ?? widget.eventO.id ?? '',
                    checkpoint: checkpoint,
                  ),
                ),
              ),
            ),
          ),
    ).then((_) => loadData());
  }

  Future<void> _deleteCheckpoint(CheckPoint checkpoint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: _T.card2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Checkpoint',
              style: _T.f(size: 17, weight: FontWeight.w700),
            ),
            content: Text(
              'Delete "${checkpoint.name}"?\nThis cannot be undone.',
              style: _T.f(size: 14, color: _T.lbl2, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: _T.f(size: 15, color: _T.lbl2)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final eId = event?.id ?? widget.eventO.id ?? '';
      final batch = firestore.batch();
      batch.delete(
        firestore
            .collection(ecol)
            .doc(eId)
            .collection(echecksub)
            .doc(checkpoint.id),
      );
      final cardsSnap =
          await firestore.collection(ecol).doc(eId).collection(cardcol).get();
      for (final doc in cardsSnap.docs) {
        final clearAt = (doc.data()['clearAt'] as List?) ?? [];
        if (clearAt.contains(checkpoint.id)) {
          batch.update(doc.reference, {
            crdClrnc: FieldValue.arrayRemove([checkpoint.id]),
          });
        }
      }
      await batch.commit();
      showToast(isGood: true, msg: 'Checkpoint deleted');
      loadData();
    } catch (e) {
      showToast(isGood: false, msg: e.toString());
    }
  }

  // ── Event tools grid ──────────────────────────────────────────────────────

  Widget _toolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('EVENT TOOLS'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            padding: EdgeInsets.only(top: psm),
            children: [
              _toolCard(
                icon: Icons.people_outline,
                count: '$contactsCount',
                title: 'Contacts',
                subtitle: 'Send messages',
                isActive: true,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => Attendees(
                            edata: event!,
                            title: "Contacts",
                            kardType: KardType.contact,
                          ),
                    ),
                  );
                  loadData();
                },
              ),
              _toolCard(
                icon: Icons.people_alt_outlined,
                count: '$contsCount',
                title: 'Contributions',
                subtitle: 'Track payments',
                isActive: true,
                onTap: () async {
                  try {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => Attendees(
                              edata: event!,
                              kardType: KardType.contribution,
                              title: 'Manage Contributions',
                            ),
                      ),
                    );
                    loadData();
                  } catch (e) {
                    showToast(isGood: false, msg: e.toString());
                  }
                },
              ),
              _toolCard(
                icon: Icons.desktop_windows_outlined,
                count: '$cardTempsNo',
                title: 'Card Templates',
                subtitle: 'Design invitations',
                isActive: true,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Cards(eId: widget.eventO.id ?? ''),
                    ),
                  );
                  loadData();
                },
              ),
              _toolCard(
                icon: Icons.chat_bubble_outline_rounded,
                count: '$evMsgTmpCount',
                title: 'SMS Templates',
                subtitle: 'Broadcast messages',
                isActive: true,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InvEditor(eId: widget.eventO.id ?? ''),
                    ),
                  );
                  loadData();
                },
              ),
              /* _toolCard(
                icon: Icons.storefront_outlined,
                count: '—',
                title: 'Vendors',
                subtitle: 'Suppliers list',
                isActive: false,
                onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
              ),
              _toolCard(
                icon: Icons.mic_none_rounded,
                count: '—',
                title: 'Event MCs',
                subtitle: 'Hosts & ceremony',
                isActive: false,
                onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
              ),
              _toolCard(
                icon: Icons.meeting_room_outlined,
                count: '—',
                title: 'Venue',
                subtitle: 'Hall management',
                isActive: false,
                onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
              ),
              _toolCard(
                icon: Icons.account_balance_wallet_outlined,
                count: '—',
                title: 'Budget',
                subtitle: 'Track expenses',
                isActive: false,
                onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
              ),
              */
            ],
          ),
        ),
        // const SizedBox(height: 8),
      ],
    );
  }

  Widget _toolCard({
    required IconData icon,
    required String count,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in rounded container
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color:
                        isActive ? _T.lime.withValues(alpha: 0.13) : _T.card2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? _T.lime : _T.lbl4,
                    size: 20,
                  ),
                ),
                const Spacer(),
                // Big count
                Text(
                  count,
                  style: _T.f(
                    size: 36,
                    weight: FontWeight.w800,
                    color: isActive ? _T.white : _T.lbl4,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: _T.f(
                    size: 13,
                    weight: FontWeight.w600,
                    color: isActive ? _T.lbl1 : _T.lbl3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: _T.f(size: 11, color: _T.lbl3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            // ACTIVE / SOON badge top-right
            Positioned(top: 0, right: 0, child: _statusBadge(isActive)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? _T.limeDim : _T.card2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? _T.lime.withValues(alpha: 0.4) : _T.sep,
          width: 0.6,
        ),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'SOON',
        style: _T.f(
          size: 8,
          weight: FontWeight.w800,
          color: isActive ? _T.lime : _T.lbl3,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Gallery section ───────────────────────────────────────────────────────

  Widget _gallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('GALLERY'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventGallery(event: event!)),
              );
              loadData();
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _T.lime.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: _T.lime,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gallery',
                          style: _T.f(
                            size: 15,
                            weight: FontWeight.w500,
                            color: _T.lbl1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$galleryCount photos',
                          style: _T.f(size: 12, color: _T.lbl3),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _T.card2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: _T.lbl3,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _sectionHeader(
    String label, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: _T.lime,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: _T.f(
                  size: 11,
                  weight: FontWeight.w700,
                  color: _T.lbl3,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _T.limeDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _T.lime.withValues(alpha: 0.3),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  action,
                  style: _T.f(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _T.lime,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Error scaffold ────────────────────────────────────────────────────────

  Widget _buildErrorScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: _T.lime.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _T.lime.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            color: _T.lime,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Something went wrong',
                          style: _T.f(
                            size: 22,
                            weight: FontWeight.w800,
                            color: _T.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We couldn\'t load the event data.\nPlease try again.',
                          textAlign: TextAlign.center,
                          style: _T.f(size: 14, color: _T.lbl2, height: 1.6),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _T.lime,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Retry',
                              style: _T.f(
                                size: 16,
                                weight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void safeState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChkpnForm — untouched logic, restyled to match
// ─────────────────────────────────────────────────────────────────────────────

class ChkpnForm extends StatefulWidget {
  final String eId;
  final CheckPoint? checkpoint;
  const ChkpnForm({super.key, required this.eId, this.checkpoint});

  @override
  State<ChkpnForm> createState() => _ChkpnFormState();
}

class _ChkpnFormState extends State<ChkpnForm> {
  List selCrdsIds = [];
  bool isLoading = false;
  bool _selInitialized = false;
  final key = GlobalKey<FormState>();
  final firestore = FirebaseFirestore.instance;
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.checkpoint?.name ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore.collection(ecol).doc(widget.eId).collection(cardcol).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError)
          return const SizedBox(
            height: kToolbarHeight * 3,
            child: Center(child: CupertinoActivityIndicator(color: _T.lime)),
          );

        final fcards =
            (snapshot.data as dynamic).docs
                .map<Kard>((doc) => Kard.fromMap(doc.id, doc.data()))
                .toList();

        if (!_selInitialized && widget.checkpoint != null) {
          _selInitialized = true;
          selCrdsIds =
              fcards
                  .where((Kard c) => c.clearAt.contains(widget.checkpoint!.id))
                  .map((Kard c) => c.id)
                  .toList();
        }

        final isEdit = widget.checkpoint != null;

        return Form(
          key: key,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              28,
              20,
              MediaQuery.of(context).padding.bottom + 52,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Checkpoint' : 'New Checkpoint',
                  style: _T.f(
                    size: 26,
                    weight: FontWeight.w800,
                    color: _T.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Name this checkpoint and select accepted card types.',
                  style: _T.f(size: 14, color: _T.lbl2, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  controller: controller,
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w400,
                    color: _T.white,
                  ),
                  cursorColor: _T.lime,
                  decoration: InputDecoration(
                    hintText: 'e.g. Main Entrance',
                    hintStyle: _T.f(size: 15, color: _T.lbl4),
                    filled: true,
                    fillColor: _T.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _T.sep, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _T.sep, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _T.lime, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_rounded,
                      color: _T.lbl3,
                      size: 17,
                    ),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.isEmpty) ? 'Name is required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 28),

                if (fcards.isNotEmpty) ...[
                  Text(
                    'Accepted Card Types',
                    style: _T.f(
                      size: 17,
                      weight: FontWeight.w600,
                      color: _T.lbl1,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fcards.map((card) {
                    final sel = selCrdsIds.contains(card.id);
                    return GestureDetector(
                      onTap:
                          () => setState(
                            () =>
                                sel
                                    ? selCrdsIds.remove(card.id)
                                    : selCrdsIds.add(card.id),
                          ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? _T.limeDim : _T.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                sel ? _T.lime.withValues(alpha: 0.45) : _T.sep,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sel
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: sel ? _T.lime : _T.lbl3,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              card.type,
                              style: _T.f(
                                size: 15,
                                weight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? _T.lime : _T.lbl1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ] else
                  _emptyCards(),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (key.currentState?.validate() ?? false) {
                                if (isEdit) {
                                  await updateActn(newSelCrdsIds: selCrdsIds);
                                } else {
                                  await crtActn(selCrdsIds: selCrdsIds);
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.lime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                            : Text(
                              isEdit ? 'Save Changes' : 'Save Checkpoint',
                              style: _T.f(
                                size: 16,
                                weight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.credit_card_off_rounded, size: 48, color: _T.lbl4),
          const SizedBox(height: 16),
          Text(
            'No card types available',
            style: _T.f(size: 15, weight: FontWeight.w500, color: _T.lbl2),
          ),
        ],
      ),
    );
  }

  Future<void> crtActn({required List selCrdsIds}) async {
    setState(() => isLoading = true);
    try {
      final batch = firestore.batch();
      final chkpnRef =
          firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(echecksub)
              .doc();

      final crdRefs =
          selCrdsIds
              .map(
                (id) => firestore
                    .collection(ecol)
                    .doc(widget.eId)
                    .collection(cardcol)
                    .doc(id as String),
              )
              .toList();

      batch.set(
        chkpnRef,
        CheckPoint(id: chkpnRef.id, name: controller.text).toMap(),
      );
      for (final ref in crdRefs) {
        batch.update(ref, {
          crdClrnc: FieldValue.arrayUnion([chkpnRef.id]),
        });
      }

      await batch.commit();
      setState(() => isLoading = false);
      if (mounted) Navigator.pop(context);
      showToast(isGood: true, msg: 'Checkpoint created successfully');
    } catch (e) {
      setState(() => isLoading = false);
      showToast(isGood: false, msg: '$e');
    }
  }

  Future<void> updateActn({required List newSelCrdsIds}) async {
    setState(() => isLoading = true);
    try {
      final checkpointId = widget.checkpoint!.id;
      final batch = firestore.batch();

      batch.update(
        firestore
            .collection(ecol)
            .doc(widget.eId)
            .collection(echecksub)
            .doc(checkpointId),
        {'name': controller.text},
      );

      final cardsSnap =
          await firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(cardcol)
              .get();

      for (final doc in cardsSnap.docs) {
        final clearAt = (doc.data()['clearAt'] as List?) ?? [];
        final wasSelected = clearAt.contains(checkpointId);
        final isSelected = newSelCrdsIds.contains(doc.id);
        if (!wasSelected && isSelected) {
          batch.update(doc.reference, {
            crdClrnc: FieldValue.arrayUnion([checkpointId]),
          });
        } else if (wasSelected && !isSelected) {
          batch.update(doc.reference, {
            crdClrnc: FieldValue.arrayRemove([checkpointId]),
          });
        }
      }

      await batch.commit();
      setState(() => isLoading = false);
      if (mounted) Navigator.pop(context);
      showToast(isGood: true, msg: 'Checkpoint updated');
    } catch (e) {
      setState(() => isLoading = false);
      showToast(isGood: false, msg: '$e');
    }
  }
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
