import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/reusables/stuff.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/sms/sms_host.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/whatsApp/wsp_host.dart';
import 'package:haflaway/utils/colors.dart';
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
      appBar: AppBar(
        title: Text(invrem),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGrad),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(psm),
        children: [
          buildSectionHeader("Editor tools", Icons.edit_document, null),
          const SizedBox(height: psm),
          buildListItemCard(
            title: dsninv,
            subtitle: "Get your invitation cards on the go",
            color: Colors.green,
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
            color: Colors.green,
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
            color: Colors.green,
            icon: Clarity.chat_bubble_outline_badged,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return WInvHost(event: widget.event);
                  },
                ),
              );
            },
          ),
          buildListItemCard(
            title: "Send WhatsApp Reminder",
            subtitle: "Remind people via WhatsApp protocol",
            color: Colors.green,
            icon: Clarity.chat_bubble_outline_badged,
            onTap: () {
              showToast(isGood: true, msg: "Coming Soon");
            },
          ),

          // SMS Tools
          buildSectionHeader("SMS tools", Icons.wechat_sharp, null),
          const SizedBox(height: psm),
          buildListItemCard(
            title: "Send Invitation Message",
            subtitle: "Invite people via SMS protocol",
            color: Colors.green,
            icon: Clarity.chat_bubble_outline_badged,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return SMSsenderHost(
                      event: widget.event,
                      title: "SMS Invitations",
                      campaignId: campaignId,
                    );
                  },
                ),
              );
            },
          ),

          buildListItemCard(
            title: "Send Reminder Message",
            subtitle: "Keep invitees on the heartbeat",
            color: Colors.green,
            icon: Clarity.chat_bubble_outline_badged,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return SMSsenderHost(
                      event: widget.event,
                      title: "SMS Reminder",
                      campaignId: remCampaignId,
                    );
                  },
                ),
              );
            },
          ),

          buildListItemCard(
            title: "Send Gratitude Message",
            subtitle: "Thank invitees after the event.",
            color: Colors.green,
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
    );
  }
}
