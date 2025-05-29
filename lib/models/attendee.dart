const gid = 'id';
const gevent = 'event';
const gdate = 'event_date';
const gtimeframe = 'event_timeframe';
const glocation = 'event_location';
/* fbase */
const atcol = "attendees";
/* labels */
const atlblname = "Name of Attendee";
const atlblphone = "Phone Number of Attendee";
const atlblemail = "Email of Attendee (Optional)";
/* labels */

/* pop-options */
List atActnlist = [atActnDwn, atActnSelAll, atActnCrt, atActnImprt, atActnDel];
const atppsend = "Send Invitation";
const atActnSelAll = "Select All / Unselect All";
const atActnDwn = "Download Attendee Card(s)";
const atActnCrt = "Create Attendee";
const atActnDel = "Delete Attendee";
const atActnImprt = "Import Attendees";

class Attendee {
  String? id;
  String cardId;
  String cardName;
  String cardUrl;
  List checkinStatus;
  DateTime createdAt;
  String email;
  String fullName;
  String? attendanceStatus;
  String phone;
  Map messages;
  Attendee({
    this.id,
    required this.cardId,
    required this.cardName,
    required this.cardUrl,
    required this.checkinStatus,
    required this.createdAt,
    required this.email,
    required this.fullName,
    required this.phone,
    this.attendanceStatus,
    required this.messages,
  });

  Map<String, dynamic> toMap() => {
    "id": id,
    "cardId": cardId,
    "cardName": cardName,
    "cardUrl": cardUrl,
    "checkinStatus": checkinStatus,
    "createdAt": createdAt.toIso8601String(),
    "email": email,
    "fullName": fullName,
    "phone": phone,
    "messages": messages,
    "attendanceStatus": attendanceStatus,
  };

  factory Attendee.fromMap(String id, Map<String, dynamic> map) {
    return Attendee(
      id: id,
      cardId: map['cardId'] ?? "",
      cardName: map['cardName'] ?? "",
      cardUrl: map['cardUrl'] ?? "",
      checkinStatus: map['checkinStatus'] ?? [],
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      email: map['email'] ?? "",
      fullName: map['fullName'] ?? "",
      phone: map['phone'] ?? "",
      messages: map['messages'] ?? {},
      attendanceStatus: map['attendanceStatus'] ?? "Pending",
    );
  }
}
