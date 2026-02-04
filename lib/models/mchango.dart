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
    return Mchango(
      id: id,
      amount: map['amount'] ?? 0.00,
      method: PayMethod.manual,
      createdAt: map['createdAt'] ?? DateTime(1920).toIso8601String(),
      updateAt: map['updateAt'] ?? DateTime(1920).toIso8601String(),
    );
  }
}

enum PayMethod { electronic, manual }
