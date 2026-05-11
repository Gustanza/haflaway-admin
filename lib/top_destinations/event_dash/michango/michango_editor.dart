import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/mchango.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — same palette as admin_pane / attendees
// ─────────────────────────────────────────────────────────────────────────────

abstract class _T {
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl2    = Color(0xFFAEAEB2);
  static const lbl3    = Color(0xFF8E8E93);
  static const red     = Color(0xFFFF3B30);
  static const redDim  = Color(0xFF2C1210);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = lbl1,
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

class MichangoEditor extends StatefulWidget {
  final Attendee attendee;
  final String eventId;
  const MichangoEditor({
    super.key,
    required this.attendee,
    required this.eventId,
  });

  @override
  State<MichangoEditor> createState() => _MichangoEditorState();
}

class _MichangoEditorState extends State<MichangoEditor> {
  GlobalKey<FormState> key = GlobalKey<FormState>();
  double? pledgedAmount;
  double? paidAmount;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController ahadiController   = TextEditingController();
  TextEditingController mchangoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // ── Summary card ────────────────────────────────────────────
                  SliverToBoxAdapter(child: _summaryCard()),

                  // ── Add Contribution button ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _addContributionBtn(),
                    ),
                  ),

                  // ── History section header ──────────────────────────────────
                  SliverToBoxAdapter(child: _sectionHeader("CONTRIBUTION HISTORY")),

                  // ── History list ────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverToBoxAdapter(
                      child: StreamBuilder(
                        stream: firestore
                            .collection(ecol)
                            .doc(widget.eventId)
                            .collection(atcol)
                            .doc(widget.attendee.id)
                            .collection(atPaySub)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            var docs = (snapshot.data as dynamic).docs;
                            if (docs.isEmpty) return _emptyHistory();
                            List<Mchango> list = docs
                                .map<Mchango>((e) => Mchango.fromMap(e.id, e.data()))
                                .toList();
                            return _michangoList(list);
                          }
                          if (snapshot.hasError) return _errorView();
                          return buildLoader();
                        },
                      ),
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

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar: back pill + pledge action ─────────────────────────────
        Padding(
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
              const Spacer(),
              // Record pledge button
              GestureDetector(
                onTap: () => _showMoneyInput(
                  title: "Record Pledge",
                  controller: ahadiController,
                  label: "Pledge Amount",
                  initialAmount: pledgedAmount,
                  onPressed: () {
                    bool ok = key.currentState?.validate() ?? false;
                    try {
                      if (ok) {
                        setPledge();
                        popper();
                      }
                    } catch (e) {
                      debugPrint("Shida: $e");
                    }
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _T.limeDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _T.lime.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded, color: _T.lime, size: 14),
                      const SizedBox(width: 6),
                      Text('Pledge',
                          style: _T.f(
                              size: 13,
                              weight: FontWeight.w700,
                              color: _T.lime)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Title block ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            widget.attendee.fullName,
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.lbl1,
              letterSpacing: -0.8,
              height: 1.12,
            ),
          ),
        ),
      ],
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────

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
          Text(label,
              style: _T.f(
                  size: 11,
                  weight: FontWeight.w700,
                  color: _T.lbl3,
                  letterSpacing: 1.3)),
        ],
      ),
    );
  }

  // ── Summary card (pledge / contribution stats) ──────────────────────────────

  Widget _summaryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: StreamBuilder(
        stream: firestore
            .collection(ecol)
            .doc(widget.eventId)
            .collection(atcol)
            .doc(widget.attendee.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            try {
              final fresh = Attendee.fromMap(
                  snapshot.data!.id, snapshot.data!.data()!);
              pledgedAmount = fresh.pledgedAmount;
              paidAmount    = fresh.paidAmount;
            } catch (_) {}
          }
          final pledge = pledgedAmount ?? 0.0;
          final paid   = paidAmount ?? 0.0;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.sep, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: _T.lime.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pledge column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PLEDGE',
                          style: _T.f(
                              size: 10,
                              weight: FontWeight.w700,
                              color: _T.lbl3,
                              letterSpacing: 1.1)),
                      const SizedBox(height: 6),
                      Text(
                        formatMoney(pledge, currency: 'TZS', currencyBefore: true),
                        style: _T.f(
                            size: 17,
                            weight: FontWeight.w800,
                            color: _T.lbl1,
                            letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: _T.sep,
                ),
                // Contribution column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONTRIBUTION',
                          style: _T.f(
                              size: 10,
                              weight: FontWeight.w700,
                              color: _T.lbl3,
                              letterSpacing: 1.1)),
                      const SizedBox(height: 6),
                      Text(
                        formatMoney(paid, currency: 'TZS', currencyBefore: true),
                        style: _T.f(
                            size: 17,
                            weight: FontWeight.w800,
                            color: _T.lime,
                            letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Add Contribution button ─────────────────────────────────────────────────

  Widget _addContributionBtn() {
    return GestureDetector(
      onTap: () => _showMoneyInput(
        title: "Record Contribution",
        controller: mchangoController,
        label: "Contribution Amount",
        onPressed: () {
          bool ok = key.currentState?.validate() ?? false;
          try {
            if (ok) {
              setMchango(amount: double.parse(mchangoController.text));
              popper();
            }
          } catch (e) {
            debugPrint("Shidar: $e");
          }
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _T.limeDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _T.lime.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: _T.lime, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Add Contribution',
                style: _T.f(
                    size: 16, weight: FontWeight.w700, color: _T.lime)),
          ],
        ),
      ),
    );
  }

  // ── Contribution history list ───────────────────────────────────────────────

  Widget _michangoList(List<Mchango> michango) {
    return Column(
      children: michango.map((m) => _michangoItem(m)).toList(),
    );
  }

  Widget _michangoItem(Mchango m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMoneyInput(
            title: "Edit Contribution",
            controller: mchangoController,
            label: "Contribution Amount",
            initialAmount: m.amount,
            onPressed: () {
              bool ok = key.currentState?.validate() ?? false;
              try {
                if (ok) {
                  setMchango(
                      amount: double.parse(mchangoController.text),
                      id: m.id);
                  popper();
                }
              } catch (e) {
                debugPrint("Shida: $e");
              }
            },
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _T.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: _T.lime, size: 22),
                ),
                const SizedBox(width: 14),
                // Amount + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TZS ${(m.amount ?? 0).toStringAsFixed(0)}',
                        style: _T.f(
                            size: 17,
                            weight: FontWeight.w700,
                            color: _T.lbl1),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(m.createdAt),
                        style: _T.f(size: 12, color: _T.lbl2),
                      ),
                    ],
                  ),
                ),
                // Edit / delete — only for manual entries
                if (m.method == PayMethod.manual) ...[
                  _iconBtn(
                    icon: Icons.edit_rounded,
                    color: _T.lime,
                    onTap: () => _showMoneyInput(
                      title: "Edit Contribution",
                      controller: mchangoController,
                      label: "Contribution Amount",
                      initialAmount: m.amount,
                      onPressed: () {
                        bool ok = key.currentState?.validate() ?? false;
                        try {
                          if (ok) {
                            setMchango(
                                amount:
                                    double.parse(mchangoController.text),
                                id: m.id);
                            popper();
                          }
                        } catch (e) {
                          debugPrint("Shida: $e");
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(
                    icon: Icons.delete_forever_rounded,
                    color: _T.red,
                    onTap: () => _confirmDel(mchango: m),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _T.card2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ── Empty / error states ────────────────────────────────────────────────────

  Widget _emptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.card2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: _T.lbl3, size: 28),
          ),
          const SizedBox(height: 14),
          Text('No contributions yet',
              style: _T.f(
                  size: 15,
                  weight: FontWeight.w600,
                  color: _T.lbl2)),
          const SizedBox(height: 4),
          Text('Tap "Add Contribution" above to record one',
              style: _T.f(size: 12, color: _T.lbl3)),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text('Failed to load history',
            style: _T.f(size: 14, color: _T.lbl3)),
      ),
    );
  }

  // ── Money input dialog ──────────────────────────────────────────────────────

  void _showMoneyInput({
    dynamic initialAmount,
    required String title,
    required TextEditingController controller,
    required String label,
    required VoidCallback onPressed,
  }) {
    if (initialAmount != null) controller.text = initialAmount.toString();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _T.limeDim,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _T.lime.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child:
                      const Icon(Icons.edit_rounded, color: _T.lime, size: 24),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: _T.f(
                        size: 20,
                        weight: FontWeight.w800,
                        color: _T.lbl1,
                        letterSpacing: -0.4)),
                const SizedBox(height: 20),
                // Input field
                Container(
                  decoration: BoxDecoration(
                    color: _T.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.sep, width: 0.8),
                  ),
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: _T.f(size: 16, weight: FontWeight.w600, color: _T.lbl1),
                    decoration: InputDecoration(
                      hintText: label,
                      hintStyle: _T.f(size: 14, color: _T.lbl3),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter an amount';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.lime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: onPressed,
                    child: Text('Save Record',
                        style: _T.f(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete confirmation dialog ──────────────────────────────────────────────

  void _confirmDel({required Mchango mchango}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.redDim,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _T.red.withValues(alpha: 0.3), width: 0.8),
                ),
                child: const Icon(Icons.warning_rounded, color: _T.red, size: 24),
              ),
              const SizedBox(height: 16),
              Text('Delete Record',
                  style: _T.f(
                      size: 20,
                      weight: FontWeight.w800,
                      color: _T.lbl1,
                      letterSpacing: -0.4)),
              const SizedBox(height: 10),
              Text(
                'You are about to delete a contribution of TZS ${mchango.amount}. This cannot be undone.',
                style: _T.f(size: 14, color: _T.lbl2, height: 1.45),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Delete
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.red,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        firestore
                            .collection(ecol)
                            .doc(widget.eventId)
                            .collection(atcol)
                            .doc(widget.attendee.id)
                            .collection(atPaySub)
                            .doc(mchango.id)
                            .delete()
                            .then((_) => showToast(isGood: true, msg: "Deleted"))
                            .catchError(
                                (e) => showToast(isGood: false, msg: "$e"));
                        popper();
                      },
                      child: Text('Delete',
                          style: _T.f(
                              size: 14,
                              weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _T.lbl2,
                        side: const BorderSide(color: _T.sep, width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: popper,
                      child: Text('Cancel',
                          style: _T.f(
                              size: 14,
                              weight: FontWeight.w600,
                              color: _T.lbl2)),
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final d = DateTime.parse(dateString);
      return '${d.day}/${d.month}/${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown';
    }
  }

  void setPledge() {
    firestore
        .collection(ecol)
        .doc(widget.eventId)
        .collection(atcol)
        .doc(widget.attendee.id)
        .set(
          {'pledgedAmount': double.tryParse(ahadiController.text) ?? 0},
          SetOptions(merge: true),
        )
        .then((_) {
          showToast(isGood: true, msg: "Saved");
          ahadiController.clear();
        })
        .catchError((e) => showToast(isGood: false, msg: "$e"));
  }

  void setMchango({dynamic amount, String? id}) {
    final mchango = Mchango(
      amount: amount ?? 0,
      createdAt: DateTime.now().toIso8601String(),
    );
    final colRef = firestore
        .collection(ecol)
        .doc(widget.eventId)
        .collection(atcol)
        .doc(widget.attendee.id)
        .collection(atPaySub);
    final docId = id ?? colRef.doc().id;
    colRef
        .doc(docId)
        .set(mchango.toMap(), SetOptions(merge: true))
        .then((_) {
          showToast(isGood: true, msg: "Saved");
          mchangoController.clear();
        })
        .catchError((e) => showToast(isGood: false, msg: "$e"));
  }

  void popper() => Navigator.of(context).pop();
}
