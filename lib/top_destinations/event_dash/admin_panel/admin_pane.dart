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
import 'package:haflaway/top_destinations/event_dash/admin_panel/users_perms/users.dart';
import 'package:haflaway/top_destinations/event_dash/cards/cards.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/components/gus_scaffold.dart';
import 'package:haflaway/utils/gus_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/attendees.dart';
import 'package:haflaway/components/moving_gradient_border.dart';
import 'package:icons_plus/icons_plus.dart';
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Slick Dark Glass Icon Pill
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [GusTheme.gold, GusTheme.goldLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: GusTheme.textPrimary.withValues(alpha: 0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (count.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "$count items recorded",
                      style: GoogleFonts.inter(
                        color: GusTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: GusTheme.textMuted,
              size: 20,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: GusTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        MovingGradientBorder(
          borderRadius: 24,
          borderWidth: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: GusTheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: List.generate(rows.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      return Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.white.withValues(alpha: 0.08),
                        indent: 72,
                      );
                    }
                    return rows[i ~/ 2];
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error view ──────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.redAccent,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Something went wrong",
              style: GoogleFonts.cormorantGaramond(
                color: GusTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We encountered an error while loading the event data. Please try again.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: GusTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => loadData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: GusTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Retry Now",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── BUILD ─────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (hasError) return GusScaffold(title: "", body: _buildErrorView());
    if (isLoading && event == null) {
      return const GusScaffold(
        title: "",
        body: Center(child: CupertinoActivityIndicator(color: GusTheme.gold)),
      );
    }

    return GusScaffold(
      title: "",
      titleWidget: MovingGradientBorder(
        borderRadius: 8,
        borderWidth: 1.2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            "Admin Panel",
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: GusTheme.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      actions: [
        _floatingButton(
          icon: Icons.settings_rounded,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventSettings(event: event),
              ),
            );
            loadData();
          },
        ),
        const SizedBox(width: 8),
        _floatingButton(
          icon: Icons.edit_rounded,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreateEvent(event: event),
              ),
            );
            loadData();
          },
        ),
        const SizedBox(width: 12),
      ],
      body: RefreshIndicator(
        onRefresh: () async => loadData(),
        color: GusTheme.gold,
        backgroundColor: GusTheme.surface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Hero Section ───────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Premium Hero Image with Glittering Border
                    MovingGradientBorder(
                      borderRadius: 32,
                      borderWidth: 1.2,
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: event?.eventThumbnail ?? "",
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: GusTheme.surface,
                                      child: const Center(
                                        child: CupertinoActivityIndicator(
                                          color: GusTheme.gold,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: GusTheme.surface,
                                      child: const Icon(
                                        Clarity.image_line,
                                        color: GusTheme.textMuted,
                                        size: 48,
                                      ),
                                    ),
                              ),
                              // Deeper Gradient Overlay for Vault-like feel
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.2),
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                              ),
                              // Event Details Overlay
                              Positioned(
                                bottom: 24,
                                left: 24,
                                right: 24,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_formattedDate().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GusTheme.gold.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          _formattedDate().toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: GusTheme.gold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      event?.title ?? "",
                                      style: GoogleFonts.cormorantGaramond(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        height: 1.0,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((event?.location ?? "").isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            color: GusTheme.gold,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              event!.location!,
                                              style: GoogleFonts.inter(
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontSize: 13,
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Dashboard Sections ────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                                builder:
                                    (context) => Attendees(
                                      edata: event!,
                                      kardType: KardType.invitation,
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
                        icon: Clarity.qr_code_line,
                        iconGradient: const [
                          Color(0xFF8B5CF6),
                          Color(0xFFA78BFA),
                        ],
                        title: "Skani Kadi",
                        count: "",
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
                                      kardType: KardType.contribution,
                                      title: "Ratibu Michango",
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
                        onTap: () {
                          showToast(
                            isGood: true,
                            msg: "Feature inakuja hivi karibuni!",
                          );
                        },
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
                              builder:
                                  (context) =>
                                      Cards(eId: widget.eventO.id ?? ""),
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
                              builder:
                                  (context) =>
                                      InvEditor(eId: widget.eventO.id ?? ""),
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
                        onTap: () {
                          showToast(isGood: true, msg: "Inakuja hivi karibuni");
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
                              builder: (context) => Users(eId: event?.id ?? ""),
                            ),
                          );
                          loadData();
                        },
                        isLast: true,
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(
                  "Checkpoint Name",
                  style: GoogleFonts.cormorantGaramond(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: GusTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  style: const TextStyle(
                    color: GusTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter checkpoint name",
                    filled: true,
                    fillColor: GusTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: GusTheme.gold,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_rounded,
                      color: GusTheme.textMuted,
                    ),
                    hintStyle: const TextStyle(color: GusTheme.textMuted),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Name is required"
                              : null,
                  textCapitalization: TextCapitalization.sentences,
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
                            color: GusTheme.gold,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Accepted Cards",
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: GusTheme.textPrimary,
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
                                    ? GusTheme.gold.withOpacity(0.1)
                                    : GusTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? GusTheme.gold.withOpacity(0.5)
                                      : GusTheme.glassBorder,
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
                                  isSelected ? GusTheme.gold : Colors.grey[600],
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
                    backgroundColor: GusTheme.gold,
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
