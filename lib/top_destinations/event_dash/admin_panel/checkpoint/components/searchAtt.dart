import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/services/checkpoint_db.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/resolver.dart';
import 'package:haflaway/utils/globalwids.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class _T {
  static const bg   = Color(0xFF111114);
  static const card = Color(0xFF1C1C1E);
  static const sep  = Color(0xFF2C2C2E);
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

// ── Results list — reads from local SQLite ────────────────────────────────────

class _ResultsList extends StatefulWidget {
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
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  List<Attendee> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void didUpdateWidget(_ResultsList old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _runSearch();
  }

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    final q = widget.query.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;

    if (q.isEmpty) {
      if (mounted) setState(() { _results = []; _loading = false; });
      return;
    }

    if (mounted) setState(() => _loading = true);

    final results = await CheckpointLocalDB.instance.search(widget.eId, q);

    // Filter by kardType (same logic as before)
    final filtered = results.where((at) {
      try {
        return at.cards[widget.kardType.name] != null;
      } catch (_) {
        return false;
      }
    }).toList();

    if (mounted) setState(() { _results = filtered; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (widget.query.isEmpty) {
      body = const GusSearchEmpty.prompt();
    } else if (_loading) {
      body = const Center(child: CupertinoActivityIndicator(color: _T.lime));
    } else if (_results.isEmpty) {
      body = GusSearchEmpty.noResults(query: widget.query);
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _results.length,
        itemBuilder: (_, i) => _AttendeeRow(
          attendee: _results[i],
          kardType: widget.kardType,
          eId: widget.eId,
          checkpnId: widget.checkpnId,
        ),
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
            builder: (_) => AttendeeCheckInView(
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
              child: const Icon(Icons.person_rounded, color: _T.lime, size: 22),
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
                    style: _T.f(size: 14, weight: FontWeight.w600, color: _T.lbl1),
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
            const Icon(Icons.arrow_forward_ios_rounded, color: _T.lbl4, size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Ambient orb ───────────────────────────────────────────────────────────────

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
