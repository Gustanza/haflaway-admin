class CheckPoint {
  String id;
  String name;

  CheckPoint({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'name': name};

  factory CheckPoint.fromMap(String id, Map<String, dynamic> map) {
    return CheckPoint(
      id: id,
      name: map['name'] as String,
    );
  }
}
