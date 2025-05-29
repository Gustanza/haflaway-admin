import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/top_destinations/account.dart';
import 'package:haflaway/top_destinations/my_events.dart';

class NavHost extends StatefulWidget {
  const NavHost({super.key});

  @override
  State<NavHost> createState() => _NavHostState();
}

class _NavHostState extends State<NavHost> {
  int currentIndex = 0;
  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        children: const [MyEvents(), Account()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (value) {
          setState(() {
            currentIndex = value;
            pageController.jumpToPage(value);
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Clarity.event_solid),
            label: 'My Haflaz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Clarity.user_solid),
            label: 'My Account',
          ),
        ],
      ),
    );
  }
}
