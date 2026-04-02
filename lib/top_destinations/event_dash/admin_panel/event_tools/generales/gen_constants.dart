import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';

var shannnels = {
  // "all": "Channel Zote",
  "sms": "Channel ya SMS",
  "whatsapp": "Channel ya WhatsApp",
};

getSenderChannels({campaignId}) {
  for (var defCampaign in defCampaignsList) {
    if (defCampaign == campaignId) {
      return shannnels;
    }
  }
  return {"sms": "Channel ya SMS"};
}

var shtates = {
  "unsent": "Hazijatumwa (Unsent)",
  "sent": "Zilizotumwa (Sent)",
  "delivered": "Zilizofika (Delivered)",
  "read": "Zilizosomwa (Read)",
  "pending": "Zilizo Pending (Pending)",
  "undelivered": "Hazikupokelewa (Undelivered)",
  "failed": "Zilizofeli (Failed)",
};
