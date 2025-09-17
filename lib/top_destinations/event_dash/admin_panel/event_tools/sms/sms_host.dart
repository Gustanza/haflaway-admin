import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/sms/sms_invitations.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/whatsApp/select_template.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';

class SMSsenderHost extends StatefulWidget {
  final Event event;
  final String title;
  final String campaignId;
  final KardType kardType;
  const SMSsenderHost({
    super.key,
    required this.event,
    required this.title,
    required this.kardType,
    required this.campaignId,
  });

  @override
  State<SMSsenderHost> createState() => _SMSsenderHostState();
}

class _SMSsenderHostState extends State<SMSsenderHost> {
  int currentStep = 0;
  List<Attendee> senderList = [];
  PageController pageController = PageController();
  GlobalKey<SelectTemplateState> someKey = GlobalKey<SelectTemplateState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: widget.title,
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: scagrad),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  SMSArtieSender(
                    event: widget.event,

                    karddType: widget.kardType,
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
                    senderList: senderList,
                    kardType: widget.kardType,
                    campaignId: widget.campaignId,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: psm,
                vertical: psm * 0.5,
              ),
              decoration: BoxDecoration(
                color: lqassgradBaseColor,
                border: BoxBorder.fromLTRB(
                  top: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
                ),
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
      ),
    );
  }
}
