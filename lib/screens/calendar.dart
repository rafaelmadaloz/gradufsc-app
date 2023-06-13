import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../functions/moodle.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic>? _events;
  bool _loading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          return data;
        }
      }
    } catch (e) {}

    return null;
  }

  Future<void> _fetchEvents() async {
    Map<String, dynamic>? userData = await getUserData();

    if (userData?['moodle_token'] != null) {
      if (userData?['info']['semester'] != null) {
        List<dynamic>? events = await MoodleHelper().getUserEvents(
            userData?['moodle_token'], userData?['info']['semester']);
        setState(() {
          _events = events;
          _loading = false;
        });
      }
    } else {
      showTokenRequiredDialog(_scaffoldKey.currentContext!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Próximos Eventos'),
      ),
      body: _events != null
          ? Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                itemCount: _events!.length,
                itemBuilder: (context, index) {
                  var event = _events![index];

                  return EventCard(
                    event: event,
                    onTap: () {},
                  );
                },
              ),
            )
          : Center(
              child: _loading
                  ? CircularProgressIndicator()
                  : Text('Nenhum evento'),
            ),
    );
  }
}

class EventCard extends StatelessWidget {
  final dynamic event;
  final VoidCallback onTap;

  const EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              // Text(
              //   event['description'],
              //   style: TextStyle(
              //     fontSize: 14,
              //   ),
              // ),
              // SizedBox(height: 8),
              Text(
                event['course']['fullname'],
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Data: ${event['datetime_formatted']}',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showTokenRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Chave do Moodle não encontrada'),
        content: Text(
            'Você precisa cadastrar uma chave do Moodle na seção Ajustes para acessar os eventos.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
