import 'package:haflaway/utils/helpers.dart';

String campcol = "campaigns";

class Campaign {
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;
  String? type;

  Campaign({
    this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.type,
  });

  Map<String, dynamic> toMap() => {
    if (name != null) "name": name,
    if (createdAt != null) "createdAt": createdAt,
    if (updatedAt != null) "updatedAt": updatedAt,
    if (type != null) "type": type,
  };

  factory Campaign.fromMap({id, map}) {
    DateTime dtime =
        map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime(1990);
    String crtdAt = formatDate(dtime: dtime);
    return Campaign(
      id: id,
      name: map['name'] ?? "",
      createdAt: crtdAt,
      updatedAt: map['updatedAt'],
      type: map['type'] ?? "",
    );
  }
}
