import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';

var shannnels = {
  // "all": "Channel Zote",
  "whatsapp": "Channel ya WhatsApp",
  "sms": "Channel ya SMS",
};

getSenderChannels({campaignId}) {
  for (var defCampaign in defCampaignsList) {
    if (defCampaign == campaignId) {
      return {"whatsapp": "Channel ya WhatsApp", "sms": "Channel ya SMS"};
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
