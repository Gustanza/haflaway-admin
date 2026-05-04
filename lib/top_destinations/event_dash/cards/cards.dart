import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl3    = Color(0xFF8E8E93);
  static const lbl4    = Color(0xFF48484A);
  static const white   = Color(0xFFFFFFFF);

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

class Cards extends StatefulWidget {
  final String eId;

  const Cards({super.key, required this.eId});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        floatingActionButton: _buildFab(),
        body: Stack(
          children: [
            // Ambient orbs
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

            SafeArea(
              bottom: false,
              child: StreamBuilder(
                stream: firestore
                    .collection(ecol)
                    .doc(widget.eId)
                    .collection(cardcol)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var docs = (snapshot.data as dynamic).docs;
                    List<Kard> cList = docs
                        .map<Kard>((doc) => Kard.fromMap(doc.id, doc.data()))
                        .toList();

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _topBar(),
                              _titleBlock(cList.length),
                            ],
                          ),
                        ),
                        if (cList.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'No templates yet',
                                style: _T.f(color: _T.lbl4),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey(cList[index].id),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds:
                                          300 + (index.clamp(0, 10) * 50),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) =>
                                        Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 14 * (1 - value)),
                                            child: child,
                                          ),
                                        ),
                                    child: _buildCardItem(cList[index]),
                                  );
                                },
                                childCount: cList.length,
                              ),
                            ),
                          ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return buildErr();
                  } else {
                    return const Center(
                      child: CupertinoActivityIndicator(color: _T.lime),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
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
        ],
      ),
    );
  }

  Widget _titleBlock(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Templates',
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.8,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count template${count == 1 ? '' : 's'}',
            style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl3),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(Kard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _T.lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  card.purpose.toUpperCase(),
                  style: _T.f(
                    size: 9,
                    weight: FontWeight.w700,
                    color: _T.lime,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  _actionIcon(
                    icon: Icons.edit_note_rounded,
                    onTap: () async {
                      var url = Uri.parse(
                        "https://haflaway-designer.web.app/designer/${widget.eId}/${card.id}/edit",
                      );
                      try {
                        await launchUrl(url);
                      } catch (e) {
                        showToast(isGood: false, msg: "$e");
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _actionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    onTap: () => cdelete(card),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.type,
            style: _T.f(
              size: 17,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(Icons.people_alt_outlined, 'Capacity: ${card.capacity}'),
              const SizedBox(width: 20),
              _stat(
                Icons.door_sliding_outlined,
                '${card.clearAt.length} Checkpoint${card.clearAt.length == 1 ? '' : 's'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _T.lbl3),
        const SizedBox(width: 6),
        Text(value, style: _T.f(size: 13, color: _T.lbl3)),
      ],
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = _T.lime,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () async {
        var url = Uri.parse(
          "https://haflaway-designer.web.app/designer/${widget.eId}/create",
        );
        try {
          await launchUrl(url);
        } catch (e) {
          showToast(isGood: false, msg: "$e");
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _T.card2,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _T.sep, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: _T.lime, size: 24),
      ),
    );
  }

  cdelete(Kard kard) async {
    return await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            "Delete Template?",
            style: _T.f(weight: FontWeight.bold),
          ),
          content: Text(
            "This will permanently remove this card template. This action cannot be undone.",
            style: _T.f(size: 13),
          ),
          actions: [
            CupertinoButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                try {
                  showProgress(context: context);

                  await firestore
                      .collection(ecol)
                      .doc(widget.eId)
                      .collection(cardcol)
                      .doc(kard.id)
                      .delete();

                  popper();
                  popper();
                  showToast(msg: "Template deleted", isGood: true);
                } catch (e) {
                  showToast(msg: "$e", isGood: false);
                  popper();
                  popper();
                }
              },
            ),
            CupertinoButton(
              child: Text("Cancel", style: _T.f()),
              onPressed: popper,
            ),
          ],
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}

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
