import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/providers/balance_provider.dart';
// import 'package:haflaway/services/balance_service.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/sms/sms_invitations.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/whatsApp/select_template.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:provider/provider.dart';

class SMSsenderHost extends StatefulWidget {
  final Event event;
  final String title;
  final String campaignId;
  const SMSsenderHost({
    super.key,
    required this.event,
    required this.title,
    required this.campaignId,
  });

  @override
  State<SMSsenderHost> createState() => _SMSsenderHostState();
}

class _SMSsenderHostState extends State<SMSsenderHost> {
  int currentStep = 0;
  late EventPlan eventPlan;
  List<Attendee> senderList = [];
  PageController pageController = PageController();
  GlobalKey<SelectTemplateState> someKey = GlobalKey<SelectTemplateState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<BalanceProvider>(
      builder: (context, provider, child) {
        // JpUser? balance = provider.balance;
        eventPlan = provider.eventPlan!;
        // int bfigure = balance != null ? balance.balance.toInt() : 0;
        return Scaffold(
          appBar: AppBar(
            // titleSpacing: 0,
            centerTitle: false,
            flexibleSpace: Container(
              decoration: BoxDecoration(gradient: primaryGrad),
            ),
            title: Text(widget.title),
            // actions: [
            //   Container(
            //     margin: const EdgeInsets.only(right: psm),
            //     padding: EdgeInsets.symmetric(
            //       horizontal: psm,
            //       vertical: psm * 0.35,
            //     ),
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(psm),
            //     ),
            //     child: Text(
            //       "TZS $bfigure",
            //       style: TextStyle(color: Colors.black),
            //     ),
            //   ),
            // ],
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    SMSArtieSender(
                      event: widget.event,
                      eventPlan: eventPlan,
                      onChanged: (p0) {
                        setState(() {
                          senderList = p0;
                        });
                      },
                      campaignId: widget.campaignId,
                    ),
                    SelectTemplate(
                      key: someKey,
                      isWhatsApp: false,
                      event: widget.event,
                      eventPlan: eventPlan,
                      senderList: senderList,
                      campaignId: widget.campaignId,
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
                                  senderList = [];
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
