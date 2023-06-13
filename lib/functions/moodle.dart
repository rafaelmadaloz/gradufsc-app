import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const moodleUrl = 'https://moodle.ufsc.br/webservice/rest/server.php';

class MoodleHelper {
  Future<int?> getUserId(String token) async {
    const functionName = 'core_webservice_get_site_info';
    final url = Uri.parse(
        '$moodleUrl?wstoken=$token&moodlewsrestformat=json&wsfunction=$functionName');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['userid'];
    } else {
      throw Exception('Failed to get user id');
    }
  }

  Future<List<dynamic>?> getUserCourses(String token, String semester) async {
    var userId = await getUserId(token);
    if (userId != null) {
      var courses = [];
      const functionName = 'core_enrol_get_users_courses';
      final url = Uri.parse(
          '$moodleUrl?wstoken=$token&moodlewsrestformat=json&wsfunction=$functionName&userid=$userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final allCourses = jsonDecode(response.body);
        for (var course in allCourses) {
          String courseIdNumber = course['idnumber'];
          String coursename = course['fullname'];
          List<String> ids = courseIdNumber.split("|");

          if (ids.length >= 6 && semester == ids[4]) {
            courses.add(course);
          }
        }
        return courses;
      } else {
        throw Exception('Failed to get courser by user id');
      }
    }
  }

  Future<List<dynamic>?> getUserEvents(String token, String semester) async {
    var courses = await getUserCourses(token, semester);
    if (courses != null) {
      const functionName = 'core_calendar_get_action_events_by_course';
      var events = [];
      for (var course in courses) {
        var courseId = course['id'];
        final url = Uri.parse(
            '$moodleUrl?wstoken=$token&moodlewsrestformat=json&wsfunction=$functionName&courseid=$courseId');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final courseEvents = jsonDecode(response.body);
          if (courseEvents != null) {
            for (var event in courseEvents['events']) {
              events.add(event);
            }
          }
        } else {
          throw Exception('Failed to get events');
        }
      }
      return cleanEvents(events);
    }
  }

  Future<List<dynamic>?> getUserEventsByCourse(String token, String courseCode,
      String classCode, String semester) async {
    var courses = await getUserCourses(token, semester);

    if (courses != null) {
      const functionName = 'core_calendar_get_action_events_by_course';
      for (var course in courses) {
        String courseIdNumber = course['idnumber'];
        String courseId = course['id'];

        List<String> ids = courseIdNumber.split("|");

        if (ids.length >= 6) {
          if (semester == ids[4] &&
              courseCode == ids[5] &&
              classCode == ids[6]) {
            final url = Uri.parse(
                '$moodleUrl?wstoken=$token&moodlewsrestformat=json&wsfunction=$functionName&courseId=$courseId');
            final response = await http.get(url);
            if (response.statusCode == 200) {
              final courseEvents = jsonDecode(response.body);
              return courseEvents;
            } else {
              throw Exception('Failed to get events by course');
            }
          }
        }
      }
    }
  }

  List<dynamic> cleanEvents(List<dynamic> events) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var filtered = events.where((event) => event["timestart"] > now).toList();

    filtered.sort((a, b) => a["timestart"].compareTo(b["timestart"]));

    var clean_events = [];
    for (var event in filtered) {
      event['name'] =
          event["name"].replaceAll("está marcado(a) para esta data", "").trim();

      if (event['timestart'] != null) {
        DateTime dateTime =
            DateTime.fromMillisecondsSinceEpoch(event['timestart'] * 1000);
        event['datetime_formatted'] =
            DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      }

      clean_events.add(event);
    }

    return clean_events;
  }

  Future<List<dynamic>?> getCourseGrade(String token, String courseCode,
      String classCode, String semester) async {
    var userId = await getUserId(token);
    if (userId != null) {
      var courses = [];
      const coursesFunctionName = 'core_enrol_get_users_courses';
      final coursesUrl = Uri.parse(
          '$moodleUrl?wstoken=$token&moodlewsrestformat=json&wsfunction=$coursesFunctionName&userid=$userId');
      final response = await http.get(coursesUrl);
      if (response.statusCode == 200) {
        final allCourses = jsonDecode(response.body);
        for (var course in allCourses) {
          int courseId = course['id'];
          String courseIdNumber = course['idnumber'];
          String coursename = course['fullname'];

          var ids = courseIdNumber.split("|");

          if (ids.length >= 6 &&
              semester.trim() == ids[4].trim() &&
              courseCode.trim() == ids[5].trim() &&
              classCode.trim() == ids[6].trim()) {
            const gradeFuncName = 'gradereport_user_get_grades_table';
            final gradeUrl = Uri.parse(
                '$moodleUrl?wstoken=$token&moodlewsrestformat=json&wsfunction=$gradeFuncName&courseid=$courseId&userid=$userId');
            final response = await http.get(gradeUrl);

            if (response.statusCode == 200) {
              return cleanGradeTables(jsonDecode(response.body));
            } else {
              throw Exception('Failed to get grade table');
            }
          }
        }
      }
    }
  }

  List<dynamic> cleanGradeTables(dynamic data) {
    var tables = [];
    if (data['tables'] != null) {
      for (var table in data['tables']) {
        if (table['tabledata'] != null) {
          for (var data in table['tabledata']) {
            var clean_data = {};

            if (data is List) {
              continue;
            }

            if (data['itemname'] != null) {
              RegExp regexName = RegExp(r'\/>(.*?)<\/(?:a|span)>');
              var matchName = regexName.firstMatch(data['itemname']['content']);

              if (matchName != null) {
                clean_data['name'] = matchName.group(1);
              }

              RegExp regexCategory = RegExp(r'category(\d+)');
              var matchCategory =
                  regexCategory.firstMatch(data['itemname']['class']);

              if (matchCategory != null) {
                String? numberString = matchCategory.group(1);
                clean_data['level'] = int.parse(numberString!);
              }
            }

            if (data['grade'] != null) {
              clean_data['grade'] = data['grade']['content'];
            }

            if (data['weight'] != null) {
              clean_data['weight'] = data['weight']['content'];
            }

            if (data['contributiontocoursetotal'] != null) {
              clean_data['contribution'] =
                  data['contributiontocoursetotal']['content'];
            }

            if (clean_data.isNotEmpty) {
              tables.add(clean_data);
            }
          }
        }
      }
    }

    return tables;
  }
}
