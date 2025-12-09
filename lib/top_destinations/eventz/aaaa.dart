import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invitation Manager',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure OLED Black
        primaryColor: const Color(0xFF0A84FF), // iOS Blue
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          secondary: Color(0xFF30D158), // iOS Green
          surface: Color(0xFF1C1C1E), // iOS Dark Surface
        ),
      ),
      home: const InvitationScreen(),
    );
  }
}

// --- MODELS ---
class Attendee {
  final String id;
  final String name;
  final int count;
  final String phone;
  final String seatType;
  final String status; // 'unsent', 'sent'
  bool isSelected;

  Attendee({
    required this.id,
    required this.name,
    required this.count,
    required this.phone,
    required this.seatType,
    this.status = 'unsent',
    this.isSelected = false,
  });
}

// --- MAIN SCREEN ---
class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  // State variables
  int _selectedSegment = 0; // 0: Unsent, 1: Sent, 2: All
  bool _isWhatsAppEnabled = true;

  // Mock Data
  final List<Attendee> _attendees = List.generate(
    10,
    (index) => Attendee(
      id: index.toString(),
      name: index % 2 == 0 ? "Wakwe Family" : "Mr. John Doe",
      count: 2 + index,
      phone: "+255 652 659 649",
      seatType: index % 3 == 0 ? "VIP" : "DOUBLE",
      status: index < 3 ? 'sent' : 'unsent',
    ),
  );

  // Getters for filtered lists
  List<Attendee> get _filteredAttendees {
    if (_selectedSegment == 0) {
      return _attendees.where((a) => a.status == 'unsent').toList();
    } else if (_selectedSegment == 1) {
      return _attendees.where((a) => a.status == 'sent').toList();
    }
    return _attendees;
  }

  int get _selectedCount =>
      _filteredAttendees.where((a) => a.isSelected).length;
  bool get _isAllSelected =>
      _filteredAttendees.isNotEmpty &&
      _filteredAttendees.every((a) => a.isSelected);

  // Logic
  void _toggleSelection(Attendee attendee) {
    setState(() {
      attendee.isSelected = !attendee.isSelected;
    });
  }

  void _toggleSelectAll() {
    bool newValue = !_isAllSelected;
    setState(() {
      for (var a in _filteredAttendees) {
        a.isSelected = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a Stack to place the Floating Bottom Bar over the list
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. iOS Style Large Navigation Bar
              const SliverAppBar(
                expandedHeight: 120,
                backgroundColor: Color(0xFF000000),
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    "Invitations",
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      backgroundColor: Color(0xFF1C1C1E),
                      child: Icon(CupertinoIcons.ellipsis, color: Colors.white),
                    ),
                  ),
                ],
              ),

              // 2. Search & Filter Area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              color: Colors.grey,
                              size: 20,
                            ),
                            hintText: "Search name or phone",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // iOS Segmented Control
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<int>(
                          backgroundColor: const Color(0xFF1C1C1E),
                          thumbColor: const Color(0xFF636366),
                          groupValue: _selectedSegment,
                          children: const {
                            0: Text(
                              'Unsent',
                              style: TextStyle(color: Colors.white),
                            ),
                            1: Text(
                              'Sent',
                              style: TextStyle(color: Colors.white),
                            ),
                            2: Text(
                              'All',
                              style: TextStyle(color: Colors.white),
                            ),
                          },
                          onValueChanged: (value) {
                            setState(() {
                              _selectedSegment = value!;
                              // Reset selection when changing tabs for safety
                              for (var a in _attendees) a.isSelected = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Section Header (Select All)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_filteredAttendees.length} GUESTS",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleSelectAll,
                        child: Text(
                          _isAllSelected ? "Deselect All" : "Select All",
                          style: const TextStyle(
                            color: Color(0xFF0A84FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. The List
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final attendee = _filteredAttendees[index];
                  return _buildAttendeeTile(attendee);
                }, childCount: _filteredAttendees.length),
              ),

              // Spacer for the bottom bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // 5. Modern Bottom Action Bar
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildAttendeeTile(Attendee attendee) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // Surface color
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleSelection(attendee),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Selection Indicator (Radio/Checkbox hybrid style)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        attendee.isSelected
                            ? const Color(0xFF0A84FF)
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          attendee.isSelected
                              ? const Color(0xFF0A84FF)
                              : Colors.grey.shade700,
                      width: 2,
                    ),
                  ),
                  child:
                      attendee.isSelected
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 16),

                // Avatar / Initials
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    attendee.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            attendee.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "+${attendee.count}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendee.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tag / Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            attendee.seatType == "VIP"
                                ? const Color(0xFFFFD60A).withOpacity(0.2)
                                : const Color(0xFF0A84FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        attendee.seatType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              attendee.seatType == "VIP"
                                  ? const Color(0xFFFFD60A)
                                  : const Color(0xFF0A84FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (attendee.status == 'sent')
                      const Row(
                        children: [
                          Text(
                            "Sent",
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF30D158),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 10,
                            color: Color(0xFF30D158),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    // Glassmorphism effect for bottom bar
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        // ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.9),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              // Channel Toggle (WhatsApp/SMS)
              InkWell(
                onTap:
                    () => setState(
                      () => _isWhatsAppEnabled = !_isWhatsAppEnabled,
                    ),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isWhatsAppEnabled
                            ? const Color(0xFF25D366).withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color:
                          _isWhatsAppEnabled
                              ? const Color(0xFF25D366)
                              : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isWhatsAppEnabled
                            ? CupertinoIcons.chat_bubble_2_fill
                            : CupertinoIcons.bubble_left_fill,
                        color:
                            _isWhatsAppEnabled
                                ? const Color(0xFF25D366)
                                : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isWhatsAppEnabled ? "WhatsApp" : "SMS",
                        style: TextStyle(
                          color:
                              _isWhatsAppEnabled
                                  ? const Color(0xFF25D366)
                                  : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Main Action Button
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _selectedCount > 0
                          ? () {
                            // Handle Send Action
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    disabledBackgroundColor: const Color(
                      0xFF0A84FF,
                    ).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedCount > 0
                        ? "Send $_selectedCount Invites"
                        : "Select Attendees",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          _selectedCount > 0
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper to access backdrop filter
// In a real project, import 'dart:ui' as ui; and use ui.ImageFilter.blur
// For this snippet to run without complex imports, I used a workaround naming in the code above,
// but here is the correct import shim if you copy-paste:
