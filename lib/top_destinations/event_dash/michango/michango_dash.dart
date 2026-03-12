import 'package:flutter/material.dart';

class MchangoAttendee {
  final String name;
  final double pledge;
  final double paid;
  final String status; // 'Paid', 'Pending', 'Partial'

  MchangoAttendee({
    required this.name,
    required this.pledge,
    required this.paid,
    required this.status,
  });
}

class MichangoDashboard extends StatefulWidget {
  final String eventId;
  const MichangoDashboard({super.key, required this.eventId});

  @override
  State<MichangoDashboard> createState() => _MichangoDashboardState();
}

class _MichangoDashboardState extends State<MichangoDashboard> {
  final List<MchangoAttendee> _mockAttendees = [
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

  @override
  Widget build(BuildContext context) {
    double totalPledged = _mockAttendees.fold(
      0,
      (sum, item) => sum + item.pledge,
    );
    double totalPaid = _mockAttendees.fold(0, (sum, item) => sum + item.paid);
    double progress = totalPledged > 0 ? totalPaid / totalPledged : 0;

    List<MchangoAttendee> filteredAttendees =
        _mockAttendees.where((a) {
          bool matchesStatus =
              _filterStatus == "All" || a.status == _filterStatus;
          bool matchesSearch = a.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          return matchesStatus && matchesSearch;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Michango Summary"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem("Total Pledges", totalPledged),
                    _buildSummaryItem("Total Collected", totalPaid),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.8 ? Colors.greenAccent : Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${(progress * 100).toStringAsFixed(1)}% Completed",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search attendee...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children:
                  ["All", "Paid", "Partial", "Pending"].map((status) {
                    bool isSelected = _filterStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(status),
                        onSelected:
                            (val) => setState(() => _filterStatus = status),
                        backgroundColor: Colors.white10,
                        selectedColor: Colors.blueAccent.withOpacity(0.3),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Attendee List
          Expanded(
            child: ListView.builder(
              itemCount: filteredAttendees.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final attendee = filteredAttendees[index];
                return _buildAttendeeTile(attendee);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          "TZS ${amount.toStringAsFixed(0)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAttendeeTile(MchangoAttendee attendee) {
    Color statusColor =
        attendee.status == "Paid"
            ? Colors.greenAccent
            : attendee.status == "Partial"
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          attendee.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Pledge: TZS ${attendee.pledge.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
            Text(
              "Paid: TZS ${attendee.paid.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(
            attendee.status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
