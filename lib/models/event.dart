String ecol = 'events';
String etcol = 'Tickets';
String evMsgTmpCol = "messageTemplates";
String eMsgTmpCol = 'messageTemplates';
String etypeEDef = 'Choose Category';

/* event-placeholders */
const eptitle = 'Event title';
const epcategory = "Event category";
const epbilolan = "Billing plan";
const epdescription = 'Event description';
const eplocation = 'Event location';
/* event-placeholders */

/* event-fields */
String eId = 'id';
//--checkpoints---//
const echecksub = "checkpoints";
const egalsub = "gallery";
const echeckname = 'name';
const echecknameVal = "General Entrance";
//--checkpoints---//

/* event-fields */
String ethumbnail = "event_thumbnail";
String etitle = "title";
String ecategory = "category_id";
String ecategoryLevel = "category_level";
String ecategoryname = "name";
String ecategoryphoto = "photo";
String ecategorylevel = "level";
String edescription = "description";
String elocation = 'location';
String eauthorId = 'author_id';

/* important */
String eadminsIds = 'adminsIds';
String eusersIds = 'usersIds';
String einvmessage = "invitationMessage";
String eremmessage = "reminderMessage";
String eScanPromo = "scanPromo";
/* important */

String estartdate = "start_date";
String eenddate = "end_date";
String ecalsubcol = 'calendar';
String ecrtdAt = 'created_at';
/* event-fields */

/* event-days-fields */
String eddate = "event_date";
String edstarttime = 'start_time';
String edendtime = 'end_time';
/* event-days-fields */

/* create card strings */
const newcard = 'New Card';
const createnewcard = "Create";
const editcard = "Edit";
const cardname = 'Card Type';
const cardart = 'Card Template';
const cardchecks = 'Allowed CheckPoint(s)';
const cardprice = 'Card Price';
const cardcount = 'Card Count';
const cardcap = 'Card Capacity';
/* create card strings */

class EventLocation {
  final String id;
  final String label;
  final String placeName;
  final double? lat;
  final double? lng;
  final String? mapsUrl;

  EventLocation({
    required this.id,
    required this.label,
    required this.placeName,
    this.lat,
    this.lng,
    this.mapsUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'placeName': placeName,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    if (mapsUrl != null) 'mapsUrl': mapsUrl,
  };

  factory EventLocation.fromMap(Map<String, dynamic> map) {
    return EventLocation(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      placeName: map['placeName'] ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      mapsUrl: map['mapsUrl'] as String?,
    );
  }
}

class AttendeeLabel {
  final String id;
  final String name;
  final int colorValue;

  AttendeeLabel({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
  };

  factory AttendeeLabel.fromMap(Map<String, dynamic> map) {
    return AttendeeLabel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF000000,
    );
  }
}

class Event {
  String? id;
  bool? usepng;
  String? title;
  String? titleLower;
  String? authorId;
  List? adminsIds;
  List? usersIds;
  String? status;
  String? categoryId;
  String? categoryLevel;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? description;
  String? eventPlanId;
  String? eventThumbnail;
  String? location;
  String? supportPhone;
  String? startDate;
  String? endDate;
  String? language;
  double? totalPledge;
  double? totalPayment;
  List<EventCalendar>? calendar;
  List<AttendeeLabel>? labels;
  List<EventLocation>? locations;
  String? scanPromo;

