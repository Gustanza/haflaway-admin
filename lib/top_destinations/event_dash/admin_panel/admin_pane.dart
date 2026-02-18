import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/index.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/inv_editor.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/settings/event_settings.dart';
import 'package:haflaway/top_destinations/event_dash/cards/cards.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/users_perms/users.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/attendees.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/sms/eventTools.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class AdminPanel extends StatefulWidget {
  final Event eventO;
  final bool isAdmin;
  const AdminPanel({super.key, required this.eventO, required this.isAdmin});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
  Event? event;
  bool isLoading = false;
  bool hasError = false;
  int invsCount = 0;
  int contsCount = 0;
  int adminsCount = 0;
  int scannersCount = 0;
  int cardTempsNo = 0;
  int evMsgTmpCount = 0;
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    safeState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      DocumentReference<Map<String, dynamic>> eventRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id);
      CollectionReference<Map<String, dynamic>> attsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(atcol);
      CollectionReference<Map<String, dynamic>> cardsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(cardcol);
      CollectionReference<Map<String, dynamic>> msgsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(evMsgTmpCol);
      var result = await Future.wait([
        eventRef.get(),
        attsRef.get(),
        cardsRef.count().get(),
        msgsRef.count().get(),
      ]);
      var eventSnapshot = result[0] as DocumentSnapshot<Map<String, dynamic>>;
      var attsSnapshot = result[1] as QuerySnapshot<Map<String, dynamic>>;
      var crdsSnapshot = result[2] as AggregateQuerySnapshot;
      var msgsSnapshot = result[3] as AggregateQuerySnapshot;
      invsCount =
          attsSnapshot.docs.where((t) {
            Attendee attendee = Attendee.fromMap(t.id, t.data());
            return attendee.cards.containsKey(KardType.invitation.name);
          }).length;

      contsCount =
          attsSnapshot.docs.where((t) {
            Attendee attendee = Attendee.fromMap(t.id, t.data());
            return attendee.cards.containsKey(KardType.contribution.name);
          }).length;

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
      debugPrint("Error is: $e");
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  String _formattedDate() {
    try {
      if (event?.startDate != null) {
        final dt = DateTime.parse(event!.startDate!);
        return DateFormat('EEE, MMM d · h:mm a').format(dt);
      }
    } catch (_) {}
    return "";
  }

  // ── Floating glass icon button (back / settings / edit) ─
  Widget _floatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ── Single action row (iOS-settings style) ──────────────
  Widget _buildActionRow({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String count,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            // Icon pill
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            // Count badge
            if (count.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section card (frosted glass container) ──────────────
  Widget _buildSectionCard({
    required String title,
    required List<Widget> rows,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: List.generate(rows.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      // Divider
                      return Padding(
                        padding: const EdgeInsets.only(left: 74),
                        child: Container(
                          height: 0.5,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      );
                    }
                    return rows[i ~/ 2];
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error view ──────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Imeshindikana kupakia",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Angalia mtandao wako na ujaribu tena",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Text(
                "Jaribu Tena",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── BUILD ─────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.48;

    return Scaffold(
      backgroundColor: scaback,
      extendBodyBehindAppBar: true,
      body:
          !hasError && isLoading
              ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a1a2e),
                      Color(0xFF16213e),
                      Color(0xFF0f3460),
                    ],
                  ),
                ),
                child: buildLoader(),
              )
              : hasError
              ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a1a2e),
                      Color(0xFF16213e),
                      Color(0xFF0f3460),
                    ],
                  ),
                ),
                child: SafeArea(child: _buildErrorView()),
              )
              : CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // ── Hero SliverAppBar ───────────────────
                  SliverAppBar(
                    expandedHeight: heroHeight,
                    pinned: true,
                    stretch: true,
                    backgroundColor: scaback,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    // Floating buttons
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Center(
                        child: _floatingButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    actions: [
                      _floatingButton(
                        icon: Icons.settings_rounded,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return EventSettings(event: event);
                              },
                            ),
                          );
                          loadData();
                        },
                      ),
                      const SizedBox(width: 10),
                      _floatingButton(
                        icon: Icons.edit_rounded,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return CreateEvent(event: event);
                              },
                            ),
                          );
                          loadData();
                        },
                      ),
                      const SizedBox(width: 14),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground,
                      ],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Event thumbnail
                          CachedNetworkImage(
                            imageUrl: event?.eventThumbnail ?? "",
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: scaback,
                                  highlightColor: const Color(0xFF16213e),
                                  child: Container(color: scaback),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: scaback,
                                  child: Icon(
                                    Clarity.image_line,
                                    color: Colors.white.withOpacity(0.2),
                                    size: 64,
                                  ),
                                ),
                          ),

                          // Multi-stop gradient fade
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.35, 0.6, 0.8, 1.0],
                                colors: [
                                  Colors.black.withOpacity(0.25),
                                  Colors.transparent,
                                  Colors.transparent,
                                  scaback.withOpacity(0.75),
                                  scaback,
                                ],
                              ),
                            ),
                          ),

                          // Event title + details overlay
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  event?.title ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_formattedDate().isNotEmpty ||
                                    (event?.location ?? "").isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  if (_formattedDate().isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: Colors.white.withOpacity(0.6),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formattedDate(),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if ((event?.location ?? "").isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white.withOpacity(0.6),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            event!.location!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Admin tool sections ────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 28, 18, 40),
                      child: Column(
                        children: [
                          // ─ Invitations & Scanning ──────
                          _buildSectionCard(
                            title: "Mialiko ya Digital",
                            rows: [
                              _buildActionRow(
                                icon: Clarity.email_line,
                                iconGradient: const [
                                  Color(0xFF6366F1),
                                  Color(0xFF818CF8),
                                ],
                                title: "Kadi Zote",
                                count: "$invsCount",
                                onTap: () async {
                                  try {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return Attendees(
                                            edata: event!,
                                            kardType: KardType.invitation,
                                          );
                                        },
                                      ),
                                    );
                                    loadData();
                                  } catch (e) {
                                    showToast(isGood: false, msg: e.toString());
                                  }
                                },
                              ),
                              _buildActionRow(
                                icon: Clarity.qr_code_line,
                                iconGradient: const [
                                  Color(0xFF8B5CF6),
                                  Color(0xFFA78BFA),
                                ],
                                title: "Skani Kadi",
                                count: "$invsCount",
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              CheckPoints(edata: widget.eventO),
                                    ),
                                  );
                                },
                                isLast: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ─ Contributions & Budget ──────
                          _buildSectionCard(
                            title: "Michango & Bajeti",
                            rows: [
                              _buildActionRow(
                                icon: Icons.monetization_on_outlined,
                                iconGradient: const [
                                  Color(0xFF10B981),
                                  Color(0xFF34D399),
                                ],
                                title: "Michango",
                                count: "$contsCount",
                                onTap: () async {
                                  try {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => Attendees(
                                              edata: event!,
                                              title: "Ratibu Michango",
                                              kardType: KardType.contribution,
                                            ),
                                      ),
                                    );
                                    loadData();
                                  } catch (e) {
                                    showToast(isGood: false, msg: e.toString());
                                  }
                                },
                              ),
                              _buildActionRow(
                                icon: Icons.account_balance_wallet_outlined,
                                iconGradient: const [
                                  Color(0xFF059669),
                                  Color(0xFF10B981),
                                ],
                                title: "Bajeti",
                                count: "",
                                onTap: () {},
                                isLast: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ─ Card & SMS Design ───────────
                          _buildSectionCard(
                            title: "Dizaini Kadi & SMS",
                            rows: [
                              _buildActionRow(
                                icon: Icons.style_outlined,
                                iconGradient: const [
                                  Color(0xFFF59E0B),
                                  Color(0xFFFBBF24),
                                ],
                                title: "Temp za Kadi",
                                count: "$cardTempsNo",
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return Cards(
                                          eId: widget.eventO.id ?? "",
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              _buildActionRow(
                                icon: Icons.sms_outlined,
                                iconGradient: const [
                                  Color(0xFFEF4444),
                                  Color(0xFFF87171),
                                ],
                                title: "Temp za SMS",
                                count: "$evMsgTmpCount",
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return InvEditor(
                                          eId: widget.eventO.id ?? "",
                                        );
                                      },
                                    ),
                                  );
                                },
                                isLast: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ─ Admins & Vendors ────────────
                          _buildSectionCard(
                            title: "Wasimamizi & Vendors",
                            rows: [
                              _buildActionRow(
                                icon: Icons.storefront_outlined,
                                iconGradient: const [
                                  Color(0xFFEC4899),
                                  Color(0xFFF472B6),
                                ],
                                title: "Vendors",
                                count: "$scannersCount",
                                onTap: () async {
                                  showToast(
                                    isGood: true,
                                    msg: "Inakuja hivi karibuni",
                                  );
                                },
                              ),
                              _buildActionRow(
                                icon: Clarity.users_line,
                                iconGradient: const [
                                  Color(0xFF3B82F6),
                                  Color(0xFF60A5FA),
                                ],
                                title: "Wasimamizi",
                                count: "$adminsCount",
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              Users(eId: event?.id ?? ""),
                                    ),
                                  );
                                  loadData();
                                },
                                isLast: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

class ChkpnForm extends StatefulWidget {
  final String eId;
  const ChkpnForm({super.key, required this.eId});

  @override
  State<ChkpnForm> createState() => _ChkpnFormState();
}

class _ChkpnFormState extends State<ChkpnForm> {
  List selCrdsIds = [];
  bool isLoading = false;
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore.collection(ecol).doc(widget.eId).collection(cardcol).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Kard> fcards =
              (snapshot.data as dynamic).docs.map<Kard>((doc) {
                return Kard.fromMap(doc.id, doc.data());
              }).toList();

          return Form(
            key: key,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: psm,
                vertical: 16,
              ),
              children: [
                const Text(
                  "Checkpoint Name",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter checkpoint name",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.edit_rounded,
                      color: Colors.grey[600],
                    ),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Name is required"
                              : null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                if (fcards.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            size: 24,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Accepted Cards",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(fcards.length, (idx) {
                        bool isSelected = selCrdsIds.contains(fcards[idx].id);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? secondaryColor.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? secondaryColor.withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isSelected ? 0.15 : 0.1,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              fcards[idx].type,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            secondary: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color:
                                  isSelected
                                      ? secondaryColor
                                      : Colors.grey[600],
                              size: 28,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (isSelected) {
                                  selCrdsIds.remove(fcards[idx].id);
                                } else {
                                  selCrdsIds.add(fcards[idx].id);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  )
                else
                  _buildEmptyCardsState(),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed:
                      !isLoading
                          ? () async {
                            if (key.currentState?.validate() ?? false) {
                              await crtActn(selCrdsIds: selCrdsIds);
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      else
                        const Icon(Icons.save_rounded, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        isLoading ? "Saving..." : "Save Checkpoint",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center();
        }
        return Center();
      },
    );
  }

  Widget _buildEmptyCardsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              "No Cards Available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> crtActn({selCrdsIds}) async {
    setState(() => isLoading = true);
    try {
      WriteBatch batch = firestore.batch();
      var chkpnRef =
          firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(echecksub)
              .doc();
      List<DocumentReference<Map<String, dynamic>>> crdRefs = [];
      for (var selCrdsId in selCrdsIds) {
        var tmp = firestore
            .collection(ecol)
            .doc(widget.eId)
            .collection(cardcol)
            .doc(selCrdsId);
        crdRefs.add(tmp);
      }
      CheckPoint checkPoint = CheckPoint(
        id: chkpnRef.id,
        name: controller.text,
      );
      batch.set(chkpnRef, checkPoint.toMap());
      for (var crdRef in crdRefs) {
        batch.update(crdRef, {
          crdClrnc: FieldValue.arrayUnion([chkpnRef.id]),
        });
      }
      await batch.commit();
      setState(() => isLoading = false);
      Navigator.pop(context);
      showToast(isGood: true, msg: "Checkpoint created successfully");
    } catch (e) {
      setState(() => isLoading = false);
      showToast(isGood: false, msg: "$e");
    }
  }
}
