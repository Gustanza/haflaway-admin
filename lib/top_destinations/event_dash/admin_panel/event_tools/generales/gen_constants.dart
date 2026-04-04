import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';

var shannnels = {"sms": "SMS Channel", "whatsapp": "WhatsApp Channel"};

getSenderChannels({campaignId}) {
  for (var defCampaign in defCampaignsList) {
    if (defCampaign == campaignId) {
      return shannnels;
    }
  }
  return {"sms": "SMS Channel"};
}

var shtates = {
  "unsent": "Unsent",
  "sent": "Sent",
  "delivered": "Delivered",
  "read": "Read",
  "pending": "Pending",
  "undelivered": "Undelivered",
  "failed": "Failed",
};
