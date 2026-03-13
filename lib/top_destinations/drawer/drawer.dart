import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/app_users/app_users.dart';
import 'package:haflaway/top_destinations/settings/account.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/gus_theme.dart';

Widget drawer({required BuildContext context}) {
  return Drawer(
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: Container(
      decoration: BoxDecoration(
        color: GusTheme.obsidian.withOpacity(0.8),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    children: [
                      // Header Section
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: GusTheme.gold.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage(
                              'assets/utils/imagen/icon.png',
                            ),
                          ),
                        ),
                        title: Text(
                          "Haflaway Cpanel",
                          style: GoogleFonts.cormorantGaramond(
                            color: GusTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        subtitle: getEvsCount(),
                        trailing: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.green, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      const SizedBox(height: 16),

                      // Navigation Items
                      _buildDrawerItem(
                        icon: Icons.settings_outlined,
                        title: "Settings & Configs",
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const Mipangilio(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDrawerItem(
                        icon: Icons.people_outline_rounded,
                        title: "Users Management",
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AppUsersScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Footer version info could go here
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "VERSION 1.0.0",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: GusTheme.textMuted.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildDrawerItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: GusTheme.gold.withOpacity(0.8), size: 22),
    title: Text(
      title,
      style: GoogleFonts.inter(
        // color: GusTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: Icon(
      Icons.arrow_forward_ios_rounded,
      color: GusTheme.textMuted.withOpacity(0.3),
      size: 14,
    ),
  );
}

getEvsCount() {
  return FutureBuilder(
    future: FirebaseFirestore.instance.collection(ecol).count().get(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        var count = snapshot.data?.count;
        return Text(
          "$count Events total",
          style: GoogleFonts.inter(color: GusTheme.textMuted, fontSize: 12),
        );
      } else if (snapshot.hasError) {
        return Text(
          "Data unavailable",
          style: GoogleFonts.inter(color: GusTheme.textMuted, fontSize: 12),
        );
      } else {
        return Text(
          "Loading...",
          style: GoogleFonts.inter(color: GusTheme.textMuted, fontSize: 12),
        );
      }
    },
  );
}
