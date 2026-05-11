import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/zawadi_item.dart';
import 'package:haflaway/top_destinations/event_dash/zawadi/zawadi_item_detail.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';

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
  static const red = Color(0xFFFF3B30);
  static const redDim = Color(0xFF2C1010);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = lbl1,
    double? height,
  }) => GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ZawadiDash extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const ZawadiDash({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<ZawadiDash> createState() => _ZawadiDashState();
}

class _ZawadiDashState extends State<ZawadiDash> {
  final _db = FirebaseFirestore.instance;

  // ── Firestore ref ──────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('events').doc(widget.eventId).collection(zawadiItemsCol);

  // ── Sheet form state ───────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── Open add / edit sheet ──────────────────────────────────────────────────
  void _openSheet({ZawadiItem? item}) {
    if (item != null) {
      _titleCtrl.text = item.title;
      _descCtrl.text = item.description ?? '';
      _amountCtrl.text = item.targetAmount.toStringAsFixed(0);
    } else {
      _titleCtrl.clear();
      _descCtrl.clear();
      _amountCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: modalBtmSheet(
          bdrdm: 28,
          child: _SheetForm(
            formKey: _formKey,
            titleCtrl: _titleCtrl,
            descCtrl: _descCtrl,
            amountCtrl: _amountCtrl,
            isEdit: item != null,
            saving: _saving,
            onSave: () => _save(item?.id),
          ),
        ),
      ),
    );
  }

  // ── Save item ──────────────────────────────────────────────────────────────
  Future<void> _save(String? existingId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'targetAmount': amount,
      'currency': 'TZS',
      'isActive': true,
      if (existingId == null) 'totalFunded': 0.0,
      if (existingId == null) 'contributorCount': 0,
      if (existingId == null) 'order': DateTime.now().millisecondsSinceEpoch,
      if (existingId == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      if (existingId != null) {
        await _col.doc(existingId).update(data);
      } else {
        await _col.add(data);
      }
      if (mounted) Navigator.of(context).pop();
      showToast(isGood: true, msg: existingId != null ? 'Updated' : 'Item added');
    } catch (e) {
      showToast(isGood: false, msg: '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete with confirmation ───────────────────────────────────────────────
  void _confirmDelete(ZawadiItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => glassDialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.redDim,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _T.red.withValues(alpha: 0.3), width: 0.8),
                ),
                child: const Icon(Icons.warning_rounded,
                    color: _T.red, size: 24),
              ),
              const SizedBox(height: 16),
              Text('Delete Item',
                  style: _T.f(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Delete "${item.title}"? This cannot be undone.',
                style: _T.f(size: 14, color: _T.lbl2, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _col.doc(item.id).delete();
                        showToast(isGood: true, msg: 'Deleted');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _T.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _T.red.withValues(alpha: 0.4), width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: Text('Delete',
                            style: _T.f(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _T.red)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        alignment: Alignment.center,
                        child: Text('Cancel',
                            style: _T.f(
                                size: 14,
                                weight: FontWeight.w600,
                                color: _T.lbl2)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar (mirrors admin_pane pill-back pattern) ────────────────────────
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
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _T.lime, size: 13),
                  const SizedBox(width: 5),
                  Text('Back',
                      style: _T.f(
                          size: 13,
                          weight: FontWeight.w500,
                          color: _T.lbl1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero block (mirrors admin_pane _heroBlock pattern) ─────────────────────
  Widget _heroBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _T.lime.withValues(alpha: 0.35), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.card_giftcard_rounded,
                    color: _T.lime, size: 11),
                const SizedBox(width: 6),
                Text(
                  'GIFT OF LOVE',
                  style: _T.f(
                      size: 10,
                      weight: FontWeight.w800,
                      color: _T.lime),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.eventTitle,
            style: _T.f(
                size: 28,
                weight: FontWeight.w800,
                color: const Color(0xFFFFFFFF),
                height: 1.15),
          ),
          const SizedBox(height: 4),
          Text('Gift fund items',
              style: _T.f(size: 13, color: _T.lbl3)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(),
        backgroundColor: _T.lime,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Stack(
        children: [
          // ── Ambient orbs ──────────────────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
          ),
          Positioned(
            bottom: -40,
            left: -80,
            child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
          ),

          // ── Content ───────────────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _col.orderBy('order').snapshots(),
            builder: (context, snap) {
              final items = snap.hasData
                  ? snap.data!.docs
                      .map((d) => ZawadiItem.fromDoc(d))
                      .toList()
                  : <ZawadiItem>[];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_topBar(), _heroBlock()],
                      ),
                    ),
                  ),

                  if (items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SummaryStrip(items: items),
                    ),

                  if (!snap.hasData)
                    const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(color: _T.lime),
                      ),
                    ),

                  if (snap.hasData && items.isEmpty)
                    SliverFillRemaining(child: _emptyState()),

                  if (items.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(psm, 12, psm, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: spaceTiles * 2),
                            child: _ItemTile(
                              item: items[i],
                              onTap: () => navNormal(
                                context: context,
                                widget: ZawadiItemDetail(
                                  eventId: widget.eventId,
                                  item: items[i],
                                ),
                              ),
                              onEdit: () => _openSheet(item: items[i]),
                              onDelete: () => _confirmDelete(items[i]),
                            ),
                          ),
                          childCount: items.length,
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 32,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _T.limeDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _T.lime.withValues(alpha: 0.25), width: 0.8),
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: _T.lime, size: 36),
          ),
          const SizedBox(height: 20),
          Text('No gift items yet',
              style: _T.f(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tap + to add your first Gift of Love item',
              style: _T.f(size: 13, color: _T.lbl3)),
        ],
      ),
    );
  }
}

