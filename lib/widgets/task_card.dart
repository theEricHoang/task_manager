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
  bool _isAddingSubtask = false;
  String? _subtaskErrorText;

  Future<void> _addSubtask() async {
    final name = _subtaskController.text.trim();
    if (name.isEmpty) {
      setState(() => _subtaskErrorText = 'Subtask name cannot be empty');
      return;
    }
    setState(() {
      _subtaskErrorText = null;
      _isAddingSubtask = true;
    });
    try {
      await _subtaskService.addSubtask(widget.task.id, name: name);
      _subtaskController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add subtask: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAddingSubtask = false);
    }
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    try {
      await _subtaskService.toggleComplete(
        widget.task.id,
        subtask.id,
        subtask.completionStatus,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update subtask: $e')));
      }
    }
  }

  Future<void> _confirmDeleteSubtask(Subtask subtask) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subtask'),
        content: Text('Delete "${subtask.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _subtaskService.deleteSubtask(widget.task.id, subtask.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete subtask: $e')));
      }
    }
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: InputDecoration(
                        hintText: 'Enter subtask name',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        errorText: _subtaskErrorText,
                      ),
                      style: const TextStyle(fontSize: 14),
                      enabled: !_isAddingSubtask,
                      onChanged: (_) {
                        if (_subtaskErrorText != null) {
                          setState(() => _subtaskErrorText = null);
                        }
                      },
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isAddingSubtask
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ElevatedButton(
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Error loading subtasks: ${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
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
                      onToggle: (_) => _toggleSubtask(subtask),
                      onDelete: () => _confirmDeleteSubtask(subtask),
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
