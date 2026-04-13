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
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  String? _errorText;
  bool _isAdding = false;
  String _searchQuery = '';

  /// The previous filtered snapshot, used to diff against the new one
  /// so we can drive AnimatedList insert/remove calls.
  List<Task> _currentTasks = [];

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

  List<Task> _filterTasks(List<Task> tasks) {
    if (_searchQuery.isEmpty) return tasks;
    final query = _searchQuery.toLowerCase();
    return tasks
        .where((task) => task.name.toLowerCase().contains(query))
        .toList();
  }

  /// Diffs [oldList] and [newList] by id, then drives AnimatedList
  /// insertions and removals with slide + fade animations.
  void _syncAnimatedList(List<Task> oldList, List<Task> newList) {
    final animatedList = _listKey.currentState;
    if (animatedList == null) return;

    final oldIds = oldList.map((t) => t.id).toList();
    final newIds = newList.map((t) => t.id).toSet();

    // Remove items no longer present (iterate in reverse to keep indices stable)
    for (var i = oldIds.length - 1; i >= 0; i--) {
      if (!newIds.contains(oldIds[i])) {
        final removedTask = oldList[i];
        animatedList.removeItem(
          i,
          (context, animation) => _buildAnimatedItem(removedTask, animation),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // Insert new items
    final oldIdSet = oldIds.toSet();
    for (var i = 0; i < newList.length; i++) {
      if (!oldIdSet.contains(newList[i].id)) {
        animatedList.insertItem(i, duration: const Duration(milliseconds: 300));
      }
    }
  }

  Widget _buildAnimatedItem(Task task, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: TaskCard(
          task: task,
          onToggle: (_) => _toggleTask(task),
          onDelete: () => _confirmDeleteTask(task),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
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
          // Add task row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),

          // Task list
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

                final allTasks = snapshot.data ?? [];
                final filteredTasks = _filterTasks(allTasks);

                // Diff the previous list against the new filtered list and
                // animate insertions / removals.
                _syncAnimatedList(_currentTasks, filteredTasks);
                _currentTasks = filteredTasks;

                if (allTasks.isEmpty) {
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

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        const Text('No tasks match your search.'),
                      ],
                    ),
                  );
                }

                return AnimatedList(
                  key: _listKey,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  initialItemCount: filteredTasks.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= _currentTasks.length) {
                      return const SizedBox.shrink();
                    }
                    final task = _currentTasks[index];
                    return _buildAnimatedItem(task, animation);
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
