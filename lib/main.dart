import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_model.dart';

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Load theme preference from shared_preferences
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // Toggle and save theme preference
  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      home: TaskListScreen(onToggleTheme: _toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}


// Main screen widget
class TaskListScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const TaskListScreen({super.key, required this.onToggleTheme});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _taskController = TextEditingController();
  List<Task> _tasks = []; // Instance variable to hold the list of tasks
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Data Persistence Methods 

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> taskJson = jsonDecode(tasksString);
      setState(() {
        _tasks = taskJson.map((json) => Task.fromJson(json)).toList();
        _sortTasks();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString =
        jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksString);
  }

  // Task Management Methods
  // All methods use setState to update the UI accordingly

  void _addTask() {
    final String taskName = _taskController.text.trim();
    if (taskName.isNotEmpty) {
      setState(() {
        _tasks.add(Task(
          id: DateTime.now().toString(),
          name: taskName,
          priority: _selectedPriority,
        ));
        _taskController.clear();
        _sortTasks(); // Sort after adding a new task
        _saveTasks();
      });
    }
  }

  void _toggleTaskCompletion(String id) {
    setState(() {
      final task = _tasks.firstWhere((task) => task.id == id);
      task.isCompleted = !task.isCompleted;
      _saveTasks();
    });
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((task) => task.id == id);
      _saveTasks();
    });
  }

  void _changeTaskPriority(String id, TaskPriority newPriority) {
    setState(() {
      final task = _tasks.firstWhere((task) => task.id == id);
      task.priority = newPriority;
      _sortTasks(); // Re-sort the list when a priority changes
      _saveTasks();
    });
  }

  void _sortTasks() {
    _tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTaskInputSection(), // UI for adding tasks
            const SizedBox(height: 20),
            Expanded(
              child: _buildTaskList(), // UI to display the list of tasks
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the text input field, priority selector, and Add button
  Widget _buildTaskInputSection() {
    return Row(
      children: [
        Expanded(
          child: TextField( // Text input field
            controller: _taskController,
            decoration: const InputDecoration(
              labelText: 'Enter a new task',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Dropdown for selecting priority
        DropdownButton<TaskPriority>(
          value: _selectedPriority,
          onChanged: (TaskPriority? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPriority = newValue;
              });
            }
          },
          items: TaskPriority.values.map((priority) {
            return DropdownMenuItem<TaskPriority>(
              value: priority,
              child: Text(priority.name[0].toUpperCase()),
            );
          }).toList(),
        ),
        const SizedBox(width: 8),
        ElevatedButton( // Add button
          onPressed: _addTask, // Implements add functionality
          child: const Text('Add'),
        ),
      ],
    );
  }

  // Widget for displaying the list of tasks
  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Checkbox( // Checkbox to mark task as complete
              value: task.isCompleted,
              onChanged: (_) => _toggleTaskCompletion(task.id), // Implements completion functionality
            ),
            title: Text(
              task.name,
              style: TextStyle(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            // Displays task priority next to the task
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Allows priority changes after creation
                DropdownButton<TaskPriority>(
                    value: task.priority,
                    onChanged: (newVal) => _changeTaskPriority(task.id, newVal!),
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name[0].toUpperCase()),
                            ))
                        .toList()),
                IconButton( // Delete button
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTask(task.id), // Implements delete functionality
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}