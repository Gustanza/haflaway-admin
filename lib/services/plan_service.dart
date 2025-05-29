import 'package:cloud_firestore/cloud_firestore.dart';

const eplancol = 'eventPlans';

class EventPlan {
  final String id;
  final String name;
  final double winvmsgprice;
  final double smsinvmsgprice;
  final double wremmsgprice;
  final double smsremmsgprice;
  final double wgratmsgprice;
  final double smsgratmsgprice;
  List services;

  EventPlan({
    required this.id,
    required this.name,
    required this.winvmsgprice,
    required this.smsinvmsgprice,
    required this.wremmsgprice,
    required this.smsremmsgprice,
    required this.wgratmsgprice,
    required this.smsgratmsgprice,
    required this.services,
  });

  factory EventPlan.fromMap(String id, Map<String, dynamic> map) {
    return EventPlan(
      id: id,
      name: map['name'] as String,
      winvmsgprice:
          map['winvmsgprice'] != null
              ? (map['winvmsgprice'] as num).toDouble()
              : 0,
      smsinvmsgprice:
          map['smsinvmsgprice'] != null
              ? (map['smsinvmsgprice'] as num).toDouble()
              : 0,
      wremmsgprice:
          map['wremmsgprice'] != null
              ? (map['wremmsgprice'] as num).toDouble()
              : 0,
      smsremmsgprice:
          map['smsremmsgprice'] != null
              ? (map['smsremmsgprice'] as num).toDouble()
              : 0,
      wgratmsgprice:
          map['wgratmsgprice'] != null
              ? (map['wgratmsgprice'] as num).toDouble()
              : 0,
      smsgratmsgprice:
          map['smsgratmsgprice'] != null
              ? (map['smsgratmsgprice'] as num).toDouble()
              : 0,
      services: map['services'],
    );
  }
}

class EventPlanService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<EventPlan> watchEventPlan({eventPlanId}) {
    return firestore.collection(eplancol).doc(eventPlanId).snapshots().map((
      snapshot,
    ) {
      return EventPlan.fromMap(
        snapshot.id,
        snapshot.data() as Map<String, dynamic>,
      );
    });
  }
}
