final String notifCol = 'notifications';

class Nottification {
  String? id;
  String? title;
  String? userId;
  String? senderName;
  String? description;
  String? createdAt;
  String? updatedAt;

  Nottification({
    this.id,
    this.title,
    this.userId,
    this.senderName,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Nottification.fromMap({id, map}) {
    var deftstring = DateTime.now().toIso8601String();
    return Nottification(
      id: id,
      title: map['title'] ?? "",
      userId: map['userId'] ?? "",
      description: map['description'] ?? "",
      createdAt: map['createdAt'] ?? deftstring,
      updatedAt: map['updatedAt'] ?? deftstring,
      senderName: map['senderName'] ?? "Haflaway",
    );
  }
}
