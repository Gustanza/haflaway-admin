import 'package:cloud_firestore/cloud_firestore.dart';

const usrsCol = 'users';
const usrsBlTrSbCol = 'transactions';

class JpUser {
  final String id;
  final double balance;
  final List<BalanceTransaction> transactions;

  JpUser({
    required this.id,
    required this.balance,
    this.transactions = const [],
  });

  Map<String, dynamic> toMap() {
    return {"balance": balance};
  }

  factory JpUser.fromMap(Map<String, dynamic> map, String id) {
    return JpUser(id: id, balance: (map['balance'] as num).toDouble());
  }
}

class BalanceTransaction {
  final String id;
  final double amount;
  final String modifiedByUserId;
  final String reason;
  final DateTime timestamp;
  final TransactionType type;

  BalanceTransaction({
    required this.id,
    required this.amount,
    required this.modifiedByUserId,
    required this.reason,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      "amount": amount,
      "modifiedByUserId": modifiedByUserId,
      "reason": reason,
      "timestamp": timestamp.toIso8601String(),
      "type": type.name
    };
  }

  factory BalanceTransaction.fromMap(String id, Map<String, dynamic> map) {
    return BalanceTransaction(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      modifiedByUserId: map['modifiedByUserId'] as String,
      reason: map['reason'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: TransactionType.values.firstWhere(
        (e) {
          return e.name == map['type'];
        },
        orElse: () => TransactionType.unknown,
      ),
    );
  }
}

enum TransactionType {
  increase,
  decrease,
  unknown,
}

class BalanceService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<JpUser> watchBalance(String userId) {
    return firestore
        .collection(usrsCol)
        .doc(userId)
        .snapshots()
        .map((cvrt) => JpUser.fromMap(
              cvrt.data() as Map<String, dynamic>,
              cvrt.id,
            ));
  }

  Stream<List<BalanceTransaction>> watchTransactions(String userId) {
    return firestore
        .collection(usrsCol)
        .doc(userId)
        .collection(usrsBlTrSbCol)
        .snapshots()
        .map((cvrt) {
      return cvrt.docs.map((doc) {
        return BalanceTransaction.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> alterBalance(
    String userId,
    double amount,
    String reason,
    String modifiedByUserId,
    TransactionType type,
  ) async {
    WriteBatch batch = firestore.batch();
    var balaceRef = firestore.collection(usrsCol).doc(userId);
    var trnsRef = balaceRef.collection(usrsBlTrSbCol).doc();
    var ramount = type == TransactionType.increase ? amount : -amount;
    batch.update(balaceRef, {"balance": FieldValue.increment(ramount)});

    var trns = BalanceTransaction(
      id: trnsRef.id,
      amount: ramount,
      reason: reason,
      type: type,
      timestamp: DateTime.now(),
      modifiedByUserId: modifiedByUserId,
    );

    batch.set(trnsRef, trns.toMap());
    await batch.commit();
  }
}
