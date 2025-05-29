import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/providers/balance_provider.dart';
// import 'package:haflaway/services/balance_service.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/whatsApp/select_template.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/whatsApp/winvintations.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:provider/provider.dart';

class WInvHost extends StatefulWidget {
  final Event event;
  const WInvHost({super.key, required this.event});

  @override
  State<WInvHost> createState() => _WInvHostState();
}

class _WInvHostState extends State<WInvHost> {
  int currentStep = 0;
  late EventPlan eventPlan;
  List<Attendee> senderList = [];
  String campaignId = "whatsapp_invitation_campaign";
  PageController pageController = PageController();
  GlobalKey<SelectTemplateState> someKey = GlobalKey<SelectTemplateState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<BalanceProvider>(
      builder: (context, provider, child) {
        eventPlan = provider.eventPlan!;
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(gradient: primaryGrad),
            ),
            title: Text("WhatsApp Invitation"),
          ),
          body: Column(
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
                      campaignId: campaignId,
                    ),
                    SelectTemplate(
                      key: someKey,
                      event: widget.event,
                      eventPlan: eventPlan,
                      senderList: senderList,
                      campaignId: campaignId,
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.grey[300],
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
                                setState(() {
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
                                  setState(() {
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
