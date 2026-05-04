import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/logs.dart';
import 'package:haflaway/utils/globalfns.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — identical to account / cards
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

class InvEditor extends StatefulWidget {
  final String eId;
  const InvEditor({super.key, required this.eId});

  @override
  State<InvEditor> createState() => _InvEditorState();
}

class _InvEditorState extends State<InvEditor> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  int? _baseSMS;

  CollectionReference<Map<String, dynamic>> get _col => firestore
      .collection(ecol)
      .doc(widget.eId)
      .collection(eMsgTmpCol);

  @override
  void initState() {
    super.initState();
    _loadBaseSMS();
  }

  Future<void> _loadBaseSMS() async {
    try {
      final eventDoc = await firestore.collection(ecol).doc(widget.eId).get();
      final planId = eventDoc.data()?['eventPlanId'] as String?;
      if (planId == null || planId.isEmpty) return;
      final planDoc = await firestore.collection('eventPlans').doc(planId).get();
      final pricing = planDoc.data()?['pricing'] as Map?;
      final base = pricing?['baseSMS'];
      if (base != null && mounted) setState(() => _baseSMS = (base as num).toInt());
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col.snapshots(),
              builder: (ctx, snap) {
                final docs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final templates = docs
                    .map((e) => MessageTemplate.fromMap(e.id, e.data()))
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

                    if (snap.connectionState == ConnectionState.waiting && docs.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CupertinoActivityIndicator(color: _T.lime)),
                      )
                    else if (snap.hasError)
                      SliverFillRemaining(child: _emptyState(isError: true))
                    else if (docs.isEmpty)
                      SliverFillRemaining(child: _emptyState(isError: false))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _templateCard(templates[i], i),
                            childCount: templates.length,
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
          GestureDetector(
            onTap: () => _showEditor(),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.lime.withValues(alpha: 0.4), width: 0.8),
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
                  'SMS TEMPLATES',
                  style: _T.f(size: 10, weight: FontWeight.w800, color: _T.lime, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Messages',
            style: _T.f(size: 28, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.8, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your broadcast message templates',
            style: _T.f(size: 13, color: _T.lbl3, height: 1.5),
          ),
        ],
      ),
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
              isError ? Icons.error_outline_rounded : Icons.chat_bubble_outline_rounded,
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
            isError ? 'Try again later' : 'Tap + to create your first message',
            style: _T.f(size: 13, color: _T.lbl4),
          ),
        ],
      ),
    );
  }

  // ── Template card ──────────────────────────────────────────────────────────

  Widget _templateCard(MessageTemplate tmpl, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('tmpl_${tmpl.id}'),
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
            // Top row: language badge + actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _T.card2,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _T.sep, width: 0.6),
                  ),
                  child: Text(
                    tmpl.language.toUpperCase(),
                    style: _T.f(size: 9, weight: FontWeight.w700, color: _T.lbl3, letterSpacing: 1.0),
                  ),
                ),
                const Spacer(),
                _actionBtn(
                  icon: Icons.edit_note_rounded,
                  onTap: () => _showEditor(tmpl: tmpl),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  icon: Icons.delete_outline_rounded,
                  iconColor: Colors.redAccent,
                  bgColor: Colors.redAccent.withValues(alpha: 0.08),
                  borderColor: Colors.redAccent.withValues(alpha: 0.2),
                  onTap: () => _confirmDelete(tmpl.id),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 0.8, color: _T.sep),
            const SizedBox(height: 12),

            // Message content
            Text(
              tmpl.content,
              style: _T.f(size: 14, color: _T.lbl2, height: 1.6),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Stats row: char count + SMS pages + cost
            Builder(builder: (_) {
              final chars = tmpl.content.length;
              final pages = (chars / 160).ceil().clamp(1, 999);
              final cost = _baseSMS != null ? pages * _baseSMS! : null;
              return Row(
                children: [
                  _infoChip('$chars chars'),
                  const SizedBox(width: 6),
                  _infoChip('$pages SMS'),
                  if (cost != null) ...[
                    const SizedBox(width: 6),
                    _infoChip('~TZS $cost / send', highlight: true),
                  ],
                ],
              );
            }),

          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? _T.limeDim : _T.card2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? _T.lime.withValues(alpha: 0.35) : _T.sep,
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: _T.f(size: 10, color: highlight ? _T.lime : _T.lbl4),
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

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showEditor({MessageTemplate? tmpl}) {
    final isEdit = tmpl != null;
    final cnt = TextEditingController(text: tmpl?.content ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: modalBtmSheet(
          bdrdm: 28,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _T.lbl4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Icon + title
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _T.limeDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _T.lime.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: _T.lime, size: 20),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isEdit ? 'Edit Template' : 'New Template',
                    style: _T.f(size: 19, weight: FontWeight.w800, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit ? 'Update the message content below' : 'Write your broadcast message',
                    style: _T.f(size: 13, color: _T.lbl3, height: 1.4),
                  ),

                  const SizedBox(height: 20),

                  // TextField
                  TextField(
                    controller: cnt,
                    maxLines: 5,
                    style: _T.f(size: 14, color: _T.white, height: 1.6),
                    cursorColor: _T.lime,
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      hintStyle: _T.f(size: 13, color: _T.lbl4),
                      filled: true,
                      fillColor: _T.card,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _T.sep),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _T.sep),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _T.lime, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _T.card2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _T.sep, width: 0.8),
                            ),
                            alignment: Alignment.center,
                            child: Text('Cancel', style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lbl2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (cnt.text.trim().isEmpty) return;
                            Navigator.pop(ctx);
                            try {
                              if (isEdit) {
                                await _col.doc(tmpl.id).update({'content': cnt.text.trim()});
                              } else {
                                final t = MessageTemplate(
                                  id: '',
                                  category: 'sms_invitation_messages',
                                  content: cnt.text.trim(),
                                  language: 'en',
                                );
                                await _col.add(t.toMap());
                              }
                              showToast(isGood: true, msg: isEdit ? 'Template updated' : 'Template created');
                            } catch (e) {
                              showToast(isGood: false, msg: '$e');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _T.limeDim,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _T.lime.withValues(alpha: 0.4), width: 0.8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isEdit ? 'Save' : 'Create',
                              style: _T.f(size: 15, weight: FontWeight.w700, color: _T.lime),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
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
          'This message template will be permanently removed.',
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
                await _col.doc(id).delete();
                showToast(isGood: true, msg: 'Template deleted');
              } catch (e) {
                showToast(isGood: false, msg: '$e');
              }
            },
            child: Text('Delete', style: _T.f(size: 15, weight: FontWeight.w600, color: Colors.red)),
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
