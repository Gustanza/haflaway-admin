import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';

buildInvite({containz, rdata, onChanged, onTap}) {
  return Container(
    margin: EdgeInsets.only(bottom: psm * 0.5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ListTile(
      leading: CupertinoCheckbox(value: containz, onChanged: onChanged),
      title: Text(rdata.fullName, style: TextStyle(fontSize: fsm - 1)),
      subtitle: Text(rdata.phone),
      trailing: Container(child: Text(rdata.cardName)),
      onTap: onTap,
    ),
  );
}

Widget buildSectionHeader(String title, IconData icon, Widget? action) {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutQuad,
    builder: (context, opacity, child) {
      return Opacity(
        opacity: opacity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(psm * 0.5),
              decoration: BoxDecoration(
                gradient: primaryGrad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: fsm + 2,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            if (action != null) Spacer(),
            if (action != null) action,
          ],
        ),
      );
    },
  );
}

Widget buildListItemCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  bool isHovered = false;
  return StatefulBuilder(
    builder: (context, setState) {
      return GestureDetector(
        onTapDown: (_) => setState(() => isHovered = true),
        onTapCancel: () => setState(() => isHovered = false),
        onTapUp: (_) {
          setState(() => isHovered = false);
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
          margin: const EdgeInsets.only(bottom: psm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isHovered ? 0.2 : 0.1),
                blurRadius: isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(psm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(psm * 0.5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: fsm,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
