import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/sms/custom_camps/ccampsmain.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/whatsApp/wsp_host.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/top_destinations/event_dash/cards/cards.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/inv_editor.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/strings.dart';

class EventTools extends StatefulWidget {
  final Event event;
  const EventTools({super.key, required this.event});

  @override
  State<EventTools> createState() => _EventToolsState();
}

class _EventToolsState extends State<EventTools> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Handy Tools",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Ccafold(
        child: ListView(
          padding: EdgeInsets.only(
            left: psm,
            right: psm,
            top: psm * 0.7,
            bottom: psm,
          ),
          children: [
            const SizedBox(height: psm * 0.25),
            buildActionItem(
              title: "Designers",
              children: [
                ActionItem(
                  figure: "1",
                  icon: Icons.card_giftcard,
                  subtitle: "Card Templates",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return Cards(eId: widget.event.id ?? "");
                        },
                      ),
                    );
                  },
                ),
                ActionItem(
                  figure: "2",
                  icon: Icons.sms,
                  subtitle: "SMS Templates",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return InvEditor(eId: widget.event.id ?? "");
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: spaceTiles),
            buildActionItem(
              title: "Save the Dates",
              children: [
                ActionItem(
                  figure: "0",
                  icon: Icons.notifications_active,
                  subtitle: "Printed Order",
                  onPressed: () {},
                ),
                ActionItem(
                  figure: "16",
                  icon: Icons.notifications_on,
                  subtitle: "Digital Sent",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return WInvHost(
                            title: "Issue Cards",
                            event: widget.event,
                            campaignId: svdtCampId,
                            kardType: KardType.invitation,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: spaceTiles),
            buildActionItem(
              title: "Invitations",
              children: [
                ActionItem(
                  figure: "0",
                  icon: Icons.people,
                  subtitle: "Printed Order",
                  onPressed: () {},
                ),
                ActionItem(
                  figure: "10",
                  icon: Icons.mark_email_read,
                  subtitle: "Digital Sent",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return WInvHost(
                            kardType: KardType.invitation,
                            event: widget.event,
                            campaignId: invCampId,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: spaceTiles),
            buildActionItem(
              title: "Contributions",
              children: [
                ActionItem(
                  figure: "0",
                  icon: Icons.people,
                  subtitle: "Physical Outreach",
                  onPressed: () {},
                ),
                ActionItem(
                  figure: "10",
                  icon: Icons.email,
                  subtitle: "Digital Outreach",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return WInvHost(
                            title: "Issue Cards",
                            event: widget.event,
                            campaignId: contrCampId,
                            kardType: KardType.contribution,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: spaceTiles),
            buildActionItem(
              title: "SMS Campaigns",
              children: [
                ActionItem(
                  figure: "0",
                  icon: Icons.sms,
                  subtitle: "Invitation Campaigns",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return AdminCampaigns(
                            event: widget.event,
                            title: "Invitation Campaigns",
                            kardType: KardType.invitation,
                          );
                        },
                      ),
                    );
                  },
                ),
                ActionItem(
                  figure: "10",
                  icon: Icons.sms,
                  subtitle: "Contribution Campaigns",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return AdminCampaigns(
                            event: widget.event,
                            title: "Contribution Campaigns",
                            kardType: KardType.contribution,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
