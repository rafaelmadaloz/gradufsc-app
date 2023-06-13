import 'package:flutter/material.dart';
import 'package:gradufsc/functions/utils.dart';
import 'package:gradufsc/widgets/title.dart';

import 'courses.dart';

class TimeTableWidget extends StatelessWidget {
  final List<dynamic> schedule;

  TimeTableWidget({required this.schedule});

  @override
  Widget build(BuildContext context) {
    Map<int, List<Map<String, dynamic>>> groupedSchedule = {};
    for (var item in schedule) {
      int weekDay = item['week_day'];
      if (!groupedSchedule.containsKey(weekDay)) {
        groupedSchedule[weekDay] = [];
      }
      groupedSchedule[weekDay]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Grade de Horários'),
      ),
      body: ListView.builder(
        itemCount: groupedSchedule.length,
        itemBuilder: (context, index) {
          int weekDay = groupedSchedule.keys.elementAt(index);
          List<Map<String, dynamic>> daySchedule = groupedSchedule[weekDay]!;

          String dayName = _getDayName(weekDay);

          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(dayName),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: daySchedule.length,
                  itemBuilder: (context, index) {
                    var item = daySchedule[index];
                    var timeformatted = getFormattedTime(item['time']);

                    var _courseSchedule = [];

                    for (var sch in schedule) {
                      if (sch['course_code'] == item['course_code']) {
                        _courseSchedule.add(sch);
                      }
                    }
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetail(
                              schedule: _courseSchedule,
                              courseCode: item['course_code'],
                              courseName: item['course_name'],
                              semester: item['semester'],
                              classCode: item['class_code'],
                              moodleToken: item['moodle_token'],
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(
                                  "${item['course_code']} - ${item['course_name']}"),
                              subtitle: Text(
                                'Local: ${item['location_center']}-${item['location_room']}',
                              ),
                              trailing: Text(
                                timeformatted,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDayName(int weekDay) {
    switch (weekDay) {
      case 1:
        return 'Domingo';
      case 2:
        return 'Segunda-feira';
      case 3:
        return 'Terça-feira';
      case 4:
        return 'Quarta-feira';
      case 5:
        return 'Quinta-feira';
      case 6:
        return 'Sexta-feira';
      case 7:
        return 'Sábado';
      default:
        return '';
    }
  }
}
