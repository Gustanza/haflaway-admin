import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/event_tile.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/create_event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane.dart';
import 'package:haflaway/utils/globalfns.dart';

class HaflaList extends StatefulWidget {
  const HaflaList({super.key});

  @override
  State<HaflaList> createState() => _HaflaListState();
}

class _HaflaListState extends State<HaflaList> with TickerProviderStateMixin {
  String _currentFilter = "My Haflas";
  PageController pcont = PageController();
  final List<String> _filters = ["My Haflas", "Guest Haflas"];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: appBar(
        title: "Haflaway",
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildActionButton(icon: Icons.search, onTap: () {}),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.add,
                  onTap: () {
                    navNormal(context: context, widget: const CreateEvent());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildFilterSelector(),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView(
                    controller: pcont,
                    children: const [PersonalEvents(), GuestEvents()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
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

  Widget _buildFilterSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children:
                  _filters.map((filter) {
                    bool isSelected = _currentFilter == filter;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentFilter = filter;
                          });
                          if (_currentFilter == "My Haflas") {
                            pcont.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            pcont.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.black
                                        : Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class PersonalEvents extends StatefulWidget {
  const PersonalEvents({super.key});

  @override
  State<PersonalEvents> createState() => _PersonalEventsState();
}

class _PersonalEventsState extends State<PersonalEvents> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          firestore
              .collection(ecol)
              .where(eadminsIds, arrayContains: uid)
              .where('status', isEqualTo: 'Published')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Event> data =
              (snapshot.data as dynamic).docs.map<Event>((doc) {
                return Event.fromMap(doc.id, doc.data());
              }).toList();

          if (data.isEmpty) {
            return _buildEmptyState("No Events Created Yet");
          } else {
            return ListView.builder(
              itemCount: data.length,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                var evlvl = data[index].categoryLevel;
                return GestureDetector(
                  onTap: () {
                    if (evlvl == '0') {
                      navNormal(
                        context: context,
                        widget: AdminPanel(isAdmin: true, edata: data[index]),
                      );
                    }
                  },
                  child: EventTile(eventData: data[index]),
                );
              },
            );
          }
        } else if (snapshot.hasError) {
          return _buildEmptyState("Something went wrong");
        } else {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class GuestEvents extends StatefulWidget {
  const GuestEvents({super.key});

  @override
  State<GuestEvents> createState() => _GuestEventsState();
}

class _GuestEventsState extends State<GuestEvents> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          firestore
              .collection(ecol)
              .where(eusersIds, arrayContains: uid)
              .where('status', isEqualTo: 'Published')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Event> data =
              (snapshot.data as dynamic).docs.map<Event>((doc) {
                return Event.fromMap(doc.id, doc.data());
              }).toList();

          if (data.isEmpty) {
            return _buildEmptyState("No Invitations Yet");
          } else {
            return ListView.builder(
              itemCount: data.length,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                var evlvl = data[index].categoryLevel;
                return GestureDetector(
                  onTap: () {
                    if (evlvl == '0') {
                      navNormal(
                        context: context,
                        widget: AdminPanel(isAdmin: false, edata: data[index]),
                      );
                    }
                  },
                  child: EventTile(eventData: data[index]),
                );
              },
            );
          }
        } else if (snapshot.hasError) {
          return _buildEmptyState("Something went wrong");
        } else {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
