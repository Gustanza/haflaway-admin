// ─── THEME CONSTANTS ───────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

const Color kBg = Color(0xFFF7F6F0);
const Color kSurface = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE5E3DC);
const Color kBorderLight = Color(0xFFF0EDE8);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF888780);
const Color kTextMuted = Color(0xFFB4B2A9);
const Color kPurple = Color(0xFF6B4FBB);
const Color kPurpleLight = Color(0xFFEDE9F9);
const Color kGreen = Color(0xFF065F46);
const Color kGreenLight = Color(0xFFD1FAE5);
const Color kGreenDot = Color(0xFF10B981);
const Color kBlue = Color(0xFF1D4ED8);
const Color kBlueLight = Color(0xFFDBEAFE);
const Color kAmber = Color(0xFF92400E);
const Color kAmberLight = Color(0xFFFEF3C7);
const Color kAmberText = Color(0xFFB45309);
const Color kPendingText = Color(0xFF92400E);
const Color kPendingBg = Color(0xFFFEF3C7);
const Color kPendingBorder = Color(0xFFFEF08A);

// ─── MOCK DATA ─────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> kSalesData = [
  {'day': 'Mon', 'value': 10},
  {'day': 'Tue', 'value': 32},
  {'day': 'Wed', 'value': 25},
  {'day': 'Thu', 'value': 80},
  {'day': 'Fri', 'value': 120},
];

const List<Map<String, dynamic>> kOrders = [
  {
    'initials': 'JP',
    'name': 'John Peter',
    'ticket': '2× VIP',
    'status': 'Paid',
    'avatarColor': kPurple,
    'avatarBg': kPurpleLight,
  },
  {
    'initials': 'AS',
    'name': 'Amina Said',
    'ticket': '1× Regular',
    'status': 'Paid',
    'avatarColor': kGreen,
    'avatarBg': kGreenLight,
  },
  {
    'initials': 'KM',
    'name': 'Kelvin M.',
    'ticket': '3× Early Bird',
    'status': 'Pending',
    'avatarColor': kAmber,
    'avatarBg': kAmberLight,
  },
];

// ─── MAIN SCREEN ───────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _NavBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EventHeader(),
                    _QuickActions(),
                    const SizedBox(height: 14),
                    _SectionLabel('Overview'),
                    _MetricsGrid(),
                    const SizedBox(height: 14),
                    _SalesProgress(),
                    const SizedBox(height: 10),
                    _SalesTrendChart(),
                    const SizedBox(height: 10),
                    _TicketTypePerformance(),
                    const SizedBox(height: 10),
                    _RecentOrders(),
                    const SizedBox(height: 10),
                    _CheckInStatus(),
                    const SizedBox(height: 10),
                    _OrganizerTools(),
                  ],
                ),
              ),
            ),
            _BottomNav(),
          ],
        ),
      ),
    );
  }
}

// ─── NAV BAR ──────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: 'Hafla'),
                TextSpan(text: 'way', style: TextStyle(color: kPurple)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDE8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 14,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: kPurple,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'YM',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EVENT HEADER ─────────────────────────────────────────────────────────────

class _EventHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LiveBadge(),
          const SizedBox(height: 6),
          const Text(
            'Amapiano Night Festival',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: const [
              _MetaChip(
                icon: Icons.calendar_today_outlined,
                label: 'Aug 24, 2026',
              ),
              SizedBox(width: 12),
              _MetaChip(
                icon: Icons.location_on_outlined,
                label: 'Serena Hotel, DSM',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kGreenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: kGreenDot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Live',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: kTextMuted),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
      ],
    );
  }
}

