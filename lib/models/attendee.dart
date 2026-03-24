import 'package:haflaway/models/card.dart';

const gid = 'id';
const gevent = 'event';
const gdate = 'event_date';
const gtimeframe = 'event_timeframe';
const glocation = 'event_location';
/* fbase */
const atcol = "attendees";
const atPaySub = 'payments';
/* labels */
const atlblname = "Name of Attendee";
const atlblphone = "Phone Number of Attendee";
const atlblemail = "Email of Attendee (Optional)";
/* labels */

/* pop-options */
List atActnlist({required KardType kardType}) {
  return [
    atActnSelAll,
    atActnCrt,
    atActnImprtFile,
    if (kardType == KardType.invitation) atActnImprtCont,
    atActnDel,
  ];
}

const atppsend = "Send Invitation";
const atActnSelAll = "Select All / Unselect All";
const atActnDwn = "Download Cards";
const atActnCrt = "Create Attendee";
const atActnDel = "Delete Attendee";
const atActnImprtFile = "Import from file";
const atActnImprtCont = "Import from contributors";

class Attendee {
  String? id;
  Map cards;
  List checkinStatus;
  DateTime createdAt;
  String email;
  String fullName;
  String? attendanceStatus;
  String phone;
  Map messages;
  double? pledgedAmount;
  double? paidAmount;
  String idComment;
  List? messageIndexes;
  Attendee({
    this.id,
    required this.cards,
    // required this.cardId,
    this.paidAmount,
    this.pledgedAmount,
    required this.checkinStatus,
    required this.createdAt,
    required this.email,
    required this.fullName,
    required this.phone,
    this.attendanceStatus,
    this.messageIndexes,
    this.idComment = 'No Comment',
    required this.messages,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) "id": id,
    "cards": cards,
    "phone": phone,
    "email": email,
    "fullName": fullName,
    "messages": messages,
    "idComment": idComment,
    if (messageIndexes != null) "messageIndexes": messageIndexes,
    "attendanceStatus": attendanceStatus,
    "checkinStatus": checkinStatus,
    "createdAt": createdAt.toIso8601String(),
    if (paidAmount != null) "paidAmount": paidAmount,
    if (pledgedAmount != null) "pledgedAmount": pledgedAmount,
  };

  factory Attendee.fromMap(String id, Map<String, dynamic> map) {
    var tmpIndexes = map['messageIndexes'] ?? [];
    List mIndexes = [];
    try {
      mIndexes =
          tmpIndexes.where((item) {
            return !item.contains("unsent");
          }).toList();
    } catch (e) {
      mIndexes = tmpIndexes;
    }
    return Attendee(
      id: id,
      cards: map['cards'] ?? {},
      checkinStatus: map['checkinStatus'] ?? [],
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      email: map['email'] ?? "",
      fullName: map['fullName'] ?? "",
      phone: map['phone'] ?? "",
      messages: map['messages'] ?? {},
      messageIndexes: mIndexes,
      pledgedAmount:
          map['pledgedAmount'] != null
              ? (map['pledgedAmount'] as num).toDouble()
              : 0.00,
      paidAmount:
          map['paidAmount'] != null
              ? (map['paidAmount'] as num).toDouble()
              : 0.00,
      idComment: map['idComment'] ?? "No Comment",
      attendanceStatus: map['attendanceStatus'] ?? "Not Confirmed",
    );
  }
}

class AttributeCard {
  String? name;
  String? url;
  String? issuedAt;
  String? templateCardId;
  AttributeCard({
    required this.name,
    required this.url,
    required this.issuedAt,
    required this.templateCardId,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'url': url,
    'issuedAt': issuedAt,
    'templateCardId': templateCardId,
  };

  factory AttributeCard.fromMap({map}) {
    return AttributeCard(
      name: map['name'] ?? "",
      url: map['url'] ?? "",
      templateCardId: map['templateCardId'] ?? "",
      issuedAt: map['issuedAt'] ?? "",
    );
  }
}
