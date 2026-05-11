import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore paths
//   events/{eventId}/zawadiItems/{itemId}
//   events/{eventId}/zawadiContributions/{contributionId}
const zawadiItemsCol = 'zawadiItems';
const zawadiContribCol = 'zawadiContributions';

class ZawadiItem {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final double targetAmount;
  final String currency;
  final int order;
  final bool isActive;
  final double totalFunded;
  final int contributorCount;
  final DateTime? createdAt;

  const ZawadiItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.targetAmount,
    this.currency = 'TZS',
    this.order = 0,
    this.isActive = true,
    this.totalFunded = 0,
    this.contributorCount = 0,
    this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (totalFunded / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remaining =>
      (targetAmount - totalFunded).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() => {
    'title': title,
    if (description != null && description!.isNotEmpty)
      'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'targetAmount': targetAmount,
    'currency': currency,
    'order': order,
    'isActive': isActive,
    'totalFunded': totalFunded,
    'contributorCount': contributorCount,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory ZawadiItem.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ZawadiItem(
      id: doc.id,
      title: m['title'] ?? '',
      description: m['description'],
      imageUrl: m['imageUrl'],
      targetAmount: (m['targetAmount'] as num?)?.toDouble() ?? 0,
      currency: m['currency'] ?? 'TZS',
      order: (m['order'] as num?)?.toInt() ?? 0,
      isActive: m['isActive'] ?? true,
      totalFunded: (m['totalFunded'] as num?)?.toDouble() ?? 0,
      contributorCount: (m['contributorCount'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ZawadiContribution {
  final String id;
  final String itemId;
  final String attendeeId;
  final String attendeeName;
  final String attendeeInitial;
  final double amount;
  final String? note;
  final String status; // PENDING | PAID | FAILED
  final String? pesapalOrderId;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const ZawadiContribution({
    required this.id,
    required this.itemId,
    required this.attendeeId,
    required this.attendeeName,
    required this.attendeeInitial,
    required this.amount,
    this.note,
    this.status = 'PENDING',
    this.pesapalOrderId,
    this.createdAt,
    this.paidAt,
  });

  factory ZawadiContribution.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ZawadiContribution(
      id: doc.id,
      itemId: m['itemId'] ?? '',
      attendeeId: m['attendeeId'] ?? '',
      attendeeName: m['attendeeName'] ?? '',
      attendeeInitial: m['attendeeInitial'] ?? '?',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      note: m['note'],
      status: m['status'] ?? 'PENDING',
      pesapalOrderId: m['pesapalOrderId'],
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      paidAt: (m['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}
