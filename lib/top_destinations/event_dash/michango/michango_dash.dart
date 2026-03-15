import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/components/gus_scaffold.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/gus_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class MchangoAttendee {
  final String name;
  final double pledge;
  final double paid;
  final String status; // 'Paid', 'Pending', 'Partial'

  const MchangoAttendee({
    required this.name,
    required this.pledge,
    required this.paid,
    required this.status,
  });

  String get initials =>
      name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class MichangoDashboard extends StatefulWidget {
  final Event edata;
  final KardType kardType;

  const MichangoDashboard({
    super.key,
    required this.edata,
    required this.kardType,
  });

  @override
  State<MichangoDashboard> createState() => _MichangoDashboardState();
}

class _MichangoDashboardState extends State<MichangoDashboard>
    with SingleTickerProviderStateMixin {
  static const _attendees = [
    MchangoAttendee(
      name: "John Doe",
      pledge: 50000,
      paid: 50000,
      status: "Paid",
    ),
    MchangoAttendee(
      name: "Jane Smith",
      pledge: 100000,
      paid: 25000,
      status: "Partial",
    ),
    MchangoAttendee(
      name: "Alice Johnson",
      pledge: 30000,
      paid: 0,
      status: "Pending",
    ),
    MchangoAttendee(
      name: "Bob Brown",
      pledge: 75000,
      paid: 75000,
      status: "Paid",
    ),
    MchangoAttendee(
      name: "Charlie Davis",
      pledge: 40000,
      paid: 10000,
      status: "Partial",
    ),
    MchangoAttendee(
      name: "Diana Prince",
      pledge: 150000,
      paid: 0,
      status: "Pending",
    ),
  ];

  String _filterStatus = "All";
  String _searchQuery = "";
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final double totalPledged = _attendees.fold(0, (s, a) => s + a.pledge);
    final double totalPaid = _attendees.fold(0, (s, a) => s + a.paid);
    final double progress = totalPledged > 0 ? totalPaid / totalPledged : 0;
    _progressAnim = Tween<double>(begin: 0, end: progress).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _progressCtrl.forward(),
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  List<MchangoAttendee> get _filtered =>
      _attendees.where((a) {
        final matchStatus = _filterStatus == "All" || a.status == _filterStatus;
        final matchSearch = a.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        return matchStatus && matchSearch;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final totalPledged = _attendees.fold<double>(0, (s, a) => s + a.pledge);
    final totalPaid = _attendees.fold<double>(0, (s, a) => s + a.paid);
    final pct = totalPledged > 0 ? totalPaid / totalPledged : 0.0;

    return GusScaffold(
      title: widget.kardType == KardType.contribution ? "Michango" : "Mialiko",
      subtitle:
          widget.kardType == KardType.contribution
              ? "COLLECTION SUMMARY"
              : "INVITATION SUMMARY",
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (widget.kardType == KardType.contribution)
            _HeroCard(
              totalPledged: totalPledged,
              totalPaid: totalPaid,
              pct: pct,
              progressAnim: _progressAnim,
            ),
          const SizedBox(height: 16),
          _SearchBar(onChanged: (v) => setState(() => _searchQuery = v)),
          const SizedBox(height: 4),
          _FilterRow(
            selected: _filterStatus,
            onSelect: (s) => setState(() => _filterStatus = s),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              "${_filtered.length} attendee${_filtered.length != 1 ? 's' : ''}",
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.4,
                color: GusTheme.textDim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._filtered.map((a) => _AttendeeCard(attendee: a)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Hero card ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double totalPledged, totalPaid, pct;
  final Animation<double> progressAnim;

  const _HeroCard({
    required this.totalPledged,
    required this.totalPaid,
    required this.pct,
    required this.progressAnim,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalPledged - totalPaid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GusTheme.glassBorder),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GusTheme.gold.withValues(alpha: 0.12),
              GusTheme.gold.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Stack(
          children: [
            // top-edge gold line
            Positioned(
              top: 0,
              left: 40,
              right: 40,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      GusTheme.gold.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // amounts row
                  Row(
                    children: [
                      _AmountBlock(
                        label: "Total Pledged",
                        amount: totalPledged,
                        align: CrossAxisAlignment.start,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: 0.5,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                GusTheme.glassBorder,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      _AmountBlock(
                        label: "Collected",
                        amount: totalPaid,
                        align: CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(pct * 100).toStringAsFixed(1)}% funded",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: GusTheme.gold,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "TZS ${_fmt(remaining)} remaining",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: GusTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: progressAnim,
                    builder:
                        (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progressAnim.value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.06,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              GusTheme.goldLight,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  // legend
                  Row(
                    children: [
                      _LegendDot(color: GusTheme.green, label: "Paid"),
                      const SizedBox(width: 12),
                      _LegendDot(color: GusTheme.orange, label: "Partial"),
                      const SizedBox(width: 12),
                      _LegendDot(color: GusTheme.red, label: "Pending"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final double amount;
  final CrossAxisAlignment align;

  const _AmountBlock({
    required this.label,
    required this.amount,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 1.4,
              color: GusTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "TZS",
            style: TextStyle(
              fontSize: 11,
              color: GusTheme.gold,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _fmt(amount),
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: GusTheme.textPrimary,
              letterSpacing: -0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: GusTheme.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ─── Search bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: GusTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Search attendee…",
          hintStyle: GoogleFonts.inter(
            color: GusTheme.textDim,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: GusTheme.textMuted,
            size: 18,
          ),
          filled: true,
          fillColor: GusTheme.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: GusTheme.glassBorder),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Filter row ──────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children:
            ["All", "Paid", "Partial", "Pending"].map((s) {
              final active = selected == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: active ? GusTheme.gold : GusTheme.surface2,
                      border: Border.all(
                        color:
                            active
                                ? GusTheme.gold
                                : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      s.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: active ? GusTheme.obsidian : GusTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ─── Attendee card ───────────────────────────────────────────────────────────

class _AttendeeCard extends StatefulWidget {
  final MchangoAttendee attendee;
  const _AttendeeCard({required this.attendee});

  @override
  State<_AttendeeCard> createState() => _AttendeeCardState();
}

class _AttendeeCardState extends State<_AttendeeCard> {
  bool _hover = false;

  (Color, Color, Color) get _statusColors {
    switch (widget.attendee.status) {
      case "Paid":
        return (GusTheme.green, GusTheme.greenBg, GusTheme.greenBorder);
      case "Partial":
        return (GusTheme.orange, GusTheme.orangeBg, GusTheme.orangeBorder);
      default:
        return (GusTheme.red, GusTheme.redBg, GusTheme.redBorder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg, statusBorder) = _statusColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _hover = true),
        onTapUp: (_) => setState(() => _hover = false),
        onTapCancel: () => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _hover
                      ? GusTheme.glassBorder
                      : Colors.white.withValues(alpha: 0.05),
            ),
            color: _hover ? GusTheme.surface3 : GusTheme.surface2,
          ),
          child: Row(
            children: [
              // avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: statusBg,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.attendee.initials,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.attendee.name,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: GusTheme.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Pledge · TZS ${_fmt(widget.attendee.pledge)}",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: GusTheme.textMuted,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // right side
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: statusBg,
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      widget.attendee.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "TZS ${_fmt(widget.attendee.paid)} paid",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: GusTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _fmt(double n) {
  if (n >= 1000000) {
    return "${(n / 1000000).toStringAsFixed(1)}M";
  } else if (n >= 1000) {
    final parts = n.toInt().toString();
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
      result.write(parts[i]);
    }
    return result.toString();
  }
  return n.toInt().toString();
}
