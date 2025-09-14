import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  int selectedIndex = 0;
  final PageController _pageController = PageController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        title: "Select Plan",
      ),
      body: Container(
        decoration: BoxDecoration(gradient: scagrad),
        child: FutureBuilder(
          future:
              firestore
                  .collection(eplancol)
                  .orderBy('rank', descending: false)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var docs = (snapshot.data as dynamic).docs;
              if (docs.isEmpty) {
                return const BuildNoDt(string: "no data");
              } else {
                return buildBody(rawData: docs);
              }
            } else if (snapshot.hasError) {
              return buildErr();
            } else {
              return buildLoader();
            }
          },
        ),
      ),
    );
  }

  buildBody({rawData}) {
    List<EventPlan> eventPlans =
        rawData.map<EventPlan>((e) {
          return EventPlan.fromMap(e.id, e.data());
        }).toList();
    Map<int, Widget> children = {};
    for (var i = 0; i < eventPlans.length; i++) {
      children[i] = Padding(
        padding: const EdgeInsets.all(psm),
        child: Text(eventPlans[i].name),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(
        top: psm * 0.5,
        right: psm,
        left: psm,
        bottom: psm,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.maxFinite,
            child: CupertinoSlidingSegmentedControl(
              children: children,
              groupValue: selectedIndex,
              onValueChanged: (index) {
                setState(() {
                  selectedIndex = index ?? 0;
                  _pageController.animateToPage(
                    selectedIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: psm * 0.5),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: children.length,
              onPageChanged: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return buildPlanCard(eventPlans[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPlanCard(EventPlan plan) {
    double dprice = plan.winvmsgprice + plan.wremmsgprice + plan.wgratmsgprice;
    int intprice = dprice.toInt();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(bmd),
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(bmd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Icon(Icons.wifi, size: 40)),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children:
                      plan.services.map<Widget>((feature) {
                        return Row(
                          children: [
                            const Icon(Clarity.shield_check_line, size: 20),
                            const SizedBox(width: psm),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Each Attendee: $intprice/=TZS',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.maxFinite,
                  child: lqAssButton(
                    label: "Select",
                    onPressed: () {
                      Navigator.of(context).pop(plan);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
