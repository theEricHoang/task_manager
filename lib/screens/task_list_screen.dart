import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _nameController = TextEditingController();
  String? _errorText;
  bool _isAdding = false;

  Future<void> _addTask() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Task name cannot be empty');
      return;
    }
    setState(() {
      _errorText = null;
      _isAdding = true;
    });
    try {
      await _taskService.addTask(name: name, completionStatus: false);
      _nameController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      await _taskService.toggleComplete(task.id, task.completionStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    }
  }

  Future<void> _confirmDeleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.name}" and all its subtasks?'),
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
      await _taskService.deleteTask(task.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete task: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Task Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter task name',
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                    enabled: !_isAdding,
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                _isAdding
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _addTask,
                        child: const Text('Add'),
                      ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.streamTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        const Text('No tasks yet. Add one above!'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onToggle: (_) => _toggleTask(task),
                      onDelete: () => _confirmDeleteTask(task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
