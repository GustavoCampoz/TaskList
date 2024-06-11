import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initSetttings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initSetttings);
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
                decoration: const InputDecoration(labelText: 'Task Description'),
              ),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Task Date and Time'),
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
                      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
                      scheduleNotification(finalDateTime, _taskController.text);
                    }
                  }
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    tasks.add({
                      'description': _taskController.text,
                      'date': _dateController.text,
                    });
                    Navigator.pop(context);
                  });
                },
                child: const Text('Add Task'),
              ),
            ],
          ),
        ),
      );
    }));
  }

  Future<void> scheduleNotification(DateTime dateTime, String taskDescription) async {
    var androidDetails = AndroidNotificationDetails(
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
