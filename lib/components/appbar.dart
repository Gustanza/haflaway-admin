import 'dart:ui';
import 'package:flutter/material.dart';

appBar({title, actions}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.1),
          elevation: 0,
          toolbarHeight: 100,
          leading: const SizedBox.shrink(),
          leadingWidth: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      actions,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
