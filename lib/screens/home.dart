import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gradufsc/constants.dart';
import 'package:gradufsc/functions/cagr.dart';
import 'package:gradufsc/functions/utils.dart';
import 'package:gradufsc/screens/timetable.dart';
import 'package:gradufsc/widgets/title.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';

import 'courses.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CagrAuth cagrAuth = CagrAuth();
  Future<List<dynamic>> getNews() async {
    final response =
        await http.get(Uri.parse('https://noticias.ufsc.br/feed/'));
    final body = response.body;
    final document = XmlDocument.parse(body);

    final items = document.findAllElements('item');

    List<dynamic> news = [];

    final DateFormat inputFormat = DateFormat('E, d MMM y H:m:s Z');
    final DateFormat outputFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (var item in items) {
      final description = item.getElement('description')?.text ?? '';
      final contentEncoded = item.getElement('content:encoded')?.text ?? '';

      final RegExp regex = RegExp(r'<img[^>]+src="([^">]+)"');
      final match = regex.firstMatch(contentEncoded);
      final imageUrl = match?.group(1) ?? '';

      String? pubDate = item.getElement('pubDate')?.text.replaceAll('"', '\\"');
      if (pubDate != null) {
        pubDate = outputFormat
            .format(inputFormat.parse(pubDate).subtract(Duration(hours: 3)));
      }

      news.add({
        'title': item.getElement('title')?.text.replaceAll('"', '\\"') ?? '',
        'link': item.getElement('link')?.text.replaceAll('"', '\\"') ?? '',
        'pub_date': pubDate,
        'description': description.replaceAll('"', '\\"'),
        'image_url': imageUrl
      });
    }

    return news;
  }

  Stream<DocumentSnapshot> getUserData() {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      // return FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(user.uid)
      //     .snapshots()
      //     .asyncMap((snapshot) {
      //   if (snapshot.exists) {
      //     return Future.value(snapshot);
      //   } else {
      //     return cagrAuth.updateData().then((updated) {
      //       if (updated) {
      //         setState(() {});
      //       } else {
      //         final snackBar = SnackBar(
      //           content: Text(
      //               'Não foi possível obter os dados do CAGR. Tente novamente mais tarde.'),
      //         );
      //         ScaffoldMessenger.of(context).showSnackBar(snackBar);
      //         return null;
      //       }
      //     });
      //   }
      // });
    } else {
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Builder(
            builder: (context) => // Ensure Scaffold is in context
                IconButton(
                    icon: Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openEndDrawer()),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              child: Text(
                'Links Úteis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Atestado de Matrícula'),
              onTap: () async {
                var uri = Uri.parse(
                    'https://cagr.sistemas.ufsc.br/relatorios/aluno/atestadoMatricula?download');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Não foi possível acessar';
                }
              },
            ),
            ListTile(
              title: Text('Currículo do Curso'),
              onTap: () async {
                var uri = Uri.parse(
                    'https://cagr.sistemas.ufsc.br/relatorios/aluno/curriculoCurso?download');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Não foi possível acessar';
                }
              },
            ),
            ListTile(
              title: Text('Controle Curricular'),
              onTap: () async {
                var uri = Uri.parse(
                    'https://cagr.sistemas.ufsc.br/relatorios/aluno/controleCurricular?download');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Não foi possível acessar';
                }
              },
            ),
            ListTile(
              title: Text('Moodle'),
              onTap: () async {
                var uri = Uri.parse('https://moodle.ufsc.br/my/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Não foi possível acessar';
                }
              },
            ),
            ListTile(
              title: Text('Biblioteca'),
              onTap: () async {
                var uri = Uri.parse('https://pergamum.ufsc.br/meupergamum');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Não foi possível acessar';
                }
              },
            ),
            ListTile(
              title: Text('Classificados'),
              onTap: () async {
                var uri = Uri.parse('https://classificados.inf.ufsc.br/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Não foi possível acessar';
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          title('Próximas aulas'),
          StreamBuilder<DocumentSnapshot>(
            stream: getUserData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                DocumentSnapshot userSnapshot = snapshot.data!;
                Map<String, dynamic>? userData =
                    userSnapshot.data() as Map<String, dynamic>?;

                List<dynamic> fullSchedule = [];

                if (userData != null && userData.containsKey('schedule')) {
                  List<dynamic> scheduleList =
                      userData['schedule'] as List<dynamic>;

                  for (var sch in scheduleList) {
                    Map<String, dynamic>? courseData = userData['courses']
                        .firstWhere(
                            (course) => course['code'] == sch['course_code'],
                            orElse: () => null);

                    if (courseData != null) {
                      sch['course_name'] = courseData['name'];
                      sch['semester'] = courseData['semester'];
                      sch['moodle_token'] = userData['moodle_token'];
                    }
                  }

                  scheduleList.sort((a, b) {
                    if (a['week_day'] != b['week_day']) {
                      return a['week_day'] - b['week_day'];
                    } else {
                      return a['time'] - b['time'];
                    }
                  });

                  DateTime now = DateTime.now();
                  int index = scheduleList.indexWhere((event) {
                    int eventWeekDay = event['week_day'];
                    int eventTime = event['time'];
                    if (eventWeekDay > now.weekday + 1 ||
                        (eventWeekDay == now.weekday + 1 &&
                            eventTime > now.hour * 100)) {
                      return true;
                    }
                    return false;
                  });

                  List nextClasses = [];
                  if (index >= 0) {
                    var stopIndex = index + 3 > scheduleList.length - 1
                        ? scheduleList.length - 1
                        : index + 3;
                    nextClasses.addAll(scheduleList.getRange(index, stopIndex));
                  }

                  if (nextClasses.length < 3) {
                    nextClasses.addAll(
                        scheduleList.getRange(0, 3 - nextClasses.length));
                  }

                  return SingleChildScrollView(
                    child: Column(children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            if (nextClasses.isNotEmpty)
                              Column(
                                children: nextClasses.map((classData) {
                                  String courseCode = classData['course_code'];
                                  String locationCenter =
                                      classData['location_center'];
                                  String locationRoom =
                                      classData['location_room'];
                                  int time = classData['time'];
                                  String classCode = classData['class_code'];
                                  String courseName = classData['course_name'];
                                  String semester = classData['semester'];

                                  String formattedTime =
                                      '${(time ~/ 100).toString().padLeft(2, '0')}:${(time % 100).toString().padLeft(2, '0')}';

                                  String weekDay =
                                      getWeekday(classData['week_day']);

                                  List<dynamic> schedule = [];
                                  if (userData['schedule'] != null) {
                                    for (var sch in userData['schedule']) {
                                      if (sch['course_code'] == courseCode) {
                                        schedule.add(sch);
                                      }
                                    }
                                  }

                                  String? moodleToken =
                                      userData['moodle_token'];

                                  return Card(
                                    elevation: 2,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CourseDetail(
                                              schedule: schedule,
                                              courseCode: courseCode,
                                              courseName: courseName,
                                              semester: semester,
                                              classCode: classCode,
                                              moodleToken: moodleToken,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ListTile(
                                          title:
                                              Text('$courseCode - $courseName'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Local: $locationCenter - $locationRoom'),
                                              Text('Turma: $classCode'),
                                              Text(
                                                  '$weekDay às $formattedTime'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (nextClasses.isEmpty)
                              Text('Nenhuma aula encontrada'),
                          ],
                        ),
                      ),
                      if (nextClasses.isNotEmpty)
                        TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TimeTableWidget(
                                      schedule: userData['schedule']),
                                ),
                              );
                            },
                            child: Text('Ver tudo')),
                    ]),
                  );
                } else if (userData == null) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/cagr-auth',
                    (route) => false,
                  );
                  // cagrAuth.updateData().then((updated) {
                  //   if (updated) {
                  //     // Atualizar a página
                  //     setState(() {});
                  //   } else {
                  //     final snackBar = SnackBar(
                  //       content: Text(
                  //           'Não foi possível obter os dados do CAGR. Tente novamente mais tarde.'),
                  //     );
                  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  //   }
                  // });
                }
                return Text('Nenhuma aula encontrada');
              } else if (snapshot.hasError) {
                return Text('Erro ao carregar as aulas');
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          title('Notícias'),
          FutureBuilder<List<dynamic>>(
            future: getNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  final allnews = snapshot.data!;

                  return Container(
                    child: Column(
                      children: allnews.map((news) {
                        return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(
                                  news?['title'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.w400),
                                ),
                                subtitle: Text(
                                  news?['pub_date'] ?? '',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 10,
                                  ),
                                ),
                                leading: news['image_url'].isNotEmpty
                                    ? Container(
                                        width: 50,
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Image.network(
                                            news['image_url'],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : null,
                                onTap: () async {
                                  if (news['link'] != '') {
                                    Uri url = Uri.parse(news['link']);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url,
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      throw 'Não foi possível acessar';
                                    }
                                  }
                                  ;
                                },
                              ),
                            ));
                      }).toList(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Erro ao carregar as notícias');
                } else {
                  return Text('Nenhuma notícia encontrada');
                }
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      )),
    );
  }
}
