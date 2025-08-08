import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/sms/sms_host.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/whatsApp/wsp_host.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/top_destinations/event_dash/cards/cards.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/inv_editor.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/strings.dart';

class InRem extends StatefulWidget {
  final Event event;
  const InRem({super.key, required this.event});

  @override
  State<InRem> createState() => _InRemState();
}

class _InRemState extends State<InRem> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: scaback,
      appBar: appBar(
        title: "Handy Tools",
        leading: buildActionButton(
          icon: Icons.arrow_back_ios,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Ccafold(
        child: ListView(
          padding: paddPrime,
          children: [
            buildSectionHeader("Editor tools", Icons.edit_document, null),
            const SizedBox(height: psm),
            buildListItemCard(
              title: dsninv,
              subtitle: "Get your invitation cards on the go",
              color: primaryWhite,
              icon: Clarity.design_line,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return Cards(eId: widget.event.id);
                    },
                  ),
                );
              },
            ),

            buildListItemCard(
              title: "Compose SMS Templates",
              subtitle: "Customize SMS contents",
              color: primaryWhite,
              icon: Clarity.chat_bubble_line,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return InvEditor(eId: widget.event.id);
                    },
                  ),
                );
              },
            ),
            buildSectionHeader("WhatsApp tools", Icons.wechat_sharp, null),
            const SizedBox(height: psm),
            buildListItemCard(
              title: sendwinv,
              subtitle: "Invite people via WhatsApp protocol",
              color: primaryWhite,
              icon: Clarity.chat_bubble_outline_badged,
              onTap: () {
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
            buildListItemCard(
              title: "Ask people for contributions",
              subtitle: "Send instant contribution messages",
              color: primaryWhite,
              icon: Clarity.chat_bubble_outline_badged,
              onTap: () {
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
            // SMS Tools
            buildSectionHeader("SMS tools", Icons.wechat_sharp, null),
            const SizedBox(height: psm),
            buildListItemCard(
              title: "Send Invitation Message",
              subtitle: "Invite people via SMS protocol",
              color: primaryWhite,
              icon: Clarity.chat_bubble_outline_badged,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return SMSsenderHost(
                        event: widget.event,
                        title: "SMS Invitations",
                        campaignId: invCampId,
                      );
                    },
                  ),
                );
              },
            ),

            buildListItemCard(
              title: "Send Reminder Message",
              subtitle: "Keep invitees on the heartbeat",
              color: primaryWhite,
              icon: Clarity.chat_bubble_outline_badged,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return SMSsenderHost(
                        event: widget.event,
                        title: "SMS Reminder",
                        campaignId: invRemCampId,
                      );
                    },
                  ),
                );
              },
            ),
            buildListItemCard(
              title: "Send Gratitude Message",
              subtitle: "Thank invitees after the event.",
              color: primaryWhite,
              icon: Clarity.chat_bubble_outline_badged,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return SMSsenderHost(
                        event: widget.event,
                        title: "SMS Gratitude",
                        campaignId: gratCampaignId,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
