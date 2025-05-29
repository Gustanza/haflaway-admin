const msglogcol = 'messageLogs';

class MessageLog {
  String id;
  String message;
  String eventId;
  String attendeeId;
  LogType type;
  String phoneNumber;
  SMSStatus smsStatus;
  DateTime timestamp;
  int failureCount;

  MessageLog({
    required this.id,
    required this.message,
    required this.eventId,
    required this.attendeeId,
    required this.type,
    required this.smsStatus,
    required this.timestamp,
    required this.phoneNumber,
    required this.failureCount,
  });

  Map<String, dynamic> toMap() => {
    'message': message,
    'eventId': eventId,
    'attendeeId': attendeeId,
    'type': type.name,
    'smsStatus': smsStatus.name,
    'phoneNumber': phoneNumber,
    'timestamp': timestamp.toIso8601String(),
    'failureCount': failureCount,
  };

  factory MessageLog.fromMap(String id, Map<String, dynamic> map) {
    return MessageLog(
      id: id,
      message: map['message'],
      eventId: map['eventId'],
      attendeeId: map['attendeeId'],
      type: LogType.values.firstWhere((e) {
        return e.name == map['type'];
      }, orElse: () => LogType.invitationMessage),
      smsStatus: SMSStatus.values.firstWhere((e) {
        return e.name == map['smsStatus'];
      }, orElse: () => SMSStatus.PENDING),
      timestamp: DateTime.parse(map['timestamp']),
      phoneNumber: map['phoneNumber'],
      failureCount: (map['failureCount'] as num).toInt(),
    );
  }
}

class MessageTemplate {
  String id;
  String category;
  String content;
  String language;

  MessageTemplate({
    required this.id,
    required this.category,
    required this.content,
    required this.language,
  });

  Map<String, dynamic> toMap() => {
    'category': category,
    'content': content,
    'language': language,
  };

  factory MessageTemplate.fromMap(String id, Map<String, dynamic> map) {
    return MessageTemplate(
      id: id,
      language: map['language'],
      category: map['category'],
      content: map['content'],
    );
  }
}

class MessageStatus {
  String sms;
  String whatsApp;

  MessageStatus({required this.sms, required this.whatsApp});

  Map<String, dynamic> toMap() => {'sms': sms, 'whatsApp': whatsApp};
}

enum LogType { invitationMessage, reminderMessage, gratitudeMessage }

enum SMSStatus { NOTSENT, UNDELIVERED, PENDING, DELIVERED, UNKNOWN }
