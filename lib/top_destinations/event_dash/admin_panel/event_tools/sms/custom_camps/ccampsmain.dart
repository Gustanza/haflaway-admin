import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/campaign.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/wsap.dart';
import 'package:haflaway/utils/errorstrs.dart';
import 'package:haflaway/utils/globalfns.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF111114);
  static const card = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const sep = Color(0xFF2C2C2E);
  static const lime = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white = Color(0xFFFFFFFF);
  static const lbl1 = Color(0xFFEEEEF0);
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
// AdminCampaigns
// ─────────────────────────────────────────────────────────────────────────────

class AdminCampaigns extends StatefulWidget {
  final Event event;
  final String title;
  final KardType kardType;
  const AdminCampaigns({
    super.key,
    required this.event,
    required this.title,
    required this.kardType,
  });

  @override
  State<AdminCampaigns> createState() => _AdminCampaignsState();
}

class _AdminCampaignsState extends State<AdminCampaigns> {
  final TextEditingController controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
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
            const Positioned(
              bottom: -40,
              left: -80,
              child: _GusOrb(size: 220, color: _T.lime, opacity: 0.06),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: _topBar(),
                  ),
                ),
                SliverToBoxAdapter(child: _titleBlock()),
                StreamBuilder(
                  stream:
                      firestore
                          .collection(ecol)
                          .doc(widget.event.id)
                          .collection(campcol)
                          .where("type", isEqualTo: widget.kardType.name)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final docs = (snapshot.data as dynamic).docs;
                      if (docs.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(),
                        );
                      }
                      final campList =
                          docs
                              .map<Campaign>(
                                (d) => Campaign.fromMap(id: d.id, map: d.data()),
                              )
                              .toList();
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _campCard(campList[i]),
                            childCount: campList.length,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(),
                      );
                    }
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CupertinoActivityIndicator(color: _T.lime),
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 32,
                  ),
                ),
              ],
            ),
          ],
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
          GestureDetector(
            onTap: () => showSelectCard(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _T.lime.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: _T.lime, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    'New',
                    style: _T.f(
                      size: 13,
                      weight: FontWeight.w600,
                      color: _T.lime,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your broadcast campaigns',
            style: _T.f(size: 14, color: _T.lbl3),
          ),
        ],
      ),
    );
  }

  // ── Campaign card ─────────────────────────────────────────────────────────

  Widget _campCard(Campaign camp) {
    final dt = DateTime.tryParse(camp.createdAt ?? '');
    final dateStr =
        dt != null
            ? '${dt.day < 10 ? '0${dt.day}' : dt.day}/'
                '${dt.month < 10 ? '0${dt.month}' : dt.month}/'
                '${dt.year}'
            : (camp.createdAt ?? '');

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => InvitesIssuers(
                  event: widget.event,
                  kardType: widget.kardType,
                  campaignId: camp.id ?? "randy",
                ),
          ),
        );
      },
      onLongPress: () => showSelectCard(campaign: camp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: _T.lime,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camp.name ?? '',
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
                    dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.f(size: 12, color: _T.lbl3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
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
    );
  }

  // ── Create / edit dialog ──────────────────────────────────────────────────

  showSelectCard({Campaign? campaign}) {
    final String flabel = "Campaign name";
    final String blabel = campaign == null ? "Create" : "Save";
    final String tlabel = campaign == null ? "New Campaign" : "Edit Campaign";
    if (campaign != null) controller.text = campaign.name ?? "";
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _T.sep, width: 0.8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tlabel,
                      style: _T.f(
                        size: 20,
                        weight: FontWeight.w800,
                        color: _T.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      style: _T.f(size: 15, color: _T.white),
                      cursorColor: _T.lime,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: flabel,
                        hintStyle: _T.f(size: 15, color: _T.lbl4),
                        filled: true,
                        fillColor: _T.card2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _T.sep,
                            width: 0.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _T.sep,
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _T.lime,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.isEmpty) {
                            showToast(isGood: false, msg: "Name is required");
                            return;
                          }
                          if (campaign == null) {
                            createCamp();
                          } else {
                            editCamp(id: campaign.id ?? "unknown");
                          }
                          controller.clear();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.lime,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          blabel,
                          style: _T.f(
                            size: 15,
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
        );
      },
    );
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  createCamp() {
    Campaign campaign = Campaign(
      name: controller.text.trim(),
      type: widget.kardType.name,
      createdAt: DateTime.now().toIso8601String(),
    );
    firestore
        .collection(ecol)
        .doc(widget.event.id)
        .collection(campcol)
        .add(campaign.toMap())
        .then((v) {
          showToast(isGood: true, msg: "Success");
        })
        .catchError((e) {
          showToast(isGood: false, msg: genErrMsg);
        });
  }

  editCamp({required String id}) {
    Campaign campaign = Campaign(
      name: controller.text.trim(),
      type: widget.kardType.name,
      updatedAt: DateTime.now().toIso8601String(),
    );
    firestore
        .collection(ecol)
        .doc(widget.event.id)
        .collection(campcol)
        .doc(id)
        .set(campaign.toMap(), SetOptions(merge: true))
        .then((v) {
          showToast(isGood: true, msg: "Success");
        })
        .catchError((e) {
          showToast(isGood: false, msg: genErrMsg);
        });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            child: const Icon(Icons.campaign_outlined, size: 32, color: _T.lbl4),
          ),
          const SizedBox(height: 16),
          Text(
            'No campaigns yet',
            style: _T.f(
              size: 16,
              weight: FontWeight.w600,
              color: _T.lbl1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to create your first campaign',
            style: _T.f(size: 13, color: _T.lbl3),
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
              color: _T.lime.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _T.lime.withValues(alpha: 0.2),
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
          Text(
            'Could not load campaigns',
            style: _T.f(size: 13, color: _T.lbl3),
          ),
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

  const _GusOrb({
    required this.size,
    required this.color,
    this.opacity = 0.05,
  });

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
