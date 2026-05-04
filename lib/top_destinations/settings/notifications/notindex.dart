import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/notication.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — mirrors account.dart
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

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(),
                    _hero(),
                    _tabBar(),
                    const Expanded(
                      child: TabBarView(
                        children: [_GeneralTab(), _ForYouTab()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
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
    );
  }

  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                  'INBOX',
                  style: _T.f(size: 10, weight: FontWeight.w800, color: _T.lime, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Notifications',
            style: _T.f(size: 28, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.8, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            'Stay up to date with your activity',
            style: _T.f(size: 13, color: _T.lbl3, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: _T.lime.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _T.lime.withValues(alpha: 0.45), width: 0.8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelColor: _T.lime,
          unselectedLabelColor: _T.lbl3,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'For You'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab views
// ─────────────────────────────────────────────────────────────────────────────

class _GeneralTab extends StatelessWidget {
  const _GeneralTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(notifCol)
          .where('userId', isEqualTo: 'haflaway')
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) => _buildBody(snap),
    );
  }
}

class _ForYouTab extends StatelessWidget {
  const _ForYouTab();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(notifCol)
          .where('userId', isEqualTo: userId)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) => _buildBody(snap),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared body builder
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildBody(AsyncSnapshot<QuerySnapshot> snap) {
  if (snap.connectionState == ConnectionState.waiting) {
    return const Center(child: CupertinoActivityIndicator(color: _T.lime));
  }
  if (snap.hasError) {
    return _emptyState(isError: true);
  }
  if (!snap.hasData || snap.data!.docs.isEmpty) {
    return _emptyState(isError: false);
  }
  final notifs = snap.data!.docs
      .map((e) => Nottification.fromMap(id: e.id, map: e.data() as Map))
      .toList();
  return ListView.builder(
    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
    itemCount: notifs.length,
    itemBuilder: (_, i) => _notifCard(notifs[i], i),
  );
}

Widget _emptyState({required bool isError}) {
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
            isError ? Icons.error_outline_rounded : Icons.notifications_none_rounded,
            color: _T.lbl4, size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isError ? 'Something went wrong' : 'No notifications',
          style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lbl3),
        ),
        const SizedBox(height: 6),
        Text(
          isError ? 'Try again later' : "You're all caught up",
          style: _T.f(size: 13, color: _T.lbl4),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification card
// ─────────────────────────────────────────────────────────────────────────────

Widget _notifCard(Nottification nott, int index) {
  String timeStr = '';
  final dt = DateTime.tryParse(nott.createdAt ?? '');
  if (dt != null) timeStr = timeago.format(dt, locale: 'en');

  final initial = (nott.senderName ?? 'H').isNotEmpty
      ? (nott.senderName ?? 'H')[0].toUpperCase()
      : 'H';

  return TweenAnimationBuilder<double>(
    key: ValueKey('notif_$index'),
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 200 + (index.clamp(0, 10) * 35)),
    curve: Curves.easeOutCubic,
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _T.lime.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _T.lime.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Center(
              child: Text(
                initial,
                style: _T.f(size: 15, weight: FontWeight.w800, color: _T.lime),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nott.senderName ?? 'Haflaway',
                        style: _T.f(size: 13, weight: FontWeight.w700, color: _T.lbl1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _T.card2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _T.sep, width: 0.6),
                        ),
                        child: Text(timeStr, style: _T.f(size: 10, color: _T.lbl4)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                if ((nott.title ?? '').isNotEmpty)
                  Text(
                    nott.title!,
                    style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lbl1, height: 1.4),
                  ),
                if ((nott.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    nott.description!,
                    style: _T.f(size: 13, color: _T.lbl3, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