// ─── Summary strip ─────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final List<ZawadiItem> items;
  const _SummaryStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalTarget =
        items.fold<double>(0, (s, i) => s + i.targetAmount);
    final totalFunded =
        items.fold<double>(0, (s, i) => s + i.totalFunded);
    final totalContribs =
        items.fold<int>(0, (s, i) => s + i.contributorCount);
    final pct =
        totalTarget > 0 ? (totalFunded / totalTarget * 100).clamp(0, 100) : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.limeDim,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _T.lime.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stat('${items.length}', 'Items'),
                _divider(),
                _stat('${pct.toStringAsFixed(0)}%', 'Done'),
                _divider(),
                _stat('$totalContribs', 'Gifts'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(height: 0.5, color: _T.sep),
            ),
            Row(
              children: [
                Text('Funded  ',
                    style: GoogleFonts.inter(fontSize: 11, color: _T.lbl3)),
                Text('TZS ${_fmt(totalFunded)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.lime)),
                const Spacer(),
                Text('Target  ',
                    style: GoogleFonts.inter(fontSize: 11, color: _T.lbl3)),
                Text('TZS ${_fmt(totalTarget)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _T.lbl2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String val, String lbl) => Expanded(
        child: Column(
          children: [
            Text(val,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.lime),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(lbl,
                style: GoogleFonts.inter(
                    fontSize: 10, color: _T.lbl3)),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 0.5,
        height: 28,
        color: _T.sep,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Item tile ─────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final ZawadiItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (item.progress * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _T.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _T.lime.withValues(alpha: 0.2), width: 0.8),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: _T.lime, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _T.lbl1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(item.description!,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: _T.lbl3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _T.card2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.ellipsis,
                        color: _T.lbl3, size: 15),
                  ),
                  color: _T.card2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: _T.sep, width: 0.8),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(CupertinoIcons.pencil,
                            color: _T.lbl2, size: 16),
                        const SizedBox(width: 10),
                        Text('Edit',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: _T.lbl1)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(CupertinoIcons.trash,
                            color: _T.red, size: 16),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: _T.red)),
                      ]),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Progress bar ────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 5,
                backgroundColor: _T.card2,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(_T.lime),
              ),
            ),

            const SizedBox(height: 10),

            // ── Amounts + badge row ─────────────────────────────────
            Row(
              children: [
                Text(
                  'TZS ${_fmt(item.totalFunded)}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _T.lime),
                ),
                Text(
                  ' / TZS ${_fmt(item.targetAmount)}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _T.lbl3),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _T.card2,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _T.sep, width: 0.8),
                  ),
                  child: Text(
                    '$pct%',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.progress >= 1
                            ? const Color(0xFF32D74B)
                            : _T.lbl2),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _T.card2,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _T.sep, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded,
                          size: 10, color: _T.lbl3),
                      const SizedBox(width: 4),
                      Text('${item.contributorCount}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _T.lbl2)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Sheet form ────────────────────────────────────────────────────────────────

class _SheetForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController amountCtrl;
  final bool isEdit;
  final bool saving;
  final VoidCallback onSave;

  const _SheetForm({
    required this.formKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.amountCtrl,
    required this.isEdit,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon + title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _T.limeDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _T.lime.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: _T.lime, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit Item' : 'New Gift Item',
                  style: _T.f(size: 18, weight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Title field
            _label('Item Name'),
            const SizedBox(height: 6),
            _field(
              controller: titleCtrl,
              hint: 'e.g. Honeymoon Trip to Zanzibar',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            // Description field
            _label('Description (optional)'),
            const SizedBox(height: 6),
            _field(
              controller: descCtrl,
              hint: 'Short note about this item…',
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            // Target amount field
            _label('Target Amount (TZS)'),
            const SizedBox(height: 6),
            _field(
              controller: amountCtrl,
              hint: 'e.g. 500000',
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                if ((double.tryParse(v.trim()) ?? 0) <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 26),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.lime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: saving ? null : onSave,
                child: saving
                    ? const CupertinoActivityIndicator(color: Colors.black)
                    : Text(
                        isEdit ? 'Save Changes' : 'Add Item',
                        style: _T.f(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Colors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: _T.f(size: 12, color: _T.lbl3, weight: FontWeight.w500));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _T.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.sentences,
        maxLines: maxLines,
        style: _T.f(size: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _T.f(size: 14, color: _T.lbl3),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
        validator: validator,
      ),
    );
  }
}

// ─── Ambient orb (mirrors admin_pane._GusOrb) ─────────────────────────────────

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
