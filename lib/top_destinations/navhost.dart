import 'package:flutter/material.dart';
import 'package:haflaway/top_destinations/my_events.dart';

class NavHost extends StatefulWidget {
  const NavHost({super.key});

  @override
  State<NavHost> createState() => _NavHostState();
}

class _NavHostState extends State<NavHost> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: HaflaWayHome());
  }
}
