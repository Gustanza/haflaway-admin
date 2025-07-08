import 'dart:ui';
import 'package:flutter/material.dart';

class PlayGround extends StatefulWidget {
  const PlayGround({super.key});

  @override
  State<PlayGround> createState() => _PlayGroundState();
}

class _PlayGroundState extends State<PlayGround> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background content (e.g., an image)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://picsum.photos/800/600',
                ), // Random image
                fit: BoxFit.cover,
              ),
            ),
          ),
          // BackdropFilter to blur part of the background
          Container(
            alignment: Alignment.center,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20.0,
                sigmaY: 20.0,
              ), // Blur effect
              child: Container(
                color: Colors.white.withOpacity(0.3), // Semi-transparent
                width: 200,
                height: 100,
                child: Center(
                  child: Text(
                    'Frosted Glass Effect',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