  Event({
    this.id,
    this.title,
    this.titleLower,
    this.authorId,
    this.adminsIds,
    this.usersIds,
    this.categoryId,
    this.categoryLevel,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.eventPlanId,
    this.eventThumbnail,
    this.location,
    this.status,
    this.supportPhone,
    this.usepng = true,
    this.startDate,
    this.endDate,
    this.language,
    this.totalPledge,
    this.totalPayment,
    this.calendar = const [],
    this.labels = const [],
    this.locations = const [],
    this.scanPromo,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    if (title != null) 'title': title,
    if (titleLower != null) 'titleLower': titleLower,
    if (authorId != null) 'authorId': authorId,
    if (adminsIds != null) 'adminsIds': adminsIds,
    if (usersIds != null) 'usersIds': usersIds,
    if (categoryId != null) 'categoryId': categoryId,
    if (categoryLevel != null) 'categoryLevel': categoryLevel,
    if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    if (description != null) 'description': description,
    if (eventPlanId != null) 'eventPlanId': eventPlanId,
    if (eventThumbnail != null) 'eventThumbnail': eventThumbnail,
    if (location != null) 'location': location,
    if (status != null) 'status': status,
    if (usepng != null) 'usepng': usepng,
    if (supportPhone != null) 'supportPhone': supportPhone,
    if (startDate != null) 'startDate': startDate,
    if (endDate != null) 'endDate': endDate,
    if (language != null) "language": language,
    if (totalPledge != null) 'totalPledge': totalPledge,
    if (totalPayment != null) 'totalPayment': totalPayment,
    if (calendar != null)
      'calendar':
          calendar?.map((e) {
            return e.toMap();
          }).toList(),
    if (labels != null)
      'labels':
          labels?.map((e) {
            return e.toMap();
          }).toList(),
    if (locations != null)
      'locations':
          locations?.map((e) {
            return e.toMap();
          }).toList(),
    if (scanPromo != null) 'scanPromo': scanPromo,
  };

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      titleLower: map['titleLower'] ?? '',
      authorId: map['authorId'] ?? '',
      adminsIds: map['adminsIds'] ?? [],
      usersIds: map['usersIds'] ?? [],
      status: map['status'] ?? 'draft',
      supportPhone: map['supportPhone'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryLevel: map['categoryLevel'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      description: map['description'] ?? '',
      eventPlanId: map['eventPlanId'] ?? '',
      eventThumbnail: map['eventThumbnail'] ?? '',
      location: map['location'] ?? '',
      usepng: map['usepng'] ?? true,
      language: map['language'] ?? 'sw',
      totalPledge:
          map['totalPledge'] != null
              ? (map['totalPledge'] as num).toDouble()
              : 0.0,
      totalPayment:
          map['totalPayment'] != null
              ? (map['totalPayment'] as num).toDouble()
              : 0.0,
      startDate: map['startDate'] ?? DateTime(1990).toIso8601String(),
      endDate: map['endDate'] ?? DateTime(1991).toIso8601String(),
      calendar:
          map['calendar'].map<EventCalendar>((e) {
            return EventCalendar.fromMap(e);
          }).toList(),
      labels:
          (map['labels'] as List?)?.map<AttendeeLabel>((e) {
            return AttendeeLabel.fromMap(e);
          }).toList() ??
          [],
      locations:
          (map['locations'] as List?)?.map<EventLocation>((e) {
            return EventLocation.fromMap(e as Map<String, dynamic>);
          }).toList() ??
          [],
      scanPromo: map['scanPromo'] as String?,
    );
  }
}

class EventCalendar {
  DateTime startTime;
  DateTime endTime;
  DateTime eventDate;

  EventCalendar({
    required this.startTime,
    required this.endTime,
    required this.eventDate,
  });

  Map<String, dynamic> toMap() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'eventDate': eventDate.toIso8601String(),
  };

  factory EventCalendar.fromMap(Map<String, dynamic> map) {
    return EventCalendar(
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      eventDate: DateTime.parse(map['eventDate'] as String),
    );
  }
}

const ecatcol = "eventCategories";

class EventCategory {
  String id;
  String name;
  String level;

  EventCategory({required this.id, required this.name, required this.level});

  factory EventCategory.fromMap(String id, Map<String, dynamic> map) {
    return EventCategory(
      id: id,
      name: map['name'] as String,
      level: map['level'] as String,
    );
  }
}
