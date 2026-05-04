import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — identical to account / admin_pane
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg    = Color(0xFF111114);
  static const card  = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const sep   = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white = Color(0xFFFFFFFF);
  static const lbl1  = Color(0xFFEEEEF0);
  static const lbl2  = Color(0xFFAEAEB2);
  static const lbl3  = Color(0xFF8E8E93);
  static const lbl4  = Color(0xFF48484A);

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

class Cards extends StatefulWidget {
  final String eId;
  const Cards({super.key, required this.eId});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> _openDesigner(String path) async {
    final url = Uri.parse("https://haflaway-designer.web.app/designer/$path");
    try {
      await launchUrl(url);
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            // Ambient orbs
            const Positioned(
              top: -80, right: -80,
              child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
            ),
            const Positioned(
              bottom: -40, left: -80,
              child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection(ecol)
                  .doc(widget.eId)
                  .collection(cardcol)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.hasData
                    ? (snapshot.data as dynamic).docs as List
                    : <dynamic>[];
                final cList = docs
                    .map<Kard>((doc) => Kard.fromMap(doc.id, doc.data()))
                    .toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(bottom: false, child: _topBar()),
                    ),
                    SliverToBoxAdapter(child: _hero()),

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        docs.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: CupertinoActivityIndicator(color: _T.lime),
                        ),
                      )
                    else if (snapshot.hasError)
                      SliverFillRemaining(child: _empty(isError: true))
                    else if (docs.isEmpty)
                      SliverFillRemaining(child: _empty(isError: false))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _cardItem(cList[i], i),
                            childCount: cList.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          // Back
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
                  const Icon(Icons.arrow_back_ios_new_rounded, color: _T.lime, size: 13),
                  const SizedBox(width: 5),
                  Text('Back', style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1)),
                ],
              ),
            ),
          ),
          const Spacer(),
          // New template
          GestureDetector(
            onTap: () => _openDesigner('${widget.eId}/create'),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _T.lime.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: const Icon(Icons.add_rounded, color: _T.lime, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _T.lime.withValues(alpha: 0.35), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: _T.lime, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'CARD TEMPLATES',
                  style: _T.f(size: 10, weight: FontWeight.w800, color: _T.lime, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Templates',
            style: _T.f(size: 28, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.8, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            'Design and manage your invitation cards',
            style: _T.f(size: 13, color: _T.lbl3, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _empty({required bool isError}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _T.card,
              shape: BoxShape.circle,
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: Icon(
              isError ? Icons.error_outline_rounded : Icons.desktop_windows_outlined,
              color: _T.lbl4, size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isError ? 'Something went wrong' : 'No templates yet',
            style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lbl3),
          ),
          const SizedBox(height: 6),
          Text(
            isError ? 'Try again later' : 'Tap + to design your first card',
            style: _T.f(size: 13, color: _T.lbl4),
          ),
        ],
      ),
    );
  }

  // ── Card item ──────────────────────────────────────────────────────────────

  Widget _cardItem(Kard card, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('card_${card.id}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 220 + (index.clamp(0, 8) * 50)),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.sep, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _T.lime.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: purpose badge + action buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _T.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _T.lime.withValues(alpha: 0.25), width: 0.6),
                  ),
                  child: Text(
                    card.purpose.toUpperCase(),
                    style: _T.f(size: 9, weight: FontWeight.w800, color: _T.lime, letterSpacing: 1.2),
                  ),
                ),
                const Spacer(),
                _actionBtn(
                  icon: Icons.edit_note_rounded,
                  onTap: () => _openDesigner('${widget.eId}/${card.id}/edit'),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  icon: Icons.delete_outline_rounded,
                  iconColor: Colors.redAccent,
                  bgColor: Colors.redAccent.withValues(alpha: 0.08),
                  borderColor: Colors.redAccent.withValues(alpha: 0.2),
                  onTap: () => _confirmDelete(card),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Type — main title
            Text(
              card.type,
              style: _T.f(size: 18, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.5, height: 1.1),
            ),

            const SizedBox(height: 12),

            // Divider
            Container(height: 0.8, color: _T.sep),

            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _stat(Icons.people_alt_outlined, 'Capacity', '${card.capacity}'),
                const SizedBox(width: 20),
                _stat(Icons.door_sliding_outlined, 'Checkpoints', '${card.clearAt.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _T.card2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.sep, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _T.lbl3),
          const SizedBox(width: 6),
          Text(
            '$label · $value',
            style: _T.f(size: 12, weight: FontWeight.w500, color: _T.lbl2),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = _T.lime,
    Color bgColor = _T.limeDim,
    Color borderColor = const Color(0x66C9A84C),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }

  // ── Delete confirm ─────────────────────────────────────────────────────────

  void _confirmDelete(Kard kard) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _T.card2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
        ),
        title: Text('Delete Template?', style: _T.f(size: 17, weight: FontWeight.w700)),
        content: Text(
          'This will permanently remove this card template. This action cannot be undone.',
          style: _T.f(size: 14, color: _T.lbl2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: _T.f(size: 15, color: _T.lbl2)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                showProgress(context: context);
                await firestore
                    .collection(ecol)
                    .doc(widget.eId)
                    .collection(cardcol)
                    .doc(kard.id)
                    .delete();
                popper();
                showToast(msg: "Template deleted", isGood: true);
              } catch (e) {
                showToast(msg: "$e", isGood: false);
                popper();
              }
            },
            child: Text('Delete', style: _T.f(size: 15, weight: FontWeight.w600, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void popper() => Navigator.of(context).pop();
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
      width: size, height: size,
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
