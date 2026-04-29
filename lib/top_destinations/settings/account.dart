import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/top_destinations/settings/notifications/notindex.dart';
import 'package:haflaway/top_destinations/settings/transactions/all_transactions.dart';
import 'package:haflaway/utils/helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — mirrors admin_pane.dart
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg     = Color(0xFF111114);
  static const card   = Color(0xFF1C1C1E);
  static const card2  = Color(0xFF28282C);
  static const sep    = Color(0xFF2C2C2E);
  static const lime   = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white  = Color(0xFFFFFFFF);
  static const lbl1   = Color(0xFFEEEEF0);
  static const lbl2   = Color(0xFFAEAEB2);
  static const lbl3   = Color(0xFF8E8E93);
  static const lbl4   = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Mipangilio — outer shell (streaming)
// ─────────────────────────────────────────────────────────────────────────────

class Mipangilio extends StatefulWidget {
  const Mipangilio({super.key});

  @override
  State<Mipangilio> createState() => _MipangilioState();
}

class _MipangilioState extends State<Mipangilio> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: StreamBuilder(
          stream: firestore.collection(ucol).doc(userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = (snapshot.data as dynamic).data();
              if (data == null) {
                return _buildLoadingScaffold();
              }
              final userr = Userr.fromMap(userId, data);
              return _MyAccountScreen(userr: userr);
            }
            if (snapshot.hasError) {
              return _buildErrorScaffold();
            }
            return _buildLoadingScaffold();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: _T.bg,
      body: const Center(
        child: CupertinoActivityIndicator(color: _T.lime),
      ),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Center(
        child: Text(
          'Something went wrong.',
          style: _T.f(size: 14, color: _T.lbl2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inner screen
// ─────────────────────────────────────────────────────────────────────────────

class _MyAccountScreen extends StatefulWidget {
  final Userr userr;
  const _MyAccountScreen({required this.userr});

  @override
  State<_MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<_MyAccountScreen> {
  int? eventsAffils;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAffiliations();
  }

  Future<void> _loadAffiliations() async {
    final snap = await firestore
        .collection(ecol)
        .where("adminsIds", arrayContains: widget.userr.id)
        .count()
        .get();
    safeState(() => eventsAffils = snap.count);
  }

  void safeState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name =
        '${widget.userr.firstName} ${widget.userr.lastName}'.trim();
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final hue = (name.hashCode % 360).abs().toDouble();
    final avatarColor =
        HSLColor.fromAHSL(1, hue, 0.55, 0.60).toColor();

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
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── Top bar ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: _topBar(),
                  ),
                ),

                // ── Profile hero ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: _profileHero(
                    name: name,
                    initials: initials,
                    avatarColor: avatarColor,
                    email: widget.userr.email ?? '',
                  ),
                ),

                // ── Stats row ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.event_outlined,
                            label: 'AFFILIATIONS',
                            value: '${eventsAffils ?? '—'}',
                            sub: 'events',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'BALANCE',
                            value:
                                '${(widget.userr.balance?.toInt() ?? 0)}',
                            sub: 'TZS',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Preferences section ───────────────────────────────
                SliverToBoxAdapter(child: _sectionHeader('PREFERENCES')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _settingRow(
                          icon: Icons.receipt_long_outlined,
                          label: 'Transactions',
                          sub: 'Preview your cash flow',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AllTransactions(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _settingRow(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          sub: 'Manage notifications',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Notifications(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _settingRow(
                          icon: Icons.lock_outline_rounded,
                          label: 'Security',
                          sub: 'Password and security',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KuresetNenoSiri(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _settingRow(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          sub: 'Contact support',
                          onTap: () async =>
                              await callNumber("+255625689904"),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Danger zone ───────────────────────────────────────
                SliverToBoxAdapter(child: _sectionHeader('ACCOUNT')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _confirmLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Log Out',
                                    style: _T.f(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sign out of your account',
                                    style: _T.f(
                                        size: 12,
                                        color: Colors.red
                                            .withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.red.withValues(alpha: 0.5),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom padding ────────────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.bottom + 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                        color: _T.lbl1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHero({
    required String name,
    required String initials,
    required Color avatarColor,
    required String email,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _T.lime.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _T.lime,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'MY ACCOUNT',
                  style: _T.f(
                    size: 10,
                    weight: FontWeight.w800,
                    color: _T.lime,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Avatar + name + email row
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatarColor.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: _T.f(
                      size: 22,
                      weight: FontWeight.w800,
                      color: avatarColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'No Name' : name,
                      style: _T.f(
                        size: 22,
                        weight: FontWeight.w800,
                        color: _T.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: _T.f(size: 13, color: _T.lbl3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            children: [
              Text(
                label,
                style: _T.f(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _T.lbl3,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _T.lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _T.lime, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: _T.f(
              size: 34,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -1.2,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(sub, style: _T.f(size: 12, color: _T.lbl3)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _T.lime,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: _T.f(
              size: 11,
              weight: FontWeight.w700,
              color: _T.lbl3,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: _T.lime, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: _T.f(
                        size: 15,
                        weight: FontWeight.w500,
                        color: _T.lbl1),
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: _T.f(size: 12, color: _T.lbl3)),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _T.lbl4,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ──────────────────────────────────────────────────────────

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _T.card2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08), width: 0.8),
        ),
        title: Text(
          'Log Out',
          style: _T.f(size: 17, weight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: _T.f(size: 14, color: _T.lbl2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: _T.f(size: 15, color: _T.lbl2)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => Login()),
                (route) => false,
              );
            },
            child: Text(
              'Log Out',
              style: _T.f(
                  size: 15,
                  weight: FontWeight.w600,
                  color: Colors.red),
            ),
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

  const _GusOrb(
      {required this.size, required this.color, this.opacity = 0.05});

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
