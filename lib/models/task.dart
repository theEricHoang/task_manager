class Task {
  final String id;
  final String name;
  final bool completionStatus;

  Task({required this.id, required this.name, required this.completionStatus});

  Map<String, dynamic> toMap() {
    return {'name': name, 'completionStatus': completionStatus};
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      name: map['name'] as String,
      completionStatus: map['completionStatus'] as bool,
    );
  }
}
