import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/notication.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:timeago/timeago.dart' as timeago;

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

// ─────────────────────────────────────────────────────────────────────────────
// Notifications screen
// ─────────────────────────────────────────────────────────────────────────────

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DefaultTabController(
        length: 2,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(context),
                    _titleBlock(),
                    _tabBar(),
                    const Expanded(
                      child: TabBarView(
                        children: [
                          GeneralNotifications(),
                          ForYouNotification(),
                        ],
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

  Widget _topBar(BuildContext context) {
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

  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
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
            'Updates and alerts for your account',
            style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl3),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: TabBar(
          labelColor: _T.white,
          unselectedLabelColor: _T.lbl3,
          labelStyle: _T.f(size: 13, weight: FontWeight.w600),
          unselectedLabelStyle: _T.f(size: 13),
          dividerHeight: 0,
          indicator: BoxDecoration(
            color: _T.card2,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _T.sep, width: 0.8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
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
// General tab
// ─────────────────────────────────────────────────────────────────────────────

class GeneralNotifications extends StatefulWidget {
  const GeneralNotifications({super.key});

  @override
  State<GeneralNotifications> createState() => _GeneralNotificationsState();
}

class _GeneralNotificationsState extends State<GeneralNotifications> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(notifCol)
          .where('userId', isEqualTo: "haflaway")
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = (snapshot.data as dynamic).docs;
          if (docs.isEmpty) {
            return const BuildNoDt(string: "no notifications yet");
          }
          final List<Nottification> notList = docs
              .map<Nottification>((e) =>
                  Nottification.fromMap(id: e.id, map: e.data()))
              .toList();
          return _buildList(notList);
        } else if (snapshot.hasError) {
          return buildErr();
        } else {
          return const Center(
            child: CupertinoActivityIndicator(color: _T.lime),
          );
        }
      },
    );
  }

  Widget _buildList(List<Nottification> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          key: ValueKey(items[index].id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 280 + (index.clamp(0, 12) * 35)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: _NotifCard(nott: items[index]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// For You tab
// ─────────────────────────────────────────────────────────────────────────────

class ForYouNotification extends StatefulWidget {
  const ForYouNotification({super.key});

  @override
  State<ForYouNotification> createState() => _ForYouNotificationState();
}

class _ForYouNotificationState extends State<ForYouNotification> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "_id";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(notifCol)
          .where('userId', isEqualTo: userId)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = (snapshot.data as dynamic).docs;
          if (docs.isEmpty) {
            return const BuildNoDt(string: "no notifications yet");
          }
          final List<Nottification> notList = docs
              .map<Nottification>((e) =>
                  Nottification.fromMap(id: e.id, map: e.data()))
              .toList();
          return _buildList(notList);
        } else if (snapshot.hasError) {
          return buildErr();
        } else {
          return const Center(
            child: CupertinoActivityIndicator(color: _T.lime),
          );
        }
      },
    );
  }

  Widget _buildList(List<Nottification> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          key: ValueKey(items[index].id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 280 + (index.clamp(0, 12) * 35)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: _NotifCard(nott: items[index]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification card
// ─────────────────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final Nottification nott;
  const _NotifCard({required this.nott});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(nott.createdAt ?? '');
    final timeStr = dt != null ? timeago.format(dt, locale: 'en_short') : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _T.lime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: _T.lime,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nott.senderName ?? 'Haflaway',
                        style: _T.f(
                          size: 12,
                          weight: FontWeight.w700,
                          color: _T.lime,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: _T.f(size: 11, color: _T.lbl4),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  nott.title ?? '',
                  style: _T.f(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _T.lbl1,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((nott.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    nott.description!,
                    style: _T.f(size: 13, color: _T.lbl3, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
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
