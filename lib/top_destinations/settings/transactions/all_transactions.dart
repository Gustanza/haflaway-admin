import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/user_transaction.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl3    = Color(0xFF8E8E93);
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

class AllTransactions extends StatefulWidget {
  const AllTransactions({super.key});

  @override
  State<AllTransactions> createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "notset";
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
              child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
            ),
            const Positioned(
              bottom: -40,
              left: -80,
              child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
            ),
            SafeArea(
              bottom: false,
              child: FutureBuilder(
                future: firestore
                    .collection(userTransCol)
                    .where("authorId", isEqualTo: userId)
                    .limit(100)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final docs = (snapshot.data as dynamic).docs;
                    final List<UserTransaction> trns =
                        docs.map<UserTransaction>((doc) {
                          return UserTransaction.fromMap(
                            id: doc.id,
                            map: doc.data(),
                          );
                        }).toList();
                    return _buildScrollView(trns);
                  } else if (snapshot.hasError) {
                    return Column(
                      children: [_topBar(), Expanded(child: buildErr())],
                    );
                  } else {
                    return Column(
                      children: [
                        _topBar(),
                        const Expanded(
                          child: Center(
                            child: CupertinoActivityIndicator(color: _T.lime),
                          ),
                        ),
                      ],
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

  Widget _buildScrollView(List<UserTransaction> trns) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _topBar()),
        SliverToBoxAdapter(child: _titleBlock(trns.length)),
        if (trns.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: BuildNoDt(string: "no transactions yet"),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(index),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(
                      milliseconds: 300 + (index.clamp(0, 12) * 40),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: _buildTransactionCard(trns[index]),
                  );
                },
                childCount: trns.length,
              ),
            ),
          ),
      ],
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
            'Transactions',
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
            '$count recent transaction${count == 1 ? '' : 's'}',
            style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl3),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(UserTransaction trn) {
    final bool isCredit = trn.amount >= 0;
    final Color amountColor = isCredit ? _T.lime : Colors.redAccent;
    final Color amountBg = isCredit
        ? _T.lime.withValues(alpha: 0.1)
        : Colors.redAccent.withValues(alpha: 0.1);
    final String amountStr =
        '${isCredit ? '+' : ''}${formatMoney(trn.amount, decimals: 0)} TZS';

    final dt = DateTime.tryParse(trn.createdAt);
    final timeStr =
        dt != null ? timeago.format(dt, locale: 'en_short') : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: amountBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Reason + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trn.reason,
                  style: _T.f(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _T.lbl1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: _T.f(size: 12, color: _T.lbl3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: amountBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              amountStr,
              style: _T.f(
                size: 13,
                weight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
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
