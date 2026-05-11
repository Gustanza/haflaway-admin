import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/zawadi_item.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:intl/intl.dart';

// ─── Design tokens (mirrors admin_pane) ───────────────────────────────────────
class _T {
  static const bg = Color(0xFF111114);
  static const card = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const sep = Color(0xFF2C2C2E);
  static const lime = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const lbl1 = Color(0xFFEEEEF0);
  static const lbl2 = Color(0xFFAEAEB2);
  static const lbl3 = Color(0xFF8E8E93);
  static const green = Color(0xFF32D74B);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = lbl1,
    double? height,
  }) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ZawadiItemDetail extends StatelessWidget {
  final String eventId;
  final ZawadiItem item;

  const ZawadiItemDetail({
    super.key,
    required this.eventId,
    required this.item,
  });

  Stream<ZawadiItem> get _itemStream => FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .collection(zawadiItemsCol)
      .doc(item.id)
      .snapshots()
      .map((s) => ZawadiItem.fromDoc(s));

  Stream<List<ZawadiContribution>> get _contribStream =>
      FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection(zawadiContribCol)
          .where('itemId', isEqualTo: item.id)
          .where('status', isEqualTo: 'PAID')
          .orderBy('paidAt', descending: true)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => ZawadiContribution.fromDoc(d)).toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: StreamBuilder<ZawadiItem>(
        stream: _itemStream,
        initialData: item,
        builder: (context, itemSnap) {
          final live = itemSnap.data ?? item;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar ─────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: _T.bg,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                expandedHeight: 90,
                leading: IconButton(
                  icon: const Icon(CupertinoIcons.chevron_back,
                      color: _T.lbl1, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    live.title,
                    style: _T.f(size: 17, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // ── Progress card ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(psm, 8, psm, 4),
                  child: _ProgressCard(item: live),
                ),
              ),

              // ── Contributors header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(psm, 18, psm, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: _T.lime, size: 14),
                      const SizedBox(width: 7),
                      Text('Contributors',
                          style:
                              _T.f(size: 13, weight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      if (live.contributorCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _T.limeDim,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${live.contributorCount}',
                              style: _T.f(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: _T.lime)),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Contributors list ────────────────────────────────────
              StreamBuilder<List<ZawadiContribution>>(
                stream: _contribStream,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: CupertinoActivityIndicator(
                              color: _T.lime),
                        ),
                      ),
                    );
                  }

                  final contribs = snap.data!;

                  if (contribs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _emptyContribs(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        psm, 0, psm, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: spaceTiles * 2),
                          child: _ContribTile(c: contribs[i]),
                        ),
                        childCount: contribs.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyContribs() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded,
                color: _T.lbl3, size: 32),
            const SizedBox(height: 12),
            Text('No contributions yet',
                style: _T.f(size: 15, weight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('Gifts will appear here once guests contribute',
                style: _T.f(size: 12, color: _T.lbl3)),
          ],
        ),
      ),
    );
  }
}

// ─── Progress card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final ZawadiItem item;
  const _ProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final pct = item.progress;
    final funded = _fmt(item.totalFunded);
    final target = _fmt(item.targetAmount);
    final remaining = _fmt(item.remaining);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (item.description != null && item.description!.isNotEmpty) ...[
            Text(item.description!,
                style: _T.f(size: 13, color: _T.lbl2, height: 1.5)),
            const SizedBox(height: 16),
          ],

          // Ring + stats row
          Row(
            children: [
              // Progress ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 6,
                      backgroundColor: _T.card2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_T.lime),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: pct >= 1 ? _T.green : _T.lime,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow(
                      icon: Icons.trending_up_rounded,
                      label: 'Funded',
                      value: 'TZS $funded',
                      valueColor: _T.lime,
                    ),
                    const SizedBox(height: 8),
                    _statRow(
                      icon: Icons.flag_rounded,
                      label: 'Target',
                      value: 'TZS $target',
                    ),
                    const SizedBox(height: 8),
                    _statRow(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'Remaining',
                      value: 'TZS $remaining',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _T.card2,
              valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 1 ? _T.green : _T.lime),
            ),
          ),

          if (pct >= 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: _T.green, size: 14),
                const SizedBox(width: 5),
                Text('Goal reached!',
                    style: _T.f(
                        size: 12,
                        weight: FontWeight.w600,
                        color: _T.green)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _T.lbl3),
        const SizedBox(width: 5),
        Text('$label  ',
            style: GoogleFonts.inter(fontSize: 12, color: _T.lbl3)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _T.lbl1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)
      return NumberFormat('#,###').format(v.toInt());
    return v.toStringAsFixed(0);
  }
}

// ─── Contributor tile ──────────────────────────────────────────────────────────

class _ContribTile extends StatelessWidget {
  final ZawadiContribution c;
  const _ContribTile({required this.c});

  // Simple deterministic color from name initial
  static const _palette = [
    [Color(0xFF1A3A28), Color(0xFF3DAA76)],
    [Color(0xFF1A2838), Color(0xFF5A8ADB)],
    [Color(0xFF2A1A38), Color(0xFFBF5AF2)],
    [Color(0xFF38200A), Color(0xFFE07040)],
    [Color(0xFF2A2210), Color(0xFFE8C070)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = c.attendeeInitial.codeUnitAt(0) % _palette.length;
    final bg = _palette[idx][0];
    final fg = _palette[idx][1];
    final date = c.paidAt != null
        ? DateFormat('dd MMM yyyy').format(c.paidAt!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                  color: fg.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Center(
              child: Text(
                c.attendeeInitial,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.attendeeName,
                        style: _T.f(
                            size: 14, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'TZS ${_fmt(c.amount)}',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _T.lime),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (c.note != null && c.note!.isNotEmpty) ...[
                  Text(
                    '"${c.note}"',
                    style: _T.f(
                        size: 12,
                        color: _T.lbl2,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                ],
                Text(date,
                    style: _T.f(size: 11, color: _T.lbl3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return NumberFormat('#,###').format(v.toInt());
    return v.toStringAsFixed(0);
  }
}
