import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/resolver.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:http/http.dart' as http;

// ── Design tokens — mirrors attendees.dart ────────────────────────────────────
class _T {
  static const bg = Color(0xFF111114);
  static const card = Color(0xFF1C1C1E);
  static const sep = Color(0xFF2C2C2E);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const lbl1 = Color(0xFFEEEEF0);
  static const lbl3 = Color(0xFF8E8E93);
  static const lbl4 = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

// ── Search delegate ───────────────────────────────────────────────────────────

class CheckPnSearchDelegate extends SearchDelegate {
  final String eId;
  final String checkpnId;
  final KardType kardType;

  CheckPnSearchDelegate({
    required this.eId,
    required this.checkpnId,
    this.kardType = KardType.invitation,
  });

  @override
  String? get searchFieldLabel => "Search by name…";

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: _T.bg,
      colorScheme: base.colorScheme.copyWith(
        surface: _T.bg,
        onSurface: _T.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _T.card,
        foregroundColor: _T.white,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.inter(color: _T.lbl4, fontSize: 16),
        border: InputBorder.none,
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: _T.lime),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _T.white,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return [];
    return [
      GestureDetector(
        onTap: () => query = '',
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _T.sep,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.close_rounded, color: _T.lbl3, size: 16),
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: _T.lime,
        size: 18,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _ResultsList(
    query: query,
    eId: eId,
    kardType: kardType,
    checkpnId: checkpnId,
  );

  @override
  Widget buildSuggestions(BuildContext context) => _ResultsList(
    query: query,
    eId: eId,
    kardType: kardType,
    checkpnId: checkpnId,
  );
}

// ── Results list ──────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final String query;
  final String eId;
  final KardType kardType;
  final String checkpnId;

  const _ResultsList({
    required this.query,
    required this.eId,
    required this.kardType,
    required this.checkpnId,
  });

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (query.isEmpty) {
      body = const GusSearchEmpty.prompt();
    } else {
      body = FutureBuilder<http.Response>(
        future: http.get(
          Uri.parse(
            "$getAttsUrl/?eventId=$eId&searchKey=${Uri.encodeComponent(query)}&kardType=${kardType.name}",
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CupertinoActivityIndicator(color: _T.lime),
            );
          }
          if (!snapshot.hasData || snapshot.hasError) return _errorView();

          try {
            final body = jsonDecode(snapshot.data!.body);
            if (body['status'] != true) return _errorView();

            final List data = body['data'];
            final attendees =
                data
                    .map((e) {
                      final item = Map<String, dynamic>.from(e['item']);
                      return Attendee.fromMap(item['id'] ?? '', item);
                    })
                    .where((at) {
                      try {
                        return at.cards[kardType.name] != null;
                      } catch (_) {
                        return false;
                      }
                    })
                    .toList();

            if (attendees.isEmpty) {
              return GusSearchEmpty.noResults(query: query);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: attendees.length,
              itemBuilder: (_, index) => _AttendeeRow(
                attendee: attendees[index],
                kardType: kardType,
                eId: eId,
                checkpnId: checkpnId,
              ),
            );
          } catch (_) {
            return _errorView();
          }
        },
      );
    }

    return Stack(
      children: [
        Container(color: _T.bg),
        const Positioned(
          top: -80,
          right: -80,
          child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
        ),
        const Positioned(
          bottom: -40,
          left: -80,
          child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
        ),
        Positioned.fill(child: body),
      ],
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: _T.lbl4, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: _T.f(
              size: 15,
              weight: FontWeight.w600,
              color: _T.lbl1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again',
            style: _T.f(size: 13, color: _T.lbl3),
          ),
        ],
      ),
    );
  }
}

// ── Single attendee row ───────────────────────────────────────────────────────

class _AttendeeRow extends StatelessWidget {
  final Attendee attendee;
  final KardType kardType;
  final String eId;
  final String checkpnId;

  const _AttendeeRow({
    required this.attendee,
    required this.kardType,
    required this.eId,
    required this.checkpnId,
  });

  @override
  Widget build(BuildContext context) {
    final attrCrdMap = attendee.cards[kardType.name];
    final attributeCard =
        attrCrdMap != null ? AttributeCard.fromMap(map: attrCrdMap) : null;
    final cardName =
        (attributeCard?.name?.isNotEmpty ?? false)
            ? attributeCard!.name!
            : 'Not Set';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => AttendeeCheckInView(
                  attId: attendee.id ?? 'nan',
                  eId: eId,
                  showAppBar: true,
                  onPressed: () async {},
                  chckpntId: checkpnId,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                color: _T.lime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: _T.lime,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendee.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.f(
                      size: 14,
                      weight: FontWeight.w600,
                      color: _T.lbl1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cardName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.f(size: 12, color: _T.lbl3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _T.lbl4,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ambient orb — mirrors attendees.dart ─────────────────────────────────────

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({
    required this.size,
    required this.color,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
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
