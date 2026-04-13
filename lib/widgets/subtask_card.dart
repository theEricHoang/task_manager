import 'package:flutter/material.dart';
import '../models/subtask.dart';

class SubtaskCard extends StatelessWidget {
  final Subtask subtask;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  const SubtaskCard({
    super.key,
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: Card(
        elevation: 1,
        child: ListTile(
          dense: true,
          leading: Checkbox(
            value: subtask.completionStatus,
            onChanged: onToggle,
          ),
          title: Text(
            subtask.name,
            style: TextStyle(
              fontSize: 14,
              decoration: subtask.completionStatus
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}
