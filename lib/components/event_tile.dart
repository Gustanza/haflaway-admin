import 'dart:ui' show ImageFilter;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/models/event.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — same palette as the rest of the app
// ─────────────────────────────────────────────────────────────────────────────

abstract class _E {
  static const card    = Color(0xFF1C1C1E);
static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const lbl1    = Color(0xFFEEEEF0);
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

          // ── Thumbnail + overlaid content ────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: const Radius.circular(20),
            ),
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  buildImage(url: widget.eventData.eventThumbnail),

                  // Gradient — heavier at the bottom so text is readable
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.30),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0.30, 0.58, 1.0],
                      ),
                    ),
                  ),

                  // Date badge — top-left
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _E.card.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _E.sep, width: 0.8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(month, style: _E.f(size: 10, weight: FontWeight.w800, color: _E.lime, letterSpacing: 1.2)),
                          Text(day,   style: _E.f(size: 22, weight: FontWeight.w800, color: _E.lbl1, height: 1.1)),
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

                  // Title + meta — anchored to bottom of image
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.eventData.title ?? '',
                          style: _E.f(
                            size: 21,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: _E.lime, size: 13),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                eventfDt,
                                style: _E.f(size: 12, color: Colors.white.withValues(alpha: 0.75)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if ((widget.eventData.location ?? '').isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: _E.lime, size: 13),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.eventData.location!,
                                  style: _E.f(size: 12, color: Colors.white.withValues(alpha: 0.60)),
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
                ],
              ),
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

}

// ─────────────────────────────────────────────────────────────────────────────
// EventCardHero — full-bleed carousel card (Apple Invites style)
// ─────────────────────────────────────────────────────────────────────────────

class EventCardHero extends StatelessWidget {
  final Event eventData;
  const EventCardHero({super.key, required this.eventData});

  @override
  Widget build(BuildContext context) {
    final parsed       = DateTime.parse(eventData.startDate!);
    final formattedDt  = formatDate(dtime: parsed);
    final status       = eventData.status ?? 'Draft';
    final isPublished  = status.toLowerCase() == 'published';
    final attendeeCount = (eventData.usersIds ?? []).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed image
          buildImage(url: eventData.eventThumbnail),

          // 2. Top vignette — keeps badges readable against bright photos
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 130,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x73000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // 3. Bottom frosted glass zone — blurs the image behind it
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _frostedZone(formattedDt, attendeeCount),
          ),

          // 4. "Hosting" badge — top-left
          Positioned(top: 16, left: 16, child: _hostingBadge()),

          // 5. Status badge — top-right
          Positioned(top: 16, right: 16, child: _statusBadge(isPublished, status)),
        ],
      ),
    );
  }

  Widget _frostedZone(String formattedDt, int attendeeCount) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white],
        stops: [0.0, 0.28],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x44000000), Color(0x88000000)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 180),
              if (attendeeCount > 0) ...[
                _attendeeRow(attendeeCount),
                const SizedBox(height: 14),
              ],
              Text(
                eventData.title ?? '',
                style: _E.f(
                  size: 26,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: _E.lime, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formattedDt,
                      style: _E.f(size: 12, color: Color(0xBFFFFFFF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if ((eventData.location ?? '').isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: _E.lime, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        eventData.location!,
                        style: _E.f(size: 12, color: Color(0x99FFFFFF)),
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
      ),
    ),
  );
  }

  Widget _attendeeRow(int total) {
    const avatarColors = [
      Color(0xFF5E5CE6),
      Color(0xFFFF6B6B),
      Color(0xFF30D158),
      Color(0xFFFF9F0A),
      Color(0xFF64D2FF),
    ];
    final shown = total.clamp(0, 5);

    return Row(
      children: [
        SizedBox(
          height: 28,
          width: shown * 20.0 + 8,
          child: Stack(
            children: List.generate(shown, (i) => Positioned(
              left: i * 20.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColors[i % avatarColors.length],
                  border: Border.all(color: const Color(0x99000000), width: 1.5),
                ),
                child: const Icon(Icons.person, size: 13, color: Colors.white),
              ),
            )),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$total attending',
          style: _E.f(size: 12, weight: FontWeight.w600, color: Color(0xCCFFFFFF)),
        ),
      ],
    );
  }

  Widget _hostingBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x61000000),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded, color: _E.lime, size: 14),
              const SizedBox(width: 6),
              Text('Hosting', style: _E.f(size: 12, weight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isPublished, String status) {
    final color = isPublished ? const Color(0xFF30D158) : const Color(0xFF48484A);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x59000000),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                status.toUpperCase(),
                style: _E.f(size: 9, weight: FontWeight.w800, color: color, letterSpacing: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
