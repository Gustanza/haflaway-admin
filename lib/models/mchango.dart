import 'package:cloud_firestore/cloud_firestore.dart';

class Mchango {
  String? id;
  double? amount;
  PayMethod method;
  String? createdAt;
  String? updateAt;

  Mchango({
    this.method = PayMethod.manual,
    this.amount,
    this.id,
    this.createdAt,
    this.updateAt,
  });

  Map<String, dynamic> toMap() => {
    if (amount != null) "amount": amount,
    "method": method.name,
    if (createdAt != null) "createdAt": createdAt,
    if (updateAt != null) "amount": updateAt,
  };

  factory Mchango.fromMap(String id, Map<String, dynamic> map) {
    var createdAt = map['createdAt'] ?? DateTime(1920).toIso8601String();
    var updateAt = map['updateAt'] ?? DateTime(1920).toIso8601String();
    var method = PayMethod.manual;
    if (map['method'] != null && map['method'] == PayMethod.digital.name) {
      method = PayMethod.digital;
    } else if (map['method'] != null &&
        map['method'] == PayMethod.manual.name) {
      method = PayMethod.manual;
    }
    var amount =
        map['amount'] != null ? (map['amount'] as num).toDouble() : 0.00;
    //
    return Mchango(
      id: id,
      amount: amount,
      method: method,
      createdAt: createdAt,
      updateAt: updateAt,
    );
  }
}

enum PayMethod { digital, manual }
