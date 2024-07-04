import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Task List',
      home: TaskPage(),
    );
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<Map<String, dynamic>> tasks = [];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initSetttings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initSetttings);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    List<Map<String, dynamic>> tasksFromDb = await _dbHelper.getTasks();
    setState(() {
      tasks = tasksFromDb;
    });
  }

  void _addTask() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Task')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _taskController,
                decoration:
                    const InputDecoration(labelText: 'Task Description'),
              ),
              TextField(
                controller: _dateController,
                decoration:
                    const InputDecoration(labelText: 'Task Date and Time'),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101));
                  if (picked != null) {
                    TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      DateTime finalDateTime = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time.hour,
                        time.minute,
                      );
                      _dateController.text =
                          DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
                      scheduleNotification(finalDateTime, _taskController.text);
                    }
                  }
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_taskController.text.isNotEmpty &&
                      _dateController.text.isNotEmpty) {
                    Map<String, dynamic> newTask = {
                      'description': _taskController.text,
                      'date': _dateController.text,
                    };
                    await _dbHelper.insertTask(newTask);
                    _taskController.clear();
                    _dateController.clear();
                    _loadTasks();
                    Navigator.pop(
                        context); // Voltar para a tela inicial após adicionar a tarefa
                  } else {
                    // Mostre uma mensagem de erro se os campos estiverem vazios
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha todos os campos')),
                    );
                  }
                },
                child: const Text('Add Task'),
              ),
            ],
          ),
        ),
      );
    }));
  }

  Future<void> scheduleNotification(
      DateTime dateTime, String taskDescription) async {
    var androidDetails = const AndroidNotificationDetails(
      'channelId',
      'channelName',
      importance: Importance.max,
      priority: Priority.high,
    );
    var generalNotificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Task Reminder',
      taskDescription,
      tz.TZDateTime.from(dateTime, tz.local),
      generalNotificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _showTaskDetails(Map<String, dynamic> task, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task['description']),
          content: Text('Date and Time: ${task['date']}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await _dbHelper.deleteTask(task['id']);
                _loadTasks();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task List')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tasks[index]['description']),
            subtitle: Text(tasks[index]['date']),
            onTap: () => _showTaskDetails(tasks[index], index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
