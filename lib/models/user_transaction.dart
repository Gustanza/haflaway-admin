const userTransCol = 'userTransactions';

class UserTransaction {
  double amount;
  String authorId;
  String createdAt;
  String eventId;
  Map? params;
  String reason;

  UserTransaction({
    required this.amount,
    required this.authorId,
    required this.createdAt,
    required this.eventId,
    this.params,
    required this.reason,
  });

  Map<String, dynamic> toMap() => {
    "amount": amount,
    "authorId": authorId,
    "createdAt": createdAt,
    "eventId": eventId,
    if (params != null) "params": params,
    "reason": reason,
  };

  factory UserTransaction.fromMap({id, map}) {
    return UserTransaction(
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : 0.00,
      authorId: map['authorId'] ?? "notset",
      createdAt: "${map['createdAt']}" ?? DateTime(1990).toIso8601String(),
      eventId: map['eventId'] ?? "notset",
      reason: map['reason'] ?? "notset",
    );
  }
}