// ─── QUICK ACTIONS ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          _ActionButton(label: 'Edit Event', isPrimary: false),
          const SizedBox(width: 6),
          _ActionButton(label: 'Share', isPrimary: false),
          const SizedBox(width: 6),
          _ActionButton(label: 'Scan Tickets', isPrimary: true),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  const _ActionButton({required this.label, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? kPurple : kSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary ? kPurple : kBorder,
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : kTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: kTextMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── METRICS GRID ─────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.55,
        children: const [
          _MetricCard(
            icon: '🎟',
            iconBg: kPurpleLight,
            value: '320',
            valueSuffix: ' / 500',
            label: 'Tickets Sold',
            trend: '▲ +12 today',
            trendColor: Color(0xFF059669),
          ),
          _MetricCard(
            icon: '💰',
            iconBg: kGreenLight,
            value: '6.4M',
            valueSuffix: ' TZS',
            label: 'Total Revenue',
            trend: '▲ +8.2%',
            trendColor: Color(0xFF059669),
          ),
          _MetricCard(
            icon: '🏟',
            iconBg: kBlueLight,
            value: '500',
            valueSuffix: '',
            label: 'Event Capacity',
            trend: '',
            trendColor: Colors.transparent,
          ),
          _MetricCard(
            icon: '⏳',
            iconBg: kAmberLight,
            value: '180',
            valueSuffix: '',
            label: 'Remaining',
            trend: '',
            trendColor: Colors.transparent,
            valueColor: kAmberText,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String value;
  final String valueSuffix;
  final String label;
  final String trend;
  final Color trendColor;
  final Color valueColor;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.value,
    required this.valueSuffix,
    required this.label,
    required this.trend,
    required this.trendColor,
    this.valueColor = kTextPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: valueColor,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: value),
                if (valueSuffix.isNotEmpty)
                  TextSpan(
                    text: valueSuffix,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: kTextMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextMuted)),
          if (trend.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              trend,
              style: TextStyle(
                fontSize: 9,
                color: trendColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SALES PROGRESS ───────────────────────────────────────────────────────────

class _SalesProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Sales Progress',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  '64% Sold',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 0.64,
                minHeight: 8,
                backgroundColor: const Color(0xFFF0EDE8),
                valueColor: const AlwaysStoppedAnimation<Color>(kPurple),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '320 sold',
                  style: TextStyle(fontSize: 10, color: kTextMuted),
                ),
                Text(
                  '180 remaining',
                  style: TextStyle(fontSize: 10, color: kTextMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SALES TREND CHART ────────────────────────────────────────────────────────

class _SalesTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Sales Trend',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(height: 90, child: _LineChart(data: kSalesData)),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _LineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        data
            .map((e) => e['value'] as int)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(data: data, maxVal: maxVal),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              data
                  .map(
                    (e) => Text(
                      e['day'] as String,
                      style: const TextStyle(fontSize: 9, color: kTextMuted),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxVal;
  const _LineChartPainter({required this.data, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.length;
    final pts = List.generate(n, (i) {
      final x = i * size.width / (n - 1);
      final y = size.height - (data[i]['value'] as int) / maxVal * size.height;
      return Offset(x, y);
    });

    // gradient fill
    final fillPath = Path()..moveTo(pts.first.dx, size.height);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      fillPath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    fillPath.lineTo(pts.last.dx, size.height);
    fillPath.close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPurple.withOpacity(0.15), kPurple.withOpacity(0.01)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    final linePaint =
        Paint()
          ..color = kPurple
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // dots
    final dotPaint = Paint()..color = kPurple;
    for (final p in pts) {
      canvas.drawCircle(p, 3, dotPaint);
      canvas.drawCircle(
        p,
        3,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── TICKET TYPE PERFORMANCE ──────────────────────────────────────────────────

class _TicketTypePerformance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Type Performance',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _TicketTypeRow(
              label: 'Early Bird',
              sold: 120,
              total: 200,
              color: kPurple,
            ),
            const SizedBox(height: 9),
            _TicketTypeRow(
              label: 'Regular',
              sold: 180,
              total: 200,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 9),
            _TicketTypeRow(
              label: 'VIP',
              sold: 20,
              total: 50,
              color: const Color(0xFFD97706),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketTypeRow extends StatelessWidget {
  final String label;
  final int sold;
  final int total;
  final Color color;
  const _TicketTypeRow({
    required this.label,
    required this.sold,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sold / total,
              minHeight: 5,
              backgroundColor: kBorderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$sold',
            style: const TextStyle(fontSize: 10, color: kTextMuted),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─── RECENT ORDERS ────────────────────────────────────────────────────────────

class _RecentOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ),
            ...kOrders.asMap().entries.map((entry) {
              final i = entry.key;
              final order = entry.value;
              return _OrderRow(order: order, isLast: i == kOrders.length - 1);
            }),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isLast;
  const _OrderRow({required this.order, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isPaid = order['status'] == 'Paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : const Border(
                  top: BorderSide(color: kBorderLight, width: 0.5),
                ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: order['avatarBg'] as Color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                order['initials'] as String,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: order['avatarColor'] as Color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['name'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  order['ticket'] as String,
                  style: const TextStyle(fontSize: 10, color: kTextMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isPaid ? kGreenLight : kPendingBg,
              border: Border.all(
                color: isPaid ? const Color(0xFFBBF7D0) : kPendingBorder,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order['status'] as String,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isPaid ? kGreen : kPendingText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CHECK-IN STATUS ──────────────────────────────────────────────────────────

class _CheckInStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: CustomPaint(painter: _DonutPainter()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-in Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CheckInRow(color: kPurple, label: 'Checked In', count: '85'),
                  const SizedBox(height: 5),
                  _CheckInRow(
                    color: kBorder,
                    label: 'Not Checked In',
                    count: '235',
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

class _CheckInRow extends StatelessWidget {
  final Color color;
  final String label;
  final String count;
  const _CheckInRow({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kTextSecondary),
        ),
        const Spacer(),
        Text(
          count,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(34, 34);
    const radius = 26.0;
    const strokeW = 9.0;

    // background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = kBorderLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // filled arc — 85/320 ≈ 26.6% of circumference
    const sweepAngle = 2 * 3.14159 * 0.266;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      Paint()
        ..color = kPurple
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // center text
    final span = TextSpan(
      text: '85',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── ORGANIZER TOOLS ──────────────────────────────────────────────────────────

class _OrganizerTools extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organizer Tools',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 2.6,
              children: const [
                _ToolButton(
                  icon: Icons.people_outline_rounded,
                  label: 'View Attendees',
                  iconBg: kPurpleLight,
                  iconColor: kPurple,
                ),
                _ToolButton(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Create Ticket',
                  iconBg: kBlueLight,
                  iconColor: kBlue,
                ),
                _ToolButton(
                  icon: Icons.download_outlined,
                  label: 'Guest List',
                  iconBg: kGreenLight,
                  iconColor: kGreen,
                ),
                _ToolButton(
                  icon: Icons.campaign_outlined,
                  label: 'Promote Event',
                  iconBg: kAmberLight,
                  iconColor: kAmber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 13, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: const [
          _BottomNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Dashboard',
            isActive: true,
          ),
          _BottomNavItem(
            icon: Icons.confirmation_number_outlined,
            label: 'Tickets',
            isActive: false,
          ),
          _BottomNavItem(
            icon: Icons.people_outline_rounded,
            label: 'Guests',
            isActive: false,
          ),
          _BottomNavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isActive: false,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? kPurple : kTextMuted;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
