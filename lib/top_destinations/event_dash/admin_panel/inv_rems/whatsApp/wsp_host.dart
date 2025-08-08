import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/providers/balance_provider.dart';
// import 'package:haflaway/services/balance_service.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/whatsApp/select_template.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/whatsApp/winvintations.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:provider/provider.dart';

class WInvHost extends StatefulWidget {
  final Event event;
  final KardType kardType;
  final String title;
  final String campaignId;
  const WInvHost({
    super.key,
    required this.event,
    required this.kardType,
    this.campaignId = invCampId,
    this.title = "Issue Invitations",
  });

  @override
  State<WInvHost> createState() => _WInvHostState();
}

class _WInvHostState extends State<WInvHost> {
  int currentStep = 0;
  bool isWhatsApp = true;
  late EventPlan eventPlan;
  List<Attendee> senderList = [];
  PageController pageController = PageController();
  GlobalKey<SelectTemplateState> someKey = GlobalKey<SelectTemplateState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<BalanceProvider>(
      builder: (context, provider, child) {
        eventPlan = provider.eventPlan!;
        return Scaffold(
          backgroundColor: scaback,
          appBar: appBar(
            title: "${widget.title}",
            leading: buildActionButton(
              icon: Icons.arrow_back_ios,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Ccafold(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      WInvSender(
                        event: widget.event,
                        eventPlan: eventPlan,
                        onChanged: (p0) {
                          setState(() {
                            senderList = p0;
                          });
                        },

                        kardType: widget.kardType,
                        campaignId: widget.campaignId,
                      ),
                      SelectTemplate(
                        key: someKey,
                        event: widget.event,
                        eventPlan: eventPlan,
                        senderList: senderList,
                        kardType: widget.kardType,
                        isWhatsApp: isWhatsApp,
                        campaignId: widget.campaignId,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacgen),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(bsm),
                      topRight: Radius.circular(bsm),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: psm,
                    vertical: psm * 0.5,
                  ),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed:
                            currentStep > 0
                                ? () {
                                  safeState(() {
                                    currentStep -= 1;
                                    pageController.jumpToPage(currentStep);
                                  });
                                }
                                : null,
                        child: Text("Back"),
                      ),
                      SizedBox(width: psm),
                      ElevatedButton(
                        onPressed:
                            senderList.isNotEmpty
                                ? () async {
                                  if (currentStep < 1) {
                                    safeState(() {
                                      currentStep += 1;
                                      pageController.jumpToPage(currentStep);
                                    });
                                  } else {
                                    await someKey.currentState?.confirmSend();
                                  }
                                }
                                : null,
                        child: Text(currentStep < 1 ? "Next" : "Send"),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.only(left: psm * 2),
                          value: isWhatsApp,
                          title: Text(
                            "WhatsApp",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onChanged:
                              currentStep < 1
                                  ? (val) {
                                    safeState(() {
                                      isWhatsApp = val;
                                    });
                                  }
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  safeState(Function runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }
}
