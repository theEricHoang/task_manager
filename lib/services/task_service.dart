import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final CollectionReference _tasksCollection = FirebaseFirestore.instance
      .collection('tasks');

  Stream<List<Task>> streamTasks() {
    return _tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addTask({
    required String name,
    required bool completionStatus,
  }) async {
    await _tasksCollection.add({
      'name': name,
      'completionStatus': completionStatus,
    });
  }

  Future<void> toggleComplete(String taskId, bool currentStatus) async {
    await _tasksCollection.doc(taskId).update({
      'completionStatus': !currentStatus,
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }
}
