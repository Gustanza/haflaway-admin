import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/user.dart';

class SearchResults extends StatelessWidget {
  final String eId;
  final List<Userr> users;
  final Function() onFinish;
  final FirebaseFirestore firestore;

  const SearchResults({
    super.key,
    required this.onFinish,
    required this.eId,
    required this.users,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _SearchUserCard(
        userr: users[index],
        eId: eId,
        firestore: firestore,
        onFinish: onFinish,
      ),
    );
  }
}

class _SearchUserCard extends StatelessWidget {
  final Userr userr;
  final String eId;
  final FirebaseFirestore firestore;
  final VoidCallback onFinish;

  const _SearchUserCard({
    required this.userr,
    required this.eId,
    required this.firestore,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SC.sep, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _SC.lime.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: ClipOval(
                    child: userr.profileImage != null && userr.profileImage!.isNotEmpty
                        ? Image.network(userr.profileImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials())
                        : _initials(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${userr.firstName ?? ''} ${userr.lastName ?? ''}".trim(),
                        style: _SC.f(size: 14, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userr.email ?? "",
                        style: _SC.f(size: 12, color: _SC.lbl3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.6, color: _SC.sep),
          _actionBtn(
            label: "Add as Admin",
            icon: Icons.admin_panel_settings_rounded,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            onTap: () {
              firestore.collection(ecol).doc(eId).update({
                'adminsIds': FieldValue.arrayUnion([userr.id]),
              });
              onFinish();
            },
          ),
        ],
      ),
    );
  }

  Widget _initials() {
    final txt =
        "${userr.firstName?.isNotEmpty == true ? userr.firstName![0] : ''}${userr.lastName?.isNotEmpty == true ? userr.lastName![0] : ''}"
            .toUpperCase();
    return Container(
      color: _SC.card2,
      alignment: Alignment.center,
      child: Text(txt.isEmpty ? "?" : txt, style: _SC.f(size: 15, weight: FontWeight.w700, color: _SC.lime)),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required BorderRadius borderRadius,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: _SC.limeDim, borderRadius: borderRadius),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: _SC.lime),
            const SizedBox(width: 6),
            Text(label, style: _SC.f(size: 13, weight: FontWeight.w600, color: _SC.lime)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local design tokens
// ─────────────────────────────────────────────────────────────────────────────

class _SC {
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white   = Color(0xFFFFFFFF);
  static const lbl3    = Color(0xFF8E8E93);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
  }) => GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
}
