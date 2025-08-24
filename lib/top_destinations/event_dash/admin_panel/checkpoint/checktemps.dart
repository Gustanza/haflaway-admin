import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/resolver.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';
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

Widget buildErrorState({onPressed}) {
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
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
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
        Container(height: kToolbarHeight * 2, color: Colors.white),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: psm),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
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
                  color: Colors.white,
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
    return Center(
      child: Form(
        key: gkey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: psm * 2),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Card(
                color: lqassgradBaseColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: psm,
                    vertical: psm * 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Enter Access Code",
                        style: TextStyle(
                          fontSize: fsm + 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: psm),
                      Pinput(
                        length: 4,
                        controller: controller,
                        defaultPinTheme: PinTheme(
                          height: kToolbarHeight,
                          width: kToolbarHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(bxsm),
                            color: lqassgradBaseColor,
                            border: Border.all(
                              color: lqassbdrColor,
                              width: bdrWidthGen,
                            ),
                          ),
                        ),
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
                      SizedBox(height: psm * 1.4),
                      lqAssButton(
                        label: "Continue",
                        onPressed: () {
                          bool isGreen = gkey.currentState?.validate() ?? false;
                          if (isGreen) {
                            String attId = controller.text;
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
