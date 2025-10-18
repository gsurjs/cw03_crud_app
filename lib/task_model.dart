// Enum for task priority levels
enum TaskPriority { low, medium, high }

class Task {
  String id;
  String name;
  bool isCompleted;
  TaskPriority priority;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
  });

  // Methods to convert Task object to and from a Map for JSON serialization
  // For saving the data locally
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCompleted': isCompleted,
        'priority': priority.index, // Store enum as an integer
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        name: json['name'],
        isCompleted: json['isCompleted'],
        priority: TaskPriority.values[json['priority']],
      );
}