import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/resolver.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:pinput/pinput.dart';
import 'package:shimmer/shimmer.dart';

Widget buildEmptyState({onPressed}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.credit_card_off, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          "No Data Available",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            // color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "There is no data available at this point",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onPressed ?? () {},
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildNoDataView(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

Widget buildErrorView({onPressed}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        const SizedBox(height: 16),
        Text(
          "Something went wrong",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[400],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onPressed ?? () {},
          icon: const Icon(Icons.refresh),
          label: const Text("Try Again"),
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

Widget buildListShimmer() {
  return Shimmer.fromColors(
    baseColor: lqassgradBaseColor,
    highlightColor: lqassbdrColor!,
    child: ListView.builder(
      padding: const EdgeInsets.all(psm),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: index == 0 ? 100 : 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    ),
  );
}

Widget buildShimmerLoader() {
  return Shimmer.fromColors(
    baseColor: lqassgradBaseColor,
    highlightColor: lqassgradBaseColor.withValues(alpha: 0.3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: kToolbarHeight * 2, color: lqassgradBaseColor),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: psm),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: lqassgradBaseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: psm),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 80,
                decoration: BoxDecoration(
                  color: lqassgradBaseColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class PinPutty extends StatelessWidget {
  final String chckpntId;
  final String eId;
  const PinPutty({super.key, required this.chckpntId, required this.eId});

  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> gkey = GlobalKey<FormState>();
    TextEditingController controller = TextEditingController();

    // ── local tokens ──────────────────────────────────────────────────────
    const bg = Color(0xFF111114);
    const lime = Color(0xFFC9A84C);
    const card2 = Color(0xFF28282C);
    const limeDim = Color(0xFF2A2210);
    const white = Color(0xFFFFFFFF);
    const lbl1 = Color(0xFFEEEEF0);
    const lbl3 = Color(0xFF8E8E93);

    TextStyle f({
      double size = 14,
      FontWeight weight = FontWeight.w400,
      Color color = white,
      double letterSpacing = 0,
    }) => GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );

    final defaultCell = PinTheme(
      height: 56,
      width: 56,
      textStyle: f(size: 22, weight: FontWeight.w800, color: lbl1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: card2.withValues(alpha: 0.70),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.8,
        ),
      ),
    );

    final focusedCell = PinTheme(
      height: 56,
      width: 56,
      textStyle: f(size: 22, weight: FontWeight.w800, color: lime),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: limeDim.withValues(alpha: 0.85),
        border: Border.all(color: lime, width: 1.5),
      ),
    );

    final submittedCell = PinTheme(
      height: 56,
      width: 56,
      textStyle: f(size: 22, weight: FontWeight.w800, color: lbl1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: card2.withValues(alpha: 0.90),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: gkey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: BoxDecoration(
                color: bg.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.13),
                  width: 1.0,
                ),
              ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon badge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: lime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: lime.withValues(alpha: 0.28),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(Icons.pin_rounded, color: lime, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Enter Access Code",
                      style: f(
                        size: 20,
                        weight: FontWeight.w800,
                        color: white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Enter your 4-digit check-in code",
                      style: f(size: 13, color: lbl3),
                    ),
                    const SizedBox(height: 28),
                    Pinput(
                      length: 4,
                      controller: controller,
                      keyboardType: TextInputType.text,
                      defaultPinTheme: defaultCell,
                      focusedPinTheme: focusedCell,
                      submittedPinTheme: submittedCell,
                      validator: (value) {
                        if (value == null) {
                          return "Key-in Figures";
                        } else if (value.length < 4) {
                          return "Key-in All Figures";
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          bool isGreen =
                              gkey.currentState?.validate() ?? false;
                          if (isGreen) {
                            String attId = controller.text;
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return AttendeeCheckInView(
                                    attId: attId,
                                    chckpntId: chckpntId,
                                    eId: eId,
                                    showAppBar: true,
                                    onPressed: () async {},
                                  );
                                },
                              ),
                            );
                          } else {
                            debugPrint("Come out here");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lime,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Continue",
                          style: f(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
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
}

