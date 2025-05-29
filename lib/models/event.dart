String ecol = 'events';
String etcol = 'Tickets';
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

class Event {
  String id;
  String title;
  String authorId;
  List adminsIds;
  List usersIds;
  String status;
  String categoryId;
  String categoryLevel;
  DateTime createdAt;
  DateTime updatedAt;
  String description;
  String eventPlanId;
  String eventThumbnail;
  String location;
  String supportPhone;
  List<EventCalendar> calendar;

  Event({
    required this.id,
    required this.title,
    required this.authorId,
    required this.adminsIds,
    required this.usersIds,
    required this.categoryId,
    required this.categoryLevel,
    required this.createdAt,
    required this.updatedAt,
    required this.description,
    required this.eventPlanId,
    required this.eventThumbnail,
    required this.location,
    required this.status,
    required this.supportPhone,
    this.calendar = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'authorId': authorId,
    'adminsIds': adminsIds,
    'usersIds': usersIds,
    'categoryId': categoryId,
    'categoryLevel': categoryLevel,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'description': description,
    'eventPlanId': eventPlanId,
    'eventThumbnail': eventThumbnail,
    'location': location,
    'status': status,
    'supportPhone': supportPhone,
    'calendar':
        calendar.map((e) {
          return e.toMap();
        }).toList(),
  };

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      title: map['title'] ?? '',
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
      calendar:
          map['calendar'].map<EventCalendar>((e) {
            return EventCalendar.fromMap(e);
          }).toList(),
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
