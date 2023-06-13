import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gradufsc/constants.dart';
import 'package:gradufsc/functions/cagr.dart';
import 'package:gradufsc/screens/calendar.dart';
import 'package:gradufsc/screens/courses.dart';
import 'package:gradufsc/screens/home.dart';
import 'package:gradufsc/screens/restaurant.dart';
import 'package:gradufsc/screens/settings.dart';
import 'package:url_launcher/url_launcher.dart';

class InitialScreen extends StatefulWidget {
  final bool moodleTokenNavigate;

  const InitialScreen({super.key, this.moodleTokenNavigate = false});

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  CagrAuth cagrAuth = CagrAuth();
  bool cagrHasData = false;
  Timer? _timer = null;

  // @override
  // void initState() {
  //   super.initState();
  //   checkAuthentication();
  // }

  // Future<void> checkAuthentication() async {
  //   if (auth.currentUser == null) {
  //     // O usuário está autenticado
  //     Navigator.pushReplacementNamed(context, '/sign-in');
  //   }
  // }

  Timer startFeedbackTimer() {
    return Timer(Duration(seconds: 45), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Feedback'),
            content: Text(
                'Sua opinião é importante para tornar o aplicativo ainda melhor! Ajude respondendo a algumas perguntas rápidas sobre sua experiência.'),
            actions: <Widget>[
              TextButton(
                child: Text('Depois'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Responder'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .update({'feedback_answered': true});
                  var uri = Uri.parse('https://forms.gle/tjdetkWGhT9HqeUB7');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          );
        },
      );
    });
  }

  @override
  void initState() {
    super.initState();

    try {
      Stream<DocumentSnapshot> snapshot = FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots();

      snapshot.listen((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          var data = documentSnapshot.data() as Map<String, dynamic>?;
          setState(() {
            cagrHasData = true;
          });
          if (widget.moodleTokenNavigate && data?['moodle_token'] == null) {
            Navigator.pushNamed(
              context,
              '/moodle-token',
            );
          } else if (!data?['feedback_answered']) {
            if (_timer == null) {
              setState(() {
                _timer = startFeedbackTimer();
              });
            }
          }
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/cagr-auth',
            (route) => false,
          );
        }
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/cagr-auth',
          (route) => false,
        );
      } else {}
    }
  }

  int _selectedIndex = 0;
  final List<Widget> _pages = <Widget>[
    HomeScreen(),
    CoursesScreen(),
    CalendarScreen(),
    RestaurantScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return !cagrHasData
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: primaryColor,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  backgroundColor: primaryColor,
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  backgroundColor: primaryColor,
                  icon: Icon(Icons.list),
                  label: 'Disciplinas',
                ),
                BottomNavigationBarItem(
                  backgroundColor: primaryColor,
                  icon: Icon(Icons.calendar_today),
                  label: 'Eventos',
                ),
                BottomNavigationBarItem(
                  backgroundColor: primaryColor,
                  icon: Icon(Icons.restaurant),
                  label: 'Restaurante',
                ),
                BottomNavigationBarItem(
                  backgroundColor: primaryColor,
                  icon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          );
  }
}
