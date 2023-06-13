import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void showNotification(int id, String title, String description) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gradufsc_notification', // ID do canal de notificação
      'Gradufsc', // Nome do canal de notificação
      importance: Importance.high, // Importância da notificação
      priority: Priority.high, // Prioridade da notificação
      // color: Colors.blue, // Cor da notificação
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      description,
      platformChannelSpecifics,
    );
  }

  void scheduleNotification(
    String title,
    String description,
    int id,
    DateTime scheduleTime,
    Duration notificationOffset,
  ) {
    DateTime notificationTime = scheduleTime.subtract(notificationOffset);

    AndroidAlarmManager.oneShotAt(
      notificationTime,
      id,
      () => showNotification(id, title, description),
      exact: true,
      wakeup: true,
    );
    // saveAlarmId(id);
  }

  void scheduleNotificationWeekly(
    int id,
    String title,
    String description,
    int weekDay, // (0 - domingo, 1 - segunda, ..., 6 - sábado)
    TimeOfDay timeOfDay,
    Duration notificationOffset,
  ) async {
    tz.initializeTimeZones();

    final String timeZoneName = 'America/Sao_Paulo';
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    )
        .add(Duration(days: (weekDay - now.weekday + 7) % 7))
        .subtract(notificationOffset);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      description,
      scheduledDate,
      const NotificationDetails(
          android:
              AndroidNotificationDetails('gradufsc_notification', 'Gradufsc')),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: "weekly",
    );
  }

  void scheduleUserGrade(Map<String, dynamic> data) async {
    cancelAllNotifications();

    bool authorized = await requestNotificationPermission();

    if (authorized) {
      var schedule = data['schedule'];
      var courses = data['courses'];

      Map<String, String> codeNameMap = {};

      for (var course in courses) {
        codeNameMap[course["code"]] = course['name'];
      }

      schedule.forEach((sch) {
        int index = schedule.indexOf(sch) + 1;

        String? courseName = codeNameMap[sch['course_code']];

        String title = courseName ?? "";

        String description =
            'Sua aula começa em 30 minutos em ${sch["location_center"]}-${sch["location_room"]}';

        int weekDay = (sch['week_day'] - 1) % 7;

        int hour = sch['time'] ~/ 100;
        int minute = sch['time'] % 100;

        TimeOfDay timeOfDay = TimeOfDay(hour: hour, minute: minute);
        Duration notificationOffset = Duration(minutes: 30);

        scheduleNotificationWeekly(
            index, title, description, weekDay, timeOfDay, notificationOffset);
      });
    }
  }

  void cancelNotification(int id) async {
    // AndroidAlarmManager.cancel(id);
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  void cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<bool> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;

    if (status != PermissionStatus.granted) {
      status = await Permission.notification.request();

      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }
}
