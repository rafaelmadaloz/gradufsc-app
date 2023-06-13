import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gradufsc/functions/utils.dart';
import 'package:gradufsc/widgets/title.dart';

import '../functions/moodle.dart';

class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disciplinas'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            DocumentSnapshot userSnapshot = snapshot.data!;
            Map<String, dynamic>? userData =
                userSnapshot.data() as Map<String, dynamic>?;

            if (userData != null && userData.containsKey('courses')) {
              List<dynamic> coursesList = userData['courses'] as List<dynamic>;

              return ListView.builder(
                itemCount: coursesList.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> courseData =
                      coursesList[index] as Map<String, dynamic>;
                  String code = courseData['code'];
                  String name = courseData['name'];
                  String classCode = courseData['class'];
                  List<String> professors =
                      List<String>.from(courseData['professors']);

                  List<dynamic> schedule = [];
                  if (userData['schedule'] != null) {
                    for (var sch in userData['schedule']) {
                      if (sch['course_code'] == code) {
                        schedule.add(sch);
                      }
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetail(
                            schedule: schedule,
                            courseCode: code,
                            courseName: name,
                            semester: courseData['semester'],
                            classCode: classCode,
                            moodleToken: userData['moodle_token'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              code + " - " + name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Turma: " + classCode,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 8),
                            Text(
                              professors.join(', '),
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return Text('Nenhuma disciplina encontrada');
            }
          } else if (snapshot.hasError) {
            return Text('Erro ao carregar as disciplinas');
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class CourseDetail extends StatefulWidget {
  final List<dynamic>? schedule;
  final String courseCode;
  final String courseName;
  final String classCode;
  final String semester;
  final String? moodleToken;

  CourseDetail(
      {required this.schedule,
      required this.courseCode,
      required this.courseName,
      required this.classCode,
      required this.semester,
      this.moodleToken});

  @override
  State<CourseDetail> createState() => _CourseDetailState();
}

class _CourseDetailState extends State<CourseDetail> {
  List<dynamic>? _grades;
  bool _loadingGrades = false;
  MoodleHelper moodleHelper = MoodleHelper();

  Future<void> _fetchGrade() async {
    setState(() {
      _loadingGrades = true;
    });

    if (widget.moodleToken != null) {
      List<dynamic>? grades = await moodleHelper.getCourseGrade(
          widget.moodleToken!,
          widget.courseCode,
          widget.classCode,
          widget.semester);
      setState(() {
        _loadingGrades = false;
        _grades = grades;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchGrade();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.schedule != null && widget.schedule!.isNotEmpty)
              title('Horários'),
            if (widget.schedule != null && widget.schedule!.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.schedule!.length,
                  itemBuilder: (context, index) {
                    var schedule = widget.schedule![index];
                    var weekDay = getWeekday(schedule['week_day']);
                    var center = schedule['location_center'];
                    var room = schedule['location_room'];
                    var time = getFormattedTime(schedule['time']);
                    return Card(
                      child: ListTile(
                        title: Text('$weekDay às $time'),
                        subtitle: Text('Centro $center | Sala $room'),
                      ),
                    );
                  },
                ),
              ),
            title('Notas'),
            if (_loadingGrades)
              Center(
                child: CircularProgressIndicator(),
              ),
            if (_grades != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _grades!.length,
                  itemBuilder: (context, index) {
                    var event = _grades![index];

                    return GradeCard(event: event);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GradeCard extends StatelessWidget {
  final dynamic event;

  const GradeCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                event['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              event['grade'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
