import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/providers/package_provider.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/models/event.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — same palette as the rest of the app
// ─────────────────────────────────────────────────────────────────────────────

abstract class _E {
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const card3   = Color(0xFF3A3A3C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const lbl1    = Color(0xFFEEEEF0);
  static const lbl2    = Color(0xFFAEAEB2);
  static const lbl3    = Color(0xFF8E8E93);
  static const lbl4    = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = lbl1,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class EventTile extends StatefulWidget {
  final Event eventData;
  final VoidCallback? onRefresh;
  const EventTile({super.key, required this.eventData, this.onRefresh});

  @override
  State<EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<EventTile> {
  final DateFormat _monthFmt = DateFormat('MMM');
  final DateFormat _dayFmt   = DateFormat('d');
  String uid = FirebaseAuth.instance.currentUser?.uid ?? "_";

  @override
  Widget build(BuildContext context) {
    final dt        = widget.eventData.startDate;
    final parsed    = DateTime.parse(dt!);
    final month     = _monthFmt.format(parsed).toUpperCase();
    final day       = _dayFmt.format(parsed);
    final eventfDt  = formatDate(dtime: parsed);
    final prov      = context.read<PackageProvider>();
    final status    = widget.eventData.status ?? 'Draft';
    final isPublished = status.toLowerCase() == 'published';

    return Container(
      decoration: BoxDecoration(
        color: _E.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _E.sep, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ───────────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.28,
                  child: buildImage(url: widget.eventData.eventThumbnail),
                ),
              ),

              // Bottom gradient so the card content below reads cleanly
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Date badge — top-left
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _E.card.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _E.sep, width: 0.8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        month,
                        style: _E.f(
                          size: 10,
                          weight: FontWeight.w800,
                          color: _E.lime,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        day,
                        style: _E.f(
                          size: 22,
                          weight: FontWeight.w800,
                          color: _E.lbl1,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status badge — top-right
              Positioned(
                top: 14,
                right: 14,
                child: _statusBadge(isPublished, status),
              ),
            ],
          ),

          // ── Content ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.eventData.title ?? "",
                  style: _E.f(
                    size: 20,
                    weight: FontWeight.w800,
                    color: _E.lbl1,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Meta row — date/time + location in a single card
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _E.card2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _E.sep, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: _E.lime, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              eventfDt,
                              style: _E.f(size: 13, color: _E.lbl2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((widget.eventData.location ?? '').isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                              height: 1, thickness: 0.5, color: _E.sep),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: _E.lime, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.eventData.location}',
                                style: _E.f(size: 13, color: _E.lbl3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Super-admin actions
                if (prov.isSuperAdmin) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Publish toggle
                      GestureDetector(
                        onTap: () async => await showPublish(
                            eventId: widget.eventData.id ?? "_"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isPublished
                                ? const Color(0xFF30D158).withValues(alpha: 0.12)
                                : _E.card3.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPublished
                                  ? const Color(0xFF30D158).withValues(alpha: 0.4)
                                  : _E.lbl4,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isPublished
                                      ? const Color(0xFF30D158)
                                      : _E.lbl4,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                status.toUpperCase(),
                                style: _E.f(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: isPublished
                                      ? const Color(0xFF30D158)
                                      : _E.lbl4,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Delete
                      GestureDetector(
                        onTap: () async => await showDeleteConfirm(
                            eventId: widget.eventData.id ?? "_"),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF453A).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFF453A).withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: Color(0xFFFF453A),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status badge (non-super-admin view — top-right of image) ───────────────

  Widget _statusBadge(bool isPublished, String status) {
    final color = isPublished ? const Color(0xFF30D158) : _E.lbl4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _E.card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: _E.f(
              size: 9,
              weight: FontWeight.w800,
              color: color,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs (logic unchanged) ──────────────────────────────────────────────

  showDeleteConfirm({eventId}) {
    TextEditingController confirmCon = TextEditingController();
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text("Delete Event"),
              content: Column(
                children: [
                  const Text(
                    "This action is IRREVERSIBLE and will delete all event data. Type \"delete permanently\" to confirm.",
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: confirmCon,
                    placeholder: "delete permanently",
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text("Cancel"),
                  onPressed: () => popper(),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: confirmCon.text == "delete permanently"
                      ? () {
                          FirebaseFirestore.instance
                              .collection(ecol)
                              .doc(eventId)
                              .delete()
                              .then((_) {
                                showToast(isGood: true, msg: "Event Deleted");
                                widget.onRefresh?.call();
                              })
                              .catchError((e) {
                                showToast(isGood: false, msg: "$e");
                              });
                          popper();
                        }
                      : null,
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  showPublish({eventId}) {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Event Status"),
          content: const Text(
            "Beware that this action will impact visibility of this Event to the end-users",
          ),
          actions: [
            CupertinoButton(
              color: Colors.red,
              borderRadius: BorderRadius.zero,
              child: const Text("Unpublish",
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection(ecol)
                    .doc(eventId)
                    .update({"status": "Draft"})
                    .then((_) {
                      showToast(isGood: true, msg: "Event set as Draft");
                      widget.onRefresh?.call();
                    })
                    .catchError((e) => showToast(isGood: false, msg: "$e"));
                popper();
              },
            ),
            CupertinoButton(
              child: const Text("Publish",
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection(ecol)
                    .doc(eventId)
                    .update({"status": "Published"})
                    .then((_) {
                      showToast(isGood: true, msg: "Event has been published");
                      widget.onRefresh?.call();
                    })
                    .catchError((e) => showToast(isGood: false, msg: "$e"));
                popper();
              },
            ),
          ],
        );
      },
    );
  }

  popper() => Navigator.of(context).pop();
}
