import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/subtask_service.dart';
import 'subtask_card.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final SubtaskService _subtaskService = SubtaskService();
  final TextEditingController _subtaskController = TextEditingController();
  bool _isExpanded = false;

  void _addSubtask() {
    final name = _subtaskController.text.trim();
    if (name.isEmpty) return;
    _subtaskService.addSubtask(widget.task.id, name: name);
    _subtaskController.clear();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: widget.task.completionStatus,
              onChanged: widget.onToggle,
            ),
            title: Text(
              widget.task.name,
              style: TextStyle(
                decoration: widget.task.completionStatus
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 32.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: const InputDecoration(
                        hintText: 'Enter subtask name',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSubtask,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<Subtask>>(
              stream: _subtaskService.streamSubtasks(widget.task.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 32.0, bottom: 8.0),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final subtasks = snapshot.data ?? [];

                if (subtasks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(left: 32.0, bottom: 8.0),
                    child: Text(
                      'No subtasks yet.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subtasks.length,
                  itemBuilder: (context, index) {
                    final subtask = subtasks[index];
                    return SubtaskCard(
                      subtask: subtask,
                      onToggle: (_) => _subtaskService.toggleComplete(
                        widget.task.id,
                        subtask.id,
                        subtask.completionStatus,
                      ),
                      onDelete: () => _subtaskService.deleteSubtask(
                        widget.task.id,
                        subtask.id,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
