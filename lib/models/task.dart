class Task {
  String title;
  bool isCompleted;
  String priority;
  DateTime? dueDate;

  Task({
    required this.title,
    this.isCompleted = false,
    this.priority = "Low",
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        isCompleted: json['isCompleted'],
        priority: json['priority'] ?? "Low",
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'])
            : null,
      );
}