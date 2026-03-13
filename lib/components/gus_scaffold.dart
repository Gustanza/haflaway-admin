import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/utils/gus_theme.dart';

class GusScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? floatingActionButton;

  const GusScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.showBackButton = true,
    this.onBack,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GusTheme.obsidian,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // ── ambient orbs ───────────────────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: const _GusOrb(size: 300, color: GusTheme.gold),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: const _GusOrb(size: 200, color: Color(0xFF4A6CF7)),
          ),

          // ── main content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GusTopBar(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                  showBackButton: showBackButton,
                  onBack: onBack,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GusTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;

  const _GusTopBar({
    required this.title,
    this.subtitle,
    this.actions,
    required this.showBackButton,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: GusTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: GusTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              if (actions != null) ...actions!,
              if (showBackButton) ...[
                if (actions != null) const SizedBox(width: 8),
                GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GusTheme.glassBorder),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: GusTheme.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({required this.size, required this.color, this.opacity = 0.06});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
