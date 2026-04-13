import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subtask.dart';

class SubtaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _subtasksCollection(String taskId) {
    return _firestore.collection('tasks').doc(taskId).collection('subtasks');
  }

  Stream<List<Subtask>> streamSubtasks(String taskId) {
    return _subtasksCollection(taskId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Subtask.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addSubtask(String taskId, {required String name}) async {
    await _subtasksCollection(
      taskId,
    ).add({'name': name, 'completionStatus': false});
  }

  Future<void> toggleComplete(
    String taskId,
    String subtaskId,
    bool currentStatus,
  ) async {
    await _subtasksCollection(
      taskId,
    ).doc(subtaskId).update({'completionStatus': !currentStatus});
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    await _subtasksCollection(taskId).doc(subtaskId).delete();
  }
}
