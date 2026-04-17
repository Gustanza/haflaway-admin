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
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/index.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/inv_editor.dart';
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
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  // Backgrounds
  static const bg = Color(0xFF0A0A0A); // near-black page  
  static const card = Color(0xFF141414); // card surface
  static const card2 = Color(0xFF1A1A1A); // slightly lighter card

  // Accent — the lime/yellow from the screenshots
  static const lime = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF1E2800);

  // Text
  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);
  static const grey2 = Color(0xFF555555);
  static const grey3 = Color(0xFF333333);

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
  List<CheckPoint> checkpoints = [];

  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

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

      final result = await Future.wait([
        eventRef.get(),
        attsRef.get(),
        cardsRef.count().get(),
        msgsRef.count().get(),
        checkPointsRef.get(),
      ]);

      final eventSnapshot = result[0] as DocumentSnapshot<Map<String, dynamic>>;
      final attsSnapshot = result[1] as QuerySnapshot<Map<String, dynamic>>;
      final crdsSnapshot = result[2] as AggregateQuerySnapshot;
      final msgsSnapshot = result[3] as AggregateQuerySnapshot;
      final checkPnsSnapshot = result[4] as QuerySnapshot<Map<String, dynamic>>;

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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (hasError) return _buildErrorScaffold();
    if (isLoading && event == null) return _buildLoadingScaffold();
    return _buildMainScaffold();
  }

  // ── Loading ───────────────────────────────────────────────────────────────────

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

  // ── Main scaffold ─────────────────────────────────────────────────────────────

  Widget _buildMainScaffold() {
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

            RefreshIndicator(
              onRefresh: loadData,
              color: _T.lime,
              backgroundColor: _T.card,
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
                  SliverToBoxAdapter(child: _teamSection()),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24,
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

  // ── Top bar ───────────────────────────────────────────────────────────────────
  // "← Event Details   Edit" — yellow accent arrow + Edit button

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _T.lime,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Event Details',
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w500,
                    color: _T.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          PopupMenuButton<int>(
            icon: const Icon(CupertinoIcons.ellipsis, color: _T.lime, size: 20),
            color: _T.card,
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _T.white.withOpacity(0.1)),
            ),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.pencil,
                          color: _T.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text('Edit Event', style: _T.f(size: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.settings,
                          color: _T.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text('Settings', style: _T.f(size: 14)),
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

  // ── Hero block ────────────────────────────────────────────────────────────────
  // LIVE NOW badge, big title, date + location

  Widget _heroBlock() {
    final title = event?.title ?? widget.eventO.title ?? '';
    final date = _formattedDate();
    final loc = event?.location ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIVE NOW badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _T.lime.withOpacity(0.4)),
            ),
            child: Text(
              'LIVE NOW',
              style: _T.f(
                size: 11,
                weight: FontWeight.w700,
                color: _T.lime,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Big event title
          Text(
            title,
            style: _T.f(
              size: 32,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),

          // Date
          if (date.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: _T.grey1,
                ),
                const SizedBox(width: 7),
                Text(date, style: _T.f(size: 13, color: _T.grey1)),
              ],
            ),
          if (loc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: _T.grey1,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    loc,
                    style: _T.f(size: 13, color: _T.grey1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Contributions big card ────────────────────────────────────────────────────
  // Matches screenshot 1: large number, progress bar, goal text

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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTRIBUTIONS',
                  style: _T.f(
                    size: 10,
                    weight: FontWeight.w700,
                    color: _T.grey2,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w700,
                    color: _T.lime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${formatMoney(event?.totalPayment, currency: "TZS")}',
              style: _T.f(
                size: 24,
                weight: FontWeight.w800,
                color: _T.white,
                letterSpacing: -1.0,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: _T.grey3,
                valueColor: AlwaysStoppedAnimation<Color>(_T.lime),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Goal: ${formatMoney(event?.totalPledge ?? 0.0, currency: 'TZS')}',
              style: _T.f(size: 12, color: _T.grey2),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mini stat row: Invitations + Admins side by side ─────────────────────────

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: _T.f(
                size: 10,
                weight: FontWeight.w700,
                color: _T.grey2,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: _T.f(
                size: 40,
                weight: FontWeight.w800,
                color: _T.white,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(sub, style: _T.f(size: 12, color: _T.grey2)),
            const SizedBox(height: 12),
            Icon(icon, color: _T.lime, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Checkpoints section ───────────────────────────────────────────────────────

  Widget _checkpointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'SCAN CHECKPOINTS',
          action: 'Add new',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CheckPoints(edata: widget.eventO),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(checkpoints.length, (idx) {
              CheckPoint checkpoint = checkpoints[idx];
              return _checkpointRow(
                icon: Icons.meeting_room_outlined,
                name: '${checkpoint.name}',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return InCheckWrapper(
                          checkpoint: checkpoint,
                          eId: event?.id ?? "",
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _checkpointRow({
    required IconData icon,
    required String name,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: _T.lime, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: _T.f(size: 15, weight: FontWeight.w500, color: _T.white),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _T.grey2, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Event tools grid ──────────────────────────────────────────────────────────

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
                      builder: (_) {
                        return Attendees(
                          edata: event!,
                          title: "Contacts",
                          kardType: KardType.contact,
                        );
                      },
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
        const SizedBox(height: 8),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon top-left
                Icon(icon, color: isActive ? _T.lime : _T.grey2, size: 22),
                const Spacer(),
                // Big count
                Text(
                  count,
                  style: _T.f(
                    size: 34,
                    weight: FontWeight.w800,
                    color: isActive ? _T.white : _T.grey2,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: _T.f(
                    size: 13,
                    weight: FontWeight.w600,
                    color: isActive ? _T.white : _T.grey2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: _T.f(size: 11, color: _T.grey2),
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
          color: isActive ? _T.lime.withOpacity(0.35) : _T.grey3,
          width: 0.5,
        ),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'SOON',
        style: _T.f(
          size: 8,
          weight: FontWeight.w800,
          color: isActive ? _T.lime : _T.grey2,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Team section ──────────────────────────────────────────────────────────────

  Widget _teamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'MANAGEMENT TEAM',
          action: 'Manage',
          onAction: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => Users(eId: event?.id ?? '')),
            );
            loadData();
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => Users(eId: event?.id ?? '')),
              );
              loadData();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _avStack(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$adminsCount Administrators',
                          style: _T.f(
                            size: 15,
                            weight: FontWeight.w600,
                            color: _T.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$scannersCount scanners',
                          style: _T.f(size: 12, color: _T.grey2),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _T.grey2,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avStack() {
    const data = [
      (Color(0xFF3D1A0A), Color(0xFFE07040), 'FA'),
      (Color(0xFF0A1830), Color(0xFF5A8ADB), 'JK'),
      (Color(0xFF0D2018), Color(0xFF3DAA76), 'AM'),
      (Color(0xFF1E0D30), Color(0xFFBF5AF2), 'SK'),
    ];
    const double sz = 32;
    const double ov = 9;
    final double w = sz + (data.length - 1) * (sz - ov);

    return SizedBox(
      width: w,
      height: sz,
      child: Stack(
        children:
            data.asMap().entries.map((e) {
              final d = e.value;
              return Positioned(
                left: e.key * (sz - ov),
                child: Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.$1,
                    border: Border.all(color: _T.card, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      d.$3,
                      style: _T.f(
                        size: 10,
                        weight: FontWeight.w700,
                        color: d.$2,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ── Publish button ────────────────────────────────────────────────────────────

  // ── Section header ────────────────────────────────────────────────────────────

  Widget _sectionHeader(
    String label, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: _T.f(
              size: 11,
              weight: FontWeight.w700,
              color: _T.grey2,
              letterSpacing: 1.2,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action,
                style: _T.f(size: 12, weight: FontWeight.w600, color: _T.lime),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom nav bar ────────────────────────────────────────────────────────────
  // Matches screenshots: 4 icons, active = lime circle background
  // ── Error scaffold ────────────────────────────────────────────────────────────

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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _T.lime.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            color: _T.lime,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Something went wrong',
                          style: _T.f(
                            size: 22,
                            weight: FontWeight.w700,
                            color: _T.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We couldn\'t load the event data.\nPlease try again.',
                          textAlign: TextAlign.center,
                          style: _T.f(size: 14, color: _T.grey1, height: 1.5),
                        ),
                        const SizedBox(height: 32),
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

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void safeState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChkpnForm — untouched logic, restyled to match
// ─────────────────────────────────────────────────────────────────────────────

class ChkpnForm extends StatefulWidget {
  final String eId;
  const ChkpnForm({super.key, required this.eId});

  @override
  State<ChkpnForm> createState() => _ChkpnFormState();
}

class _ChkpnFormState extends State<ChkpnForm> {
  List selCrdsIds = [];
  bool isLoading = false;
  final key = GlobalKey<FormState>();
  final firestore = FirebaseFirestore.instance;
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore.collection(ecol).doc(widget.eId).collection(cardcol).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center();
        if (snapshot.hasError) return const Center();

        final fcards =
            (snapshot.data as dynamic).docs
                .map<Kard>((doc) => Kard.fromMap(doc.id, doc.data()))
                .toList();

        return Form(
          key: key,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                'New Checkpoint',
                style: _T.f(
                  size: 26,
                  weight: FontWeight.w800,
                  color: _T.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Name this checkpoint and select accepted card types.',
                style: _T.f(size: 14, color: _T.grey1, height: 1.5),
              ),
              const SizedBox(height: 22),

              // Name field
              TextFormField(
                controller: controller,
                style: _T.f(size: 15, weight: FontWeight.w400, color: _T.white),
                cursorColor: _T.lime,
                decoration: InputDecoration(
                  hintText: 'e.g. Main Entrance',
                  hintStyle: _T.f(size: 15, color: _T.grey2),
                  filled: true,
                  fillColor: _T.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _T.grey3, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _T.grey3, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _T.lime, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_rounded,
                    color: _T.grey2,
                    size: 18,
                  ),
                ),
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 28),

              if (fcards.isNotEmpty) ...[
                Text(
                  'Accepted Card Types',
                  style: _T.f(
                    size: 17,
                    weight: FontWeight.w600,
                    color: _T.white,
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? _T.lime.withOpacity(0.4) : _T.grey3,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sel
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: sel ? _T.lime : _T.grey2,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            card.type,
                            style: _T.f(
                              size: 15,
                              weight: sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? _T.lime : _T.white,
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
                              await crtActn(selCrdsIds: selCrdsIds);
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.lime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                            'Save Checkpoint',
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
        );
      },
    );
  }

  Widget _emptyCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.credit_card_off_rounded, size: 48, color: _T.grey2),
          const SizedBox(height: 16),
          Text(
            'No card types available',
            style: _T.f(size: 15, weight: FontWeight.w500, color: _T.grey1),
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
