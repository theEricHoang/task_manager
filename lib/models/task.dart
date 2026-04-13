class Task {
  final String name;
  final bool completionStatus;

  Task({required this.name, required this.completionStatus});

  Map<String, dynamic> toMap() {
    return {'name': name, 'completionStatus': completionStatus};
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      name: map['name'] as String,
      completionStatus: map['completionStatus'] as bool,
    );
  }
}
