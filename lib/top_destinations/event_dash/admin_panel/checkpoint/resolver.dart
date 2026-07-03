import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/services/checkpoint_db.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white   = Color(0xFFFFFFFF);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl2    = Color(0xFFAEAEB2);
  static const lbl3    = Color(0xFF8E8E93);
  static const green   = Color(0xFF30D158);
  static const red     = Color(0xFFFF453A);

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
// AttendeeCheckInView
// ─────────────────────────────────────────────────────────────────────────────

class AttendeeCheckInView extends StatefulWidget {
  final bool showAppBar;
  final String attId;
  final String eId;
  final String chckpntId;
  final Function() onPressed;

  const AttendeeCheckInView({
    Key? key,
    required this.attId,
    required this.eId,
    this.showAppBar = false,
    required this.onPressed,
    required this.chckpntId,
  }) : super(key: key);

  @override
  State<AttendeeCheckInView> createState() => _AttendeeCheckInViewState();
}

class _AttendeeCheckInViewState extends State<AttendeeCheckInView> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final docRef = firestore
        .collection(ecol)
        .doc(widget.eId)
        .collection(atcol)
        .doc(widget.attId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            // Ambient orbs
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

            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(context),
                  Expanded(
                    child: StreamBuilder(
                      stream: docRef.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final data = (snapshot.data as dynamic).data();
                          if (data != null) {
                            final attendee = Attendee.fromMap(
                              widget.attId,
                              data,
                            );
                            return _buildContent(context, attendee, docRef);
                          }
                          return _buildError();
                        }
                        if (snapshot.hasError) return _buildError();
                        return const Center(
                          child: CupertinoActivityIndicator(color: _T.lime),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _topBar(BuildContext context) {
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
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _T.lime,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                'Back',
                style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    Attendee attendee,
    dynamic docRef,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _attendeeCard(attendee),
          const SizedBox(height: 24),
          _sectionLabel('CHECK-IN STATUS'),
          const SizedBox(height: 12),
          ...List.generate(
            attendee.checkinStatus.length,
            (idx) => _checkInItem(
              atSts: attendee.checkinStatus[idx],
              idx: idx,
              attendee: attendee,
              docRef: docRef,
            ),
          ),
          if (!widget.showAppBar) ...[
            const SizedBox(height: 24),
            _scanNextButton(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Attendee card ─────────────────────────────────────────────────────────

  Widget _attendeeCard(Attendee attendee) {
    final source = attendee.cards[KardType.invitation.name];
    final attrCard = source != null ? AttributeCard.fromMap(map: source) : null;
    final cardName = attrCard?.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card type badge — mirrors the "LIVE NOW" treatment
          if (cardName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    cardName.toUpperCase(),
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
          const SizedBox(height: 14),
          // Attendee name — hero title treatment, slightly toned down
          Text(
            attendee.fullName,
            style: _T.f(
              size: 26,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.6,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
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
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Check-in item ─────────────────────────────────────────────────────────

  Widget _checkInItem({
    required Map<String, dynamic> atSts,
    required int idx,
    required Attendee attendee,
    required dynamic docRef,
  }) {
    final bool isIn = atSts[crdChkpns][widget.chckpntId] ?? false;
    final statusColor = isIn ? _T.green : _T.red;
    final name = atSts[cattendeename] ?? 'Guest';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        children: [
          // Status dot with glow
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.45),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Name + status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.f(
                    size: 14,
                    weight: FontWeight.w500,
                    color: _T.lbl1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isIn ? 'Checked in' : 'Not checked in',
                  style: _T.f(size: 12, color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Action button
          GestureDetector(
            onTap: () async {
              if (!isIn) {
                attendee.checkinStatus[idx][crdChkpns][widget.chckpntId] = true;
                docRef.update({'checkinStatus': attendee.checkinStatus});
                CheckpointLocalDB.instance.updateCheckin(
                  widget.attId,
                  attendee.checkinStatus,
                );
              } else {
                await _showCheckout(
                  idx: idx,
                  attendee: attendee,
                  docRef: docRef,
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isIn ? _T.card2 : _T.lime,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isIn ? _T.sep : Colors.transparent,
                  width: 0.8,
                ),
              ),
              child: Text(
                isIn ? 'Checked' : 'Check In',
                style: _T.f(
                  size: 13,
                  weight: FontWeight.w600,
                  color: isIn ? _T.lbl3 : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Checkout dialog ───────────────────────────────────────────────────────

  Future<void> _showCheckout({
    required int idx,
    required dynamic docRef,
    required Attendee attendee,
  }) async {
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: _T.card2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: _T.sep, width: 0.8),
            ),
            title: Text(
              'Checkout',
              style: _T.f(size: 17, weight: FontWeight.w700),
            ),
            content: Text(
              'Are you sure you want to check this person out?',
              style: _T.f(size: 14, color: _T.lbl2, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: _T.f(size: 15, color: _T.lbl2)),
              ),
              TextButton(
                onPressed: () {
                  attendee.checkinStatus[idx][crdChkpns][widget.chckpntId] =
                      false;
                  docRef.update({'checkinStatus': attendee.checkinStatus});
                  CheckpointLocalDB.instance.updateCheckin(
                    widget.attId,
                    attendee.checkinStatus,
                  );
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Checkout',
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w600,
                    color: _T.red,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Scan Next button ──────────────────────────────────────────────────────

  Widget _scanNextButton() {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _T.lime,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _T.lime.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              'Scan Next',
              style: _T.f(size: 15, weight: FontWeight.w700, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _T.lime.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: _T.lime.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: _T.lime, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load attendee',
            style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lbl1),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again',
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
