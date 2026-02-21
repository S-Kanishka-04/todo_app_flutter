import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];
  String searchQuery = "";
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = tasks.map((e) => jsonEncode(e.toJson())).toList();
    prefs.setStringList("tasks", data);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList("tasks");

    if (data != null) {
      setState(() {
        tasks = data
            .map((e) => Task.fromJson(jsonDecode(e)))
            .toList();
      });
    }
  }

  void addTask(String title, String priority, DateTime? date) {
    if (title.isEmpty) return;

    setState(() {
      tasks.add(Task(
        title: title,
        priority: priority,
        dueDate: date,
      ));
    });

    saveTasks();
  }

  void toggleTask(int index) {
    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
    });
    saveTasks();
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    saveTasks();
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void showAddDialog() {
    TextEditingController controller = TextEditingController();
    String priority = "Low";
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Add Task"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(hintText: "Task title"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: priority,
                    isExpanded: true,
                    items: ["Low", "Medium", "High"]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        priority = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Text(selectedDate == null
                        ? "Select Due Date"
                        : selectedDate!
                            .toString()
                            .split(" ")[0]),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  addTask(controller.text, priority, selectedDate);
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = tasks.where((task) {
      final matchesSearch = task.title
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      final matchesFilter =
          selectedFilter == "All" || task.priority == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    int completed = tasks.where((t) => t.isCompleted).length;
    double progress = tasks.isEmpty ? 0 : completed / tasks.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "My Tasks",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: LinearProgressIndicator(value: progress),
            ),

            // SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration:
                    const InputDecoration(hintText: "Search task..."),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
            ),

            // FILTER
            DropdownButton<String>(
              value: selectedFilter,
              items: ["All", "Low", "Medium", "High"]
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedFilter = val!;
                });
              },
            ),

            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];

                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) =>
                            toggleTask(tasks.indexOf(task)),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: task.dueDate != null
                          ? Text(
                              "Due: ${task.dueDate!.toString().split(" ")[0]}")
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  getPriorityColor(task.priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              deleteTask(
                                  tasks.indexOf(task));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}