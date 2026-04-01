List supportedttypes = ['Cards', 'Tickets'];
const cardcol = 'cards';
/* configs */
const coriginalW = 'cardWidth';
const coriginalH = 'cardHeight';
const cscaleFactor = 'scaleFactor';
const crenderedW = 'renderedCardWidth';
const crenderedH = 'renderedCardHeight';
const crdelements = 'elements';
const crdattname = 'attendeeName';
const crdtype = 'cardType';
const crdpasscode = 'passcode';
const crdQrCode = 'qrcode';
//
const lmntvalue = 'value';
const lmntconfig = 'config';
const lmntsize = 'size';
const lmntcolor = 'color';
const lmntlvx = 'relativeX';
const lmntlvy = 'relativeY';
const lmntcenter = 'isCentered';
//
const cattSize = 'attendeeNameSize';
const cattX = 'attendeeNameX';
const cattY = 'attendeeNameY';
const cattColor = 'attendeeNameColor';
const ctypeSize = 'cardTypeSize';
const ctypeX = 'cardTypeX';
const ctypeY = 'cardTypeY';
const ctypeColor = 'cardTypeColor';
const cpassSize = 'passcodeSize';
const cpassX = 'passcodeX';
const cpassY = 'passcodeY';
const cpassColor = 'passcodeColor';
const cqrSize = 'qrcodeSize';
const cqrX = 'qrcodeX';
const cqrY = 'qrcodeY';
const cqrColor = 'qrcodeColor';
/* configs */

/* fields */
const tempcid = 'eventCardId';
const tempccurl = 'templateUrl';
//-----------------------//
const crdClrnc = 'clearAt';
const cevId = 'eventId';
const cname = 'name';
const cdsnumber = 'dispatched';
const cprice = 'price';
const ccapacity = 'capacity';
const cattendeename = "attendee_name";
const crdChkpns = "checkpoints";
const ccount = 'count';
const ctimestamp = 'createdOn';
/* fields */

enum KardType { invitation, contribution, save_the_date, contact }

class Kard {
  String id;
  String type;
  List clearAt;
  String eventId;
  String purpose;
  DateTime createdAt;
  DateTime updatedAt;
  int capacity;

  Kard({
    required this.id,
    required this.type,
    required this.purpose,
    required this.clearAt,
    required this.eventId,
    required this.createdAt,
    required this.updatedAt,
    required this.capacity,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'clearAt': clearAt,
      'eventId': eventId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'purpose': purpose,
      'capacity': capacity,
    };
  }

  factory Kard.fromMap(String id, Map<String, dynamic> map) {
    return Kard(
      id: id,
      type: map['type'] ?? "",
      purpose: map['purpose'] ?? "",
      clearAt: map['clearAt'] ?? [],
      eventId: map['eventId'] ?? "",
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      capacity: (map['capacity'] as num).toInt(),
    );
  }
}

class CardConfig {
  String? id;
  String type;
  List clearAt;
  String eventId;
  String purpose;
  double cardHeight;
  double cardWidth;
  dynamic elements;
  DateTime createdAt;
  DateTime updatedAt;
  String templateUrl;
  int capacity;

  CardConfig({
    this.id,
    required this.type,
    required this.purpose,
    required this.clearAt,
    required this.eventId,
    required this.cardWidth,
    required this.cardHeight,
    required this.createdAt,
    required this.updatedAt,
    required this.elements,
    required this.capacity,
    required this.templateUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,
      'type': type,
      'clearAt': clearAt,
      'eventId': eventId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'purpose': purpose,
      'elements': elements,
      'cardWidth': cardWidth,
      'cardHeight': cardHeight,
      'capacity': capacity,
      'templateUrl': templateUrl,
    };
  }

  factory CardConfig.fromMap(String id, Map<String, dynamic> map) {
    return CardConfig(
      id: id,
      type: map['type'] ?? "",
      purpose: map['purpose'] ?? "",
      clearAt: map['clearAt'] ?? [],
      eventId: map['eventId'] ?? "",
      cardWidth: map['cardWidth'] ?? 10,
      cardHeight: map['cardHeight'] ?? 10,
      elements: map['elements'] ?? {},
      templateUrl: map['templateUrl'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      capacity: (map['capacity'] as num).toInt(),
    );
  }
}
