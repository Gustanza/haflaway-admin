class AttendeeMessage {
  String? id;
  String type;
  String channel;
  String status;

  AttendeeMessage({
    this.id,
    required this.type,
    required this.channel,
    required this.status,
  });

  factory AttendeeMessage.fromMap({id, map}) {
    return AttendeeMessage(
      id: id ?? "",
      type: map['type'] ?? "",
      channel: map['channel'] ?? "",
      status: map['status'] ?? "",
    );
  }
}
