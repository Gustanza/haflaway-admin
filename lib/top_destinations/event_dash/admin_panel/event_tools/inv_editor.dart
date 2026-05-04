import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/logs.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/utils/globalwids.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl2    = Color(0xFFAEAEB2);
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

class InvEditor extends StatefulWidget {
  final String eId;
  const InvEditor({super.key, required this.eId});

  @override
  State<InvEditor> createState() => _InvEditorState();
}

class _InvEditorState extends State<InvEditor> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  int? _baseSMS;
  bool _loadingPlan = true;

  @override
  void initState() {
    super.initState();
    _loadBaseSMS();
  }

  Future<void> _loadBaseSMS() async {
    try {
      final eventSnap = await firestore.collection(ecol).doc(widget.eId).get();
      final eventPlanId = eventSnap.data()?['eventPlanId'] as String?;
      if (eventPlanId == null || eventPlanId.isEmpty) {
        if (mounted) setState(() => _loadingPlan = false);
        return;
      }

      final planSnap =
          await firestore.collection(eplancol).doc(eventPlanId).get();
      final data = planSnap.data();
      if (data == null) {
        if (mounted) setState(() => _loadingPlan = false);
        return;
      }

      // Try pricing.baseSMS first, fall back to smsinvmsgprice
      int? base;
      final pricing = data['pricing'];
      if (pricing is Map) {
        base = (pricing['baseSMS'] as num?)?.toInt();
      }
      base ??= (data['smsinvmsgprice'] as num?)?.toInt();

      if (mounted) setState(() { _baseSMS = base; _loadingPlan = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  int _smsSegments(String content) =>
      content.isEmpty ? 1 : (content.length / 160).ceil();

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
                  _topBar(),
                  Expanded(
                    child: StreamBuilder(
                      stream: firestore
                          .collection(ecol)
                          .doc(widget.eId)
                          .collection(eMsgTmpCol)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var docs = (snapshot.data as dynamic).docs;
                          List<MessageTemplate> msgTmps =
                              docs.map<MessageTemplate>((e) {
                                return MessageTemplate.fromMap(e.id, e.data());
                              }).toList();
                          return _buildBody(msgTmps);
                        } else if (snapshot.hasError) {
                          return buildErr();
                        } else {
                          return buildLoader();
                        }
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
          const Spacer(),
          GestureDetector(
            onTap: () async => await showCreate(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _T.lime.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: _T.lime, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    'New',
                    style: _T.f(
                      size: 13,
                      weight: FontWeight.w600,
                      color: _T.lime,
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
            'Messages',
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
            '$count template${count == 1 ? '' : 's'}',
            style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl3),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<MessageTemplate> msgTmps) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _titleBlock(msgTmps.length)),
        if (msgTmps.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: BuildNoDt(string: "no templates yet"),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(msgTmps[index].id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(
                      milliseconds: 300 + (index.clamp(0, 10) * 50),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: _buildTemplateCard(msgTmps[index], index),
                  );
                },
                childCount: msgTmps.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateCard(MessageTemplate tmpl, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _T.lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TEMPLATE ${index + 1}',
                  style: _T.f(
                    size: 9,
                    weight: FontWeight.w700,
                    color: _T.lime,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              _actionIcon(
                icon: Icons.edit_note_rounded,
                onTap: () async => await showCreate(msgTmp: tmpl),
              ),
              const SizedBox(width: 8),
              _actionIcon(
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
                onTap: () async => await showDelete(id: tmpl.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tmpl.content,
            style: _T.f(size: 14, color: _T.lbl2, height: 1.55),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: _T.sep),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.sms_outlined, size: 12, color: _T.lbl3),
              const SizedBox(width: 5),
              Text(
                '${tmpl.content.length} chars · ${_smsSegments(tmpl.content)} SMS',
                style: _T.f(size: 12, color: _T.lbl3),
              ),
              const Spacer(),
              if (_loadingPlan)
                Container(
                  width: 56,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _T.card2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else if (_baseSMS != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _T.limeDim,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _T.lime.withValues(alpha: 0.3),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    'TZS ${_smsSegments(tmpl.content) * _baseSMS!}',
                    style: _T.f(
                      size: 11,
                      weight: FontWeight.w700,
                      color: _T.lime,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = _T.lime,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  showCreate({MessageTemplate? msgTmp}) async {
    final bool isEdit = msgTmp != null;
    final TextEditingController cnt = TextEditingController(
      text: isEdit ? msgTmp.content : '',
    );

    return await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                    right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20, top: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _T.lime.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _T.lime.withValues(alpha: 0.25),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_note_rounded
                                  : Icons.add_rounded,
                              color: _T.lime,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Template' : 'New Template',
                            style: _T.f(
                              size: 18,
                              weight: FontWeight.w700,
                              color: _T.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      buildField(cont: cnt),
                      const SizedBox(height: 20),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: _T.f(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: _T.lbl2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (cnt.text.trim().isEmpty) return;
                                if (isEdit) {
                                  firestore
                                      .collection(ecol)
                                      .doc(widget.eId)
                                      .collection(eMsgTmpCol)
                                      .doc(msgTmp.id)
                                      .update({'content': cnt.text.trim()});
                                } else {
                                  final newTmpl = MessageTemplate(
                                    id: 'id',
                                    category: 'sms_invitation_messages',
                                    content: cnt.text.trim(),
                                    language: 'en',
                                  );
                                  firestore
                                      .collection(ecol)
                                      .doc(widget.eId)
                                      .collection(eMsgTmpCol)
                                      .add(newTmpl.toMap());
                                }
                                Navigator.of(ctx).pop();
                              },
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _T.lime,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  isEdit ? 'Save' : 'Create',
                                  style: _T.f(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
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
      },
    );
  }

  showDelete({String? id}) async {
    return await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Delete Template?"),
          content: const Text(
            "This template will be permanently removed and cannot be undone.",
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: popper,
              child: const Text("Cancel"),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                firestore
                    .collection(ecol)
                    .doc(widget.eId)
                    .collection(eMsgTmpCol)
                    .doc(id)
                    .delete();
                popper();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
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
