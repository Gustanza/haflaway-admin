import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
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
  // late AnimationController _fabController;
  // late AnimationController _headerController;
  // late Animation<double> _fabAnimation;
  // late Animation<double> _headerAnimation;

  @override
  void initState() {
    String userId = widget.edata.authorId;
    var provider = Provider.of<BalanceProvider>(context, listen: false);
    provider.startWatchingBalance(userId);
    provider.startWatchingEventPlan(planId: widget.edata.eventPlanId);

    _scrollController.addListener(_onScroll);

    // // Initialize animations
    // _fabController = AnimationController(
    //   duration: const Duration(milliseconds: 800),
    //   vsync: this,
    // );
    // _headerController = AnimationController(
    //   duration: const Duration(milliseconds: 1200),
    //   vsync: this,
    // );

    // _fabAnimation = Curves.elasticOut.animate(_fabController);
    // _headerAnimation = Curves.easeOutCubic.animate(_headerController);

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // _headerController.forward();
        // _fabController.forward();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // _fabController.dispose();
    // _headerController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                  const Color(0xFF0f3460),
                ],
              ),
            ),
          ),

          // Main content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildGlassAppBar(),
              _buildEventHeader(),
              if (widget.isAdmin) _buildAdminToolsSection(),
              _buildCheckpointsSection(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildGlassAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(_isScrolled ? 0.25 : 0.1),
                  Colors.white.withOpacity(_isScrolled ? 0.15 : 0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      title:
          _isScrolled
              ? Text(
                widget.edata.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
              : null,
    );
  }

  SliverToBoxAdapter _buildEventHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              buildImage(url: widget.edata.eventThumbnail),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // Content overlay with glass effect
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.edata.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDateChip(),
                          const SizedBox(height: 16),
                          _buildEventStats(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            formatDate(dtime: widget.edata.calendar[0].eventDate),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventStats() {
    return Row(
      children: [
        _buildStatBubble("Active", "12", Icons.people_rounded),
        const SizedBox(width: 12),
        _buildStatBubble("Check-ins", "8", Icons.check_circle_rounded),
      ],
    );
  }

  Widget _buildStatBubble(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminToolsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildGlassSectionHeader(
              "Admin Tools",
              Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(height: 16),
            _buildGlassCard(
              child: Column(
                children: [
                  _buildGlassListItem(
                    title: "Event Notifications",
                    subtitle: "Manage all event messages and alerts",
                    icon: Clarity.notification_solid,
                    gradient: [
                      const Color(0xFF4CAF50),
                      const Color(0xFF45A047),
                    ],
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => InRem(event: widget.edata),
                          ),
                        ),
                  ),
                  _buildDivider(),
                  _buildGlassListItem(
                    title: "Attendees Management",
                    subtitle: "View and manage event participants",
                    icon: Clarity.user_solid,
                    gradient: [
                      const Color(0xFF2196F3),
                      const Color(0xFF1976D2),
                    ],
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => Attendees(edata: widget.edata),
                          ),
                        ),
                  ),
                  _buildDivider(),
                  _buildGlassListItem(
                    title: "Team Management",
                    subtitle: "Manage staff permissions and roles",
                    icon: Clarity.user_solid_alerted,
                    gradient: [
                      const Color(0xFFFF9800),
                      const Color(0xFFF57C00),
                    ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.1),
    );
  }

  SliverToBoxAdapter _buildCheckpointsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            _buildGlassSectionHeader(
              "Checkpoints",
              Icons.check_circle_outline_rounded,
              showAddButton: widget.isAdmin,
            ),
            const SizedBox(height: 16),
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
                    return _buildGlassEmptyState();
                  }

                  return _buildGlassCard(
                    child: Column(
                      children: List.generate(docs.length, (index) {
                        final isLast = index == docs.length - 1;
                        return Column(
                          children: [
                            _buildGlassCheckpointItem(docs[index]),
                            if (!isLast) _buildDivider(),
                          ],
                        );
                      }),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _buildGlassErrorView();
                }
                return _buildGlassShimmerLoader();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassSectionHeader(
    String title,
    IconData icon, {
    bool showAddButton = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        if (showAddButton) _buildGlassAddButton(),
      ],
    );
  }

  Widget _buildGlassAddButton() {
    return GestureDetector(
      onTap: null, // showCrtChkpn,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.8),
              primaryColor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassListItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCheckpointItem(CheckPoint checkpoint) {
    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) =>
                      InCheck(checkpoint: checkpoint, eId: widget.edata.id),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkpoint.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: ${checkpoint.id}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassEmptyState() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Checkpoints Available",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Create a checkpoint to start managing check-ins",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            if (widget.isAdmin) ...[
              const SizedBox(height: 32),
              _buildGlassButton(
                text: "Create First Checkpoint",
                icon: Icons.add_circle_outline,
                onPressed: null, // showCrtChkpn,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGlassErrorView() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Something Went Wrong",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            _buildGlassButton(
              text: "Try Again",
              icon: Icons.refresh,
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassShimmerLoader() {
    return _buildGlassCard(
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
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
