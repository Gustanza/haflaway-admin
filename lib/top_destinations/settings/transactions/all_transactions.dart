import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/user_transaction.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — mirrors account.dart
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg    = Color(0xFF111114);
  static const card  = Color(0xFF1C1C1E);
  static const sep   = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white = Color(0xFFFFFFFF);
  static const lbl1  = Color(0xFFEEEEF0);
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

class AllTransactions extends StatefulWidget {
  const AllTransactions({super.key});

  @override
  State<AllTransactions> createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
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
              top: -80, right: -80,
              child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
            ),
            const Positioned(
              bottom: -40, left: -80,
              child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
            ),
            FutureBuilder<QuerySnapshot>(
              future: firestore
                  .collection(userTransCol)
                  .where("authorId", isEqualTo: userId)
                  .limit(100)
                  .get(),
              builder: (ctx, snap) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(bottom: false, child: _topBar()),
                    ),
                    SliverToBoxAdapter(child: _hero()),
                    if (snap.connectionState == ConnectionState.waiting)
                      const SliverFillRemaining(
                        child: Center(
                          child: CupertinoActivityIndicator(color: _T.lime),
                        ),
                      )
                    else if (snap.hasError || !snap.hasData || snap.data!.docs.isEmpty)
                      SliverFillRemaining(child: _empty(snap.hasError))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final doc = snap.data!.docs[i];
                              final trn = UserTransaction.fromMap(
                                id: doc.id,
                                map: doc.data() as Map,
                              );
                              return _trxCard(trn, i);
                            },
                            childCount: snap.data!.docs.length,
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
                  const Icon(Icons.arrow_back_ios_new_rounded, color: _T.lime, size: 13),
                  const SizedBox(width: 5),
                  Text('Back', style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1)),
                ],
              ),
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
                  'CASH FLOW',
                  style: _T.f(size: 10, weight: FontWeight.w800, color: _T.lime, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Transactions',
            style: _T.f(size: 28, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.8, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            'Your recent payment activity',
            style: _T.f(size: 13, color: _T.lbl3, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _empty(bool isError) {
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
              isError ? Icons.error_outline_rounded : Icons.receipt_long_outlined,
              color: _T.lbl4, size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isError ? 'Something went wrong' : 'No transactions yet',
            style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lbl3),
          ),
          const SizedBox(height: 6),
          Text(
            isError ? 'Try again later' : 'Your cash flow will appear here',
            style: _T.f(size: 13, color: _T.lbl4),
          ),
        ],
      ),
    );
  }

  Widget _trxCard(UserTransaction trn, int index) {
    String timeStr = '—';
    final dt = DateTime.tryParse(trn.createdAt);
    if (dt != null) timeStr = timeago.format(dt, locale: 'en');

    return TweenAnimationBuilder<double>(
      key: ValueKey('trn_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 220 + (index.clamp(0, 10) * 40)),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: _T.lime, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trn.reason,
                    style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lbl1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(timeStr, style: _T.f(size: 11, color: _T.lbl4)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'TZS ${formatMoney(trn.amount)}',
                style: _T.f(size: 12, weight: FontWeight.w700, color: _T.lime),
              ),
            ),
          ],
        ),
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
