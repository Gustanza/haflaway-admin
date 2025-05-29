import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/providers/balance_provider.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/users_perms/users.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/attendees.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/inrem.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'checkpoint/in_check.dart';

class AdminPanel extends StatefulWidget {
  final Event edata;
  final bool isAdmin;
  const AdminPanel({super.key, required this.edata, required this.isAdmin});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();
  double fabScale = 1.0;

  @override
  void initState() {
    String userId = widget.edata.authorId;
    var provider = Provider.of<BalanceProvider>(context, listen: false);
    provider.startWatchingBalance(userId);
    provider.startWatchingEventPlan(planId: widget.edata.eventPlanId);

    _scrollController.addListener(_onScroll);
    // Simulate FAB pulse animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => fabScale = 1.1);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => fabScale = 1.0);
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 80 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 80 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[200]!.withOpacity(_isScrolled ? 0.8 : 0.95),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            _buildEventHeader(),
            if (widget.isAdmin) _buildAdminToolsSection(),
            _buildCheckpointsSection(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: _isScrolled ? 4 : 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: primaryGrad),
      ),
      titleSpacing: 0,
      title: AnimatedOpacity(
        opacity: _isScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Text(
          widget.edata.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildEventHeader() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildImage(url: widget.edata.eventThumbnail),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.edata.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: fsm * 1.75,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Colors.white.withOpacity(0.85),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${formatDate(dtime: widget.edata.calendar[0].eventDate)}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminToolsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: psm, right: psm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: psm),
            buildSectionHeader(
              "Admin Tools",
              Icons.admin_panel_settings_rounded,
              null,
            ),
            const SizedBox(height: psm),
            buildListItemCard(
              title: "Event Notifications",
              subtitle: "Manage all event messages and alerts",
              icon: Clarity.notification_solid,
              color: const Color(0xFF4CAF50),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => InRem(event: widget.edata),
                    ),
                  ),
            ),
            buildListItemCard(
              title: "Attendees Management",
              subtitle: "View and manage event participants",
              icon: Clarity.user_solid,
              color: const Color(0xFF2196F3),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Attendees(edata: widget.edata),
                    ),
                  ),
            ),
            buildListItemCard(
              title: "Team Management",
              subtitle: "Manage staff permissions and roles",
              icon: Clarity.user_solid_alerted,
              color: const Color(0xFFFF9800),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Users(eId: widget.edata.id),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCheckpointsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: psm, right: psm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: psm),
            buildSectionHeader(
              "Checkpoints",
              Icons.check_circle_outline_rounded,
              TextButton(
                onPressed: showCrtChkpn,
                child: Icon(Clarity.plus_line),
              ),
            ),
            const SizedBox(height: psm),
            StreamBuilder(
              stream:
                  firestore
                      .collection(ecol)
                      .doc(widget.edata.id)
                      .collection(echecksub)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<CheckPoint> docs =
                      (snapshot.data as dynamic).docs.map<CheckPoint>((doc) {
                        return CheckPoint.fromMap(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        );
                      }).toList();
                  if (docs.isEmpty) {
                    return _buildEmptyState();
                  }
                  return Column(
                    children: List.generate(
                      docs.length,
                      (index) =>
                          _buildCheckpointCard(docs[index], index: index),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _buildErrorView();
                }
                return _buildShimmerLoader();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointCard(CheckPoint checkpoint, {required int index}) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isHovered = true),
          onTapCancel: () => setState(() => isHovered = false),
          onTapUp: (_) {
            setState(() => isHovered = false);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) =>
                        InCheck(checkpoint: checkpoint, eId: widget.edata.id),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
            margin: const EdgeInsets.only(bottom: psm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(isHovered ? 0.2 : 0.1),
                  blurRadius: isHovered ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(psm),
              child: Row(
                children: [
                  Hero(
                    tag: 'checkpoint-${checkpoint.id}',
                    child: Container(
                      padding: const EdgeInsets.all(psm * 0.5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Clarity.check_circle_line,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checkpoint.name,
                          style: const TextStyle(
                            fontSize: fsm,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "ID: ${checkpoint.id}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              "No Checkpoints Available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Create a checkpoint to start managing check-ins",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (widget.isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: showCrtChkpn,
                icon: const Icon(Icons.add_circle_outline, size: 24),
                label: const Text(
                  "Create First Checkpoint",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              "Something Went Wrong",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, size: 24),
              label: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    // Fallback to CircularProgressIndicator if shimmer is unstable
    try {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: secondaryColor),
        ),
      );
    }
  }

  void showCrtChkpn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[200]!, Colors.white],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: psm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Create Checkpoint",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 32,
                    thickness: 1,
                    indent: psm,
                    endIndent: psm,
                  ),
                  Expanded(child: ChkpnForm(eId: widget.edata.id)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ChkpnForm extends StatefulWidget {
  final String eId;
  const ChkpnForm({super.key, required this.eId});

  @override
  State<ChkpnForm> createState() => _ChkpnFormState();
}

class _ChkpnFormState extends State<ChkpnForm> {
  List selCrdsIds = [];
  bool isLoading = false;
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore.collection(ecol).doc(widget.eId).collection(cardcol).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Kard> fcards =
              (snapshot.data as dynamic).docs.map<Kard>((doc) {
                return Kard.fromMap(doc.id, doc.data());
              }).toList();

          return Form(
            key: key,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: psm,
                vertical: 16,
              ),
              children: [
                const Text(
                  "Checkpoint Name",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter checkpoint name",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.edit_rounded,
                      color: Colors.grey[600],
                    ),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Name is required"
                              : null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                if (fcards.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            size: 24,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Accepted Cards",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(fcards.length, (idx) {
                        bool isSelected = selCrdsIds.contains(fcards[idx].id);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? secondaryColor.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? secondaryColor.withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isSelected ? 0.15 : 0.1,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              fcards[idx].type,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            secondary: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color:
                                  isSelected
                                      ? secondaryColor
                                      : Colors.grey[600],
                              size: 28,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (isSelected) {
                                  selCrdsIds.remove(fcards[idx].id);
                                } else {
                                  selCrdsIds.add(fcards[idx].id);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  )
                else
                  _buildEmptyCardsState(),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed:
                      !isLoading
                          ? () async {
                            if (key.currentState?.validate() ?? false) {
                              await crtActn(selCrdsIds: selCrdsIds);
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      else
                        const Icon(Icons.save_rounded, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        isLoading ? "Saving..." : "Save Checkpoint",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center();
        }
        return Center();
      },
    );
  }

  Widget _buildEmptyCardsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              "No Cards Available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> crtActn({selCrdsIds}) async {
    setState(() => isLoading = true);
    try {
      WriteBatch batch = firestore.batch();
      var chkpnRef =
          firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(echecksub)
              .doc();
      List<DocumentReference<Map<String, dynamic>>> crdRefs = [];
      for (var selCrdsId in selCrdsIds) {
        var tmp = firestore
            .collection(ecol)
            .doc(widget.eId)
            .collection(cardcol)
            .doc(selCrdsId);
        crdRefs.add(tmp);
      }
      CheckPoint checkPoint = CheckPoint(
        id: chkpnRef.id,
        name: controller.text,
      );
      batch.set(chkpnRef, checkPoint.toMap());
      for (var crdRef in crdRefs) {
        batch.update(crdRef, {
          crdClrnc: FieldValue.arrayUnion([chkpnRef.id]),
        });
      }
      await batch.commit();
      setState(() => isLoading = false);
      Navigator.pop(context);
      showToast(isGood: true, msg: "Checkpoint created successfully");
    } catch (e) {
      setState(() => isLoading = false);
      showToast(isGood: false, msg: "$e");
    }
  }
}
