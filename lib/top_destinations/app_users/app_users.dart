import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/gus_theme.dart';

class AppUsersScreen extends StatefulWidget {
  const AppUsersScreen({super.key});

  @override
  State<AppUsersScreen> createState() => _AppUsersScreenState();
}

class _AppUsersScreenState extends State<AppUsersScreen> {
  int pageSize = 6;
  List<Userr> users = [];
  bool isLoading = false;
  bool isSearching = false;
  String selectedStatus = 'All';
  String selectedClearance = 'All';
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  popper() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    loadUsers();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent) {
      if (!isLoading) {
        loadMoreUsers();
      }
    }
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  loadUsers() async {
    safeState(() {
      isLoading = true;
      users.clear();
      lastDocument = null;
    });
    try {
      Query query = firestore.collection(ucol);

      if (searchQuery.isNotEmpty) {
        String q = searchQuery.toLowerCase();
        query = query
            .where(usearchName, isGreaterThanOrEqualTo: q)
            .where(usearchName, isLessThanOrEqualTo: "$q\uf8ff")
            .orderBy(usearchName);
      } else {
        query = query.orderBy('registrationDate', descending: true);
      }

      QuerySnapshot<Map<String, dynamic>> res =
          await (query as Query<Map<String, dynamic>>).limit(pageSize).get();

      if (res.docs.isNotEmpty) {
        lastDocument = res.docs.last;
      }

      users =
          res.docs.map<Userr>((e) {
            return Userr.fromMap(e.id, e.data());
          }).toList();
    } catch (e) {
      showToast(isGood: false, msg: "$e");
      debugPrint("Load Error: $e");
    }
    safeState(() {
      isLoading = false;
    });
  }

  loadMoreUsers() async {
    if (lastDocument == null) return;

    safeState(() {
      isLoading = true;
    });
    try {
      Query query = firestore.collection(ucol);

      if (searchQuery.isNotEmpty) {
        String q = searchQuery.toLowerCase();
        query = query
            .where(usearchName, isGreaterThanOrEqualTo: q)
            .where(usearchName, isLessThanOrEqualTo: "$q\uf8ff")
            .orderBy(usearchName);
      } else {
        query = query.orderBy('registrationDate', descending: true);
      }

      QuerySnapshot<Map<String, dynamic>> res =
          await (query as Query<Map<String, dynamic>>)
              .startAfterDocument(lastDocument!)
              .limit(pageSize)
              .get();

      if (res.docs.isNotEmpty) {
        lastDocument = res.docs.last;
        List<Userr> tmpusers =
            res.docs.map<Userr>((e) {
              return Userr.fromMap(e.id, e.data());
            }).toList();
        users.addAll(tmpusers);
      }
    } catch (e) {
      showToast(isGood: false, msg: "$e");
      debugPrint("Load More Error: $e");
    }
    safeState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            // Ambient Orbs
            const Positioned(
              top: -100,
              right: -60,
              child: _GusOrb(
                size: 300,
                color: Color(0xFFC9A84C),
                opacity: 0.08,
              ),
            ),
            const Positioned(
              bottom: 100,
              left: -80,
              child: _GusOrb(
                size: 250,
                color: Color(0xFFC9A84C),
                opacity: 0.05,
              ),
            ),

            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async => await loadUsers(),
                color: const Color(0xFFC9A84C),
                backgroundColor: const Color(0xFF141414),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _topBar()),
                    SliverToBoxAdapter(child: _heroTitle()),
                    if (isSearching)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverToBoxAdapter(
                          child: CupertinoSearchTextField(
                            controller: searchController,
                            placeholder: "Search users...",
                            placeholderStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (v) {
                              searchQuery = v;
                              loadUsers();
                            },
                            onSubmitted: (v) {
                              searchQuery = v;
                              loadUsers();
                            },
                          ),
                        ),
                      ),
                    if (users.isEmpty && isLoading)
                      SliverFillRemaining(child: buildLoader())
                    else if (users.isEmpty && !isLoading)
                      SliverFillRemaining(
                        child: BuildNoDt(
                          string: "No Users Found",
                          isRefreshed: () async {
                            await loadUsers();
                          },
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == users.length) {
                              if (isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CupertinoActivityIndicator(
                                      color: GusTheme.gold,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox(height: 100);
                            }
                            final user = users[index];
                            return _buildUserCard(userr: user);
                          }, childCount: users.length + 1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => popper(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFC9A84C),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  safeState(() {
                    isSearching = !isSearching;
                    if (!isSearching) {
                      searchQuery = "";
                      searchController.clear();
                      loadUsers();
                    }
                  });
                },
                child: Icon(
                  isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: const Color(0xFFC9A84C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Msajili()),
                  );
                  loadUsers();
                },
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFC9A84C),
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "App Users",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage your organization's members",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({required Userr userr}) {
    final isActive = userr.isActive ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GusTheme.gold.withOpacity(0.3),
                      GusTheme.gold.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: GusTheme.glassBorder),
                ),
                child: const Icon(Icons.person_rounded, color: GusTheme.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${userr.firstName} ${userr.lastName}",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userr.phoneNumber ?? "No Phone Number",
                      style: GoogleFonts.inter(
                        color: GusTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _cardAction(
                icon: Icons.edit_note_rounded,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Msajili(userr: userr),
                    ),
                  );
                  loadUsers();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildModernChip(
                  label: isActive ? "Active" : "Suspended",
                  icon:
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                  color: isActive ? GusTheme.green : GusTheme.red,
                  onTap: () => alterStatus(userr: userr),
                ),
                const SizedBox(width: 8),
                _buildModernChip(
                  label: "TZS ${userr.balance?.toInt() ?? 0}",
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFC9A84C),
                  onTap: () => alterBalance(userr: userr),
                ),
                const SizedBox(width: 8),
                _buildModernChip(
                  label: "Lvl ${userr.clearanceLevel ?? 0}",
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFFC9A84C),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildModernChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  alterStatus({required Userr userr}) {
    bool isActive = userr.isActive ?? false;
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: StatefulBuilder(
            builder: (context, settState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${userr.firstName} ${userr.lastName}",
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Update Account Status",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: GusTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          "Active Account",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          isActive
                              ? "User can access all features"
                              : "User access is restricted",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: GusTheme.textMuted,
                          ),
                        ),
                        value: isActive,
                        activeColor: GusTheme.green,
                        onChanged: (v) {
                          settState(() {
                            isActive = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GusTheme.gold,
                          foregroundColor: GusTheme.obsidian,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          firestore
                              .collection(ucol)
                              .doc(userr.id)
                              .set({
                                "isActive": isActive,
                              }, SetOptions(merge: true))
                              .then((o) {
                                showToast(isGood: true, msg: "Status Updated");
                                loadUsers();
                              });
                          popper();
                        },
                        child: Text(
                          "Save Changes",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => popper(),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          color: GusTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  alterBalance({required Userr userr}) {
    bool overwriteSgn = false;
    GlobalKey<FormState> key = GlobalKey<FormState>();
    TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: StatefulBuilder(
            builder: (context, settState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${userr.firstName} ${userr.lastName}",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Manage Wallet Balance",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: GusTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      buildField(
                        lbl: "Amount (e.g. 5000)",
                        filled: true,
                        cont: controller,
                        type: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: SwitchListTile(
                          value: overwriteSgn,
                          activeColor: GusTheme.gold,
                          title: Text(
                            "Overwrite Balance",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "Current Balance: TZS ${userr.balance?.toInt() ?? 0}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: GusTheme.gold.withOpacity(0.7),
                            ),
                          ),
                          onChanged: (v) {
                            settState(() {
                              overwriteSgn = v;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GusTheme.gold,
                            foregroundColor: GusTheme.obsidian,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            bool isValid =
                                key.currentState?.validate() ?? false;
                            if (!isValid) return;
                            try {
                              double balanc =
                                  double.tryParse(controller.text) ?? 0.00;
                              firestore
                                  .collection(ucol)
                                  .doc(userr.id)
                                  .set({
                                    "balance":
                                        overwriteSgn
                                            ? balanc
                                            : FieldValue.increment(balanc),
                                  }, SetOptions(merge: true))
                                  .then((o) {
                                    showToast(
                                      isGood: true,
                                      msg: "Balance Updated",
                                    );
                                    loadUsers();
                                  });
                              popper();
                            } catch (e) {
                              showToast(isGood: false, msg: "$e");
                            }
                          },
                          child: Text(
                            "Confirm Update",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => popper(),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            color: GusTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

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
        color: color.withOpacity(opacity),
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
