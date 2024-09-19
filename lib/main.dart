import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 15, 202, 223)),
        useMaterial3: true,
      ),
      home: const TodaApp(),
    );
  }
}

class TodaApp extends StatefulWidget {
  const TodaApp({super.key});

  @override
  State<TodaApp> createState() => _TodaAppState();
}

class _TodaAppState extends State<TodaApp> {
  late TextEditingController _texteditController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _texteditController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  // Function to show add task dialog
  void addTodoHandle(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add new task"),
            content: SizedBox(
              width: 120,
              height: 140,
              child: Column(
                children: [
                  TextField(
                    controller: _texteditController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Input your task"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "Description"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    CollectionReference tasks =
                        FirebaseFirestore.instance.collection("tasks");
                    tasks.add({
                      'name': _texteditController.text,
                      'note': _descriptionController.text,
                      'completed':
                          false, // เพิ่มฟิลด์สถานะงานเริ่มต้นเป็น false
                    }).then((res) {
                      print(res);
                    }).catchError((onError) {
                      print("Failed to add new Task");
                    });

                    _texteditController.clear();
                    _descriptionController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("Save"))
            ],
          );
        });
  }

  // Function to show edit task dialog
  void editTodoHandle(BuildContext context, String taskId, String name,
      String note, bool completed) {
    _texteditController.text = name;
    _descriptionController.text = note;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Edit task"),
            content: SizedBox(
              width: 120,
              height: 140,
              child: Column(
                children: [
                  TextField(
                    controller: _texteditController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "Task"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "Description"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    CollectionReference tasks =
                        FirebaseFirestore.instance.collection("tasks");

                    tasks.doc(taskId).update({
                      'name': _texteditController.text,
                      'note': _descriptionController.text,
                      'completed': completed, // อัปเดตสถานะงานด้วย
                    }).then((res) {
                      print("Task updated");
                    }).catchError((onError) {
                      print("Failed to update task");
                    });

                    _texteditController.clear();
                    _descriptionController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("Save"))
            ],
          );
        });
  }

  // Function to delete a task
  void deleteTask(String taskId) {
    CollectionReference tasks = FirebaseFirestore.instance.collection("tasks");
    tasks.doc(taskId).delete().catchError((onError) {
      print("Failed to delete task");
    });
  }

  // Function to update task's completed status
  void updateTaskStatus(String taskId, bool newStatus) {
    CollectionReference tasks = FirebaseFirestore.instance.collection("tasks");
    tasks.doc(taskId).update({'completed': newStatus}).catchError((onError) {
      print("Failed to update task status");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("tasks").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return const Text("Something went wrong");
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No tasks available");
            }

            return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var task = snapshot.data!.docs[index];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // เพิ่ม Checkbox ที่เชื่อมโยงกับฟิลด์ completed
                        Checkbox(
                          value: task['completed'],
                          onChanged: (value) {
                            updateTaskStatus(task.id, value!);
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['name'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: task['completed']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  decoration: task['completed']
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              if (task['note'] != null && task['note'] != "")
                                Text(task['note']),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            editTodoHandle(context, task.id, task['name'],
                                task['note'], task['completed']);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteTask(task.id);
                          },
                        )
                      ],
                    ),
                  );
                });
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
