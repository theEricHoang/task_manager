class Subtask {
  final String id;
  final String name;
  final bool completionStatus;

  Subtask({
    required this.id,
    required this.name,
    required this.completionStatus,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'completionStatus': completionStatus};
  }

  factory Subtask.fromMap(String id, Map<String, dynamic> map) {
    return Subtask(
      id: id,
      name: map['name'] as String,
      completionStatus: map['completionStatus'] as bool,
    );
  }
}
