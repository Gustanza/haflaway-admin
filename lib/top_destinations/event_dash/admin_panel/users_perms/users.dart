import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'search.dart';

class Users extends StatefulWidget {
  final String eId;
  const Users({super.key, required this.eId});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Userr> searchResults = [];
  bool isSearchLoading = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> performSearch(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    setState(() => isSearchLoading = true);
    try {
      final res = await firestore.collection(ucol).where("email", isEqualTo: q).get();
      setState(() {
        searchResults = res.docs.map<Userr>((doc) => Userr.fromMap(doc.id, doc.data())).toList();
        isSearchLoading = false;
      });
    } catch (_) {
      setState(() => isSearchLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            const Positioned(top: -80, right: -80, child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11)),
            const Positioned(bottom: -40, left: -80, child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06)),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  if (!isSearching) _titleBlock(),
                  Expanded(
                    child: isSearching
                        ? _searchBody()
                        : StreamBuilder(
                            stream: firestore.collection(ecol).doc(widget.eId).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final data = snapshot.data;
                                if (data!.exists) {
                                  final event = Event.fromMap(data.id, data.data()!);
                                  return _usersList(
                                    event.authorId ?? "",
                                    List<String>.from(event.adminsIds ?? []),
                                    List<String>.from(event.usersIds ?? []),
                                  );
                                } else {
                                  return const BuildNoDt(string: "no data");
                                }
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
          if (!isSearching)
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
          if (isSearching)
            Expanded(
              child: CupertinoSearchTextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  final lower = val.toLowerCase();
                  if (val != lower) {
                    searchController.value = searchController.value.copyWith(
                      text: lower,
                      selection: TextSelection.collapsed(offset: lower.length),
                    );
                  }
                  performSearch(lower);
                },
              ),
            ),
          if (!isSearching) const Spacer(),
          if (!isSearching)
            _iconBtn(icon: Icons.search, onTap: () => setState(() => isSearching = true))
          else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () => setState(() {
                  isSearching = false;
                  searchController.clear();
                  searchResults = [];
                }),
                child: Text("Cancel", style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lime)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manage Teams",
            style: _T.f(size: 28, weight: FontWeight.w800, color: _T.white, letterSpacing: -0.8, height: 1.12),
          ),
          const SizedBox(height: 6),
          Text("Admins & scanning team", style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl3)),
        ],
      ),
    );
  }

  Widget _searchBody() {
    if (isSearchLoading) return buildLoader();
    if (searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.manage_search_rounded, color: _T.lbl4, size: 52),
            const SizedBox(height: 12),
            Text("Enter an email address to find a user", style: _T.f(size: 14, color: _T.lbl3)),
          ],
        ),
      );
    }
    if (searchResults.isEmpty) {
      return GusSearchEmpty.noResults(query: searchController.text);
    }
    return SearchResults(
      firestore: firestore,
      users: searchResults,
      eId: widget.eId,
      onFinish: () => setState(() {
        isSearching = false;
        searchController.clear();
        searchResults = [];
      }),
    );
  }

  Widget _usersList(String oId, List<String> adlist, List<String> ulist) {
    if (adlist.isEmpty && ulist.isEmpty) {
      return const BuildNoDt(string: "no data");
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (adlist.isNotEmpty) ...[
          _sectionLabel("Admins", adlist.length),
          const SizedBox(height: 10),
          ...adlist.map((uid) => UserTile(oId: oId, eId: widget.eId, where: 'adminsIds', firestore: firestore, userId: uid)),
          const SizedBox(height: 24),
        ],
        if (ulist.isNotEmpty) ...[
          _sectionLabel("Scanning Team", ulist.length),
          const SizedBox(height: 10),
          ...ulist.map((uid) => UserTile(oId: oId, eId: widget.eId, where: 'usersIds', firestore: firestore, userId: uid)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, int count) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: _T.f(size: 10, weight: FontWeight.w800, color: _T.lbl4, letterSpacing: 1.0),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _T.card2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _T.sep, width: 0.6),
          ),
          child: Text("$count", style: _T.f(size: 10, weight: FontWeight.w700, color: _T.lbl3)),
        ),
      ],
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Icon(icon, color: _T.lbl2, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class UserTile extends StatefulWidget {
  final String oId;
  final String eId;
  final String where;
  final FirebaseFirestore firestore;
  final String userId;
  const UserTile({
    super.key,
    required this.eId,
    required this.oId,
    required this.userId,
    required this.where,
    required this.firestore,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FutureBuilder(
        future: widget.firestore.collection(ucol).doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data;
            if (data!.exists) {
              return _card(Userr.fromMap(data.id, data.data()!));
            }
            return _placeholder("Data unavailable", loading: false);
          } else if (snapshot.hasError) {
            return _placeholder("Data unavailable", loading: false);
          } else {
            return _placeholder(null, loading: true);
          }
        },
      ),
    );
  }

  Widget _card(Userr userr) {
    final isSuperAdmin = widget.oId == widget.userId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _T.lime.withValues(alpha: 0.3), width: 1.5),
            ),
            child: ClipOval(
              child: userr.profileImage != null && userr.profileImage!.isNotEmpty
                  ? Image.network(userr.profileImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(userr))
                  : _initials(userr),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${userr.firstName ?? ''} ${userr.lastName ?? ''}".trim(),
                  style: _T.f(size: 14, weight: FontWeight.w700, color: _T.lbl1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userr.email ?? "",
                  style: _T.f(size: 12, color: _T.lbl3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSuperAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.lime.withValues(alpha: 0.3), width: 0.6),
              ),
              child: Text("Owner", style: _T.f(size: 11, weight: FontWeight.w700, color: _T.lime)),
            )
          else
            GestureDetector(
              onTap: _showDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25), width: 0.6),
                ),
                child: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initials(Userr userr) {
    final txt = "${userr.firstName?.isNotEmpty == true ? userr.firstName![0] : ''}${userr.lastName?.isNotEmpty == true ? userr.lastName![0] : ''}".toUpperCase();
    return Container(
      color: _T.card2,
      alignment: Alignment.center,
      child: Text(txt.isEmpty ? "?" : txt, style: _T.f(size: 15, weight: FontWeight.w700, color: _T.lime)),
    );
  }

  Widget _placeholder(String? label, {required bool loading}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _T.card2),
            child: loading ? const CupertinoActivityIndicator(color: _T.lime) : null,
          ),
          const SizedBox(width: 12),
          Text(label ?? "Loading...", style: _T.f(size: 14, color: _T.lbl3)),
        ],
      ),
    );
  }

  Future<void> _showDelete() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Remove User"),
        content: const Text("This person will lose access to this event."),
        actions: [
          CupertinoButton(
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
            onPressed: () {
              widget.firestore.collection(ecol).doc(widget.eId).update({
                widget.where: FieldValue.arrayRemove([widget.userId]),
              });
              Navigator.of(context).pop();
            },
          ),
          CupertinoButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
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
  static const lbl4    = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
