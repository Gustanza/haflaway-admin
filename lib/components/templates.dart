import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/in_check.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

buildInvite({
  containz,
  Attendee? rdata,
  KardType kardType = KardType.invitation,
  onChanged,
  eventId,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      return Container(
        margin: EdgeInsets.only(bottom: psm * 0.5),
        decoration: BoxDecoration(
          color: lqassgradBaseColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
        ),
        padding: EdgeInsets.symmetric(vertical: psm * 0.5),
        child: ListTile(
          leading: CupertinoCheckbox(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
              borderRadius: BorderRadius.circular(50),
            ),
            value: containz,
            onChanged: onChanged,
          ),
          title: Text(
            "${rdata?.fullName}",
            style: TextStyle(fontSize: fsm - 1),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: psm * 0.5),
            child: Column(
              children: [
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android, size: icnsm),
                        const SizedBox(width: psm * 0.5),
                        Text("${rdata?.phone}"),
                      ],
                    ),
                    const SizedBox(width: psm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.card_membership, size: icnsm),
                        const SizedBox(width: psm * 0.5),
                        Text("${rdata?.cards[kardType.name]?['name']}"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: psm * 0.75),
                Divider(height: 0, thickness: bdrWidthGen),
                const SizedBox(height: psm * 0.75),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await showCommentDialog(
                          context: context,
                          atId: rdata?.id,
                          eventId: eventId,
                          label: rdata?.idComment,
                        );
                      },
                      child: Icon(Icons.edit_square),
                    ),
                    const SizedBox(width: psm * 0.5),
                    Expanded(
                      child: Text(
                        "${rdata?.idComment}",
                        style: TextStyle(fontSize: fsm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // onTap: onTap,
        ),
      );
    },
  );
}

showCommentDialog({context, eventId, atId, label}) {
  TextEditingController controller = TextEditingController();
  if (label != null) controller.text = label;

  return showDialog(
    context: context,
    builder: (context) {
      return glassDialog(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: psm * 3,
            horizontal: psm * 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Comment",
                style: TextStyle(
                  fontSize: fsm + 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: psm),
              buildField(lbl: label ?? "Comment here", cont: controller),
              const SizedBox(height: psm * 1.5),
              SizedBox(
                width: double.maxFinite,
                child: buildGlassButton(
                  text: "Save Comment",
                  icon: Icons.save,
                  onPressed: () {
                    try {
                      FirebaseFirestore.instance
                          .collection(ecol)
                          .doc(eventId)
                          .collection(atcol)
                          .doc(atId)
                          .set({
                            "idComment": controller.text.trim(),
                          }, SetOptions(merge: true));
                    } catch (e) {
                      showToast(isGood: false, msg: "$e");
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
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
            Text(
              title,
              style: const TextStyle(
                fontSize: fsm + 2,
                fontWeight: FontWeight.w800,
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
          margin: const EdgeInsets.only(bottom: psm * 0.65),
          decoration: BoxDecoration(
            gradient: lqassgrad,
            borderRadius: BorderRadius.circular(bmd),
            border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
          ),
          child: Padding(
            padding: const EdgeInsets.all(psm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(psm * 0.5),
                  decoration: BoxDecoration(
                    color: lqassgradBaseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryWhite, size: 28),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
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

Widget buildActionButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    ),
  );
}

// Glass Wids in the Admin Pane

Widget buildDivider() {
  return Container(
    height: 0.5,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.white.withOpacity(0.1),
  );
}

Widget buildGlassSectionHeader(
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
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
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
      if (showAddButton) buildGlassAddButton(),
    ],
  );
}

Widget buildGlassAddButton() {
  return GestureDetector(
    onTap: () {
      // Navigator.of(
      //   context,
      // ).push(MaterialPageRoute(builder: (context) => PlayGround()));
    }, // showCrtChkpn,
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

Widget buildGlassCard({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      // gradient: lqassgrad,
      // borderRadius: BorderRadius.circular(24),
      // border: lqassbdr,
    ),
    child: child,
  );
}

Widget buildGlassListItem({
  required String title,
  required String subtitle,
  required IconData icon,
  required List<Color> gradient,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: p20, vertical: psm),
      margin: EdgeInsets.only(bottom: psm * 0.65),
      decoration: BoxDecoration(
        gradient: secscagrad,
        borderRadius: BorderRadius.circular(bmd),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(16),
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

Widget buildGlassCheckpointItem(
  BuildContext context,
  Event edata,
  CheckPoint checkpoint,
) {
  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return InCheckWrapper(checkpoint: checkpoint, eId: edata.id ?? "");
          },
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        borderRadius: BorderRadius.circular(bmd),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
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

Widget buildGlassEmptyState() {
  return buildGlassCard(
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

          const SizedBox(height: 32),
          buildGlassButton(
            text: "Create First Checkpoint",
            icon: Icons.add_circle_outline,
            onPressed: null, // showCrtChkpn,
          ),
        ],
      ),
    ),
  );
}

Widget buildGlassErrorView() {
  return buildGlassCard(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
          buildGlassButton(
            text: "Try Again",
            icon: Icons.refresh,
            onPressed: () {},
          ),
        ],
      ),
    ),
  );
}

Widget buildGlassButton({
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
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

Widget buildGlassShimmerLoader() {
  return buildGlassCard(
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

// End Glass Wids in the Admin Pamen

// Global Buttons
buildFloatingBtn({
  required bool mini,
  required String heroTag,
  onPressed,
  required IconData iconData,
}) {
  return FloatingActionButton(
    elevation: 20,
    heroTag: heroTag,
    mini: mini,
    onPressed: onPressed,
    backgroundColor: Colors.white.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusGeometry.circular(40),
      side: BorderSide(color: lqassbdrColor, width: 0.5),
    ),
    child: Icon(iconData, color: mWhite),
  );
}

// End of Global Button

buildActionItem({required String title, required List<ActionItem> children}) {
  return Container(
    decoration: BoxDecoration(
      gradient: lqassgrad,
      border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      borderRadius: BorderRadius.circular(bsm),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(psm),
          child: Text(
            "${title}",
            style: TextStyle(fontSize: fsm + 5, fontWeight: FontWeight.bold),
          ),
        ),
        Divider(thickness: 0.1, height: 0),
        IntrinsicHeight(
          child: Row(
            children: List.generate(children.length + 1, (index) {
              int rindex = index == 0 ? index : index - 1;
              if (index % 2 == 0) {
                return Expanded(
                  child: GestureDetector(
                    onTap: children[rindex].onPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: psm * 2.5,
                        vertical: psm * 2,
                      ),
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${children[rindex].figure}",
                                style: TextStyle(
                                  fontSize: fsm * 2.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              buildActionButton(
                                icon: children[rindex].icon,
                                onTap: () {},
                              ),
                            ],
                          ),
                          Text("${children[rindex].subtitle}"),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return VerticalDivider(thickness: 0.2, width: 0);
              }
            }),
          ),
        ),
      ],
    ),
  );
}

class ActionItem {
  String figure;
  IconData icon;
  String subtitle;
  Function() onPressed;

  ActionItem({
    required this.figure,
    required this.icon,
    required this.subtitle,
    required this.onPressed,
  });
}
