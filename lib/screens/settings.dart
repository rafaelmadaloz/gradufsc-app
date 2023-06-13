import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gradufsc/functions/cagr.dart';
import 'package:gradufsc/functions/notifications.dart';
import 'package:gradufsc/screens/login.dart';
import 'package:gradufsc/screens/moodle_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseStore = FirebaseFirestore.instance;
  // .collection('users')
  // .doc(_firebaseAuth.currentUser?.uid)
  // .update({'notifications_off': !value});

  late TextEditingController _tokenController;
  String campus = 'trindade';
  bool notificationsOff = false;
  final cagrAuth = CagrAuth();
  Map<String, dynamic>? userInfo;
  Map<String, dynamic>? userData;
  bool _isEditingToken = false;
  bool isLoadingCagr = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: '');
    updateUserInfo();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _editToken() {
    setState(() {});
  }

  void _saveToken() {
    setState(() {});
  }

  void updateUserInfo() async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_firebaseAuth.currentUser?.uid);

    DocumentSnapshot snapshot = await userDocRef.get();

    if (snapshot.exists) {
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          userData = data;
          if (data.containsKey('info')) {
            userInfo = data['info'];
          }

          if (data.containsKey('moodle_token')) {
            _tokenController.text = data['moodle_token'];
          }

          if (data.containsKey('campus')) {
            campus = data['campus'];
          }

          if (data.containsKey('notifications_off')) {
            notificationsOff = data['notifications_off'];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        automaticallyImplyLeading: false,
        actions: [
          Row(
            children: [
              IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/sign-in',
                      (Route<dynamic> route) =>
                          false, // impede que o usuário volte para a tela anterior
                    );
                  },
                  icon: const Icon(Icons.logout)),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 10),
              if (userInfo != null)
                Column(
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Aluno'),
                        ),
                        Text(userInfo?['name'])
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Curso'),
                        ),
                        Text(userInfo?['course_name'])
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Semestre atual'),
                        ),
                        Text(userInfo?['semester'])
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    )
                  ],
                ),
              Text(
                _firebaseAuth.currentUser!.email!,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Como obter?'),
                          content: Text.rich(
                            TextSpan(
                              text:
                                  'Acesse o menu preferências da sua conta do Moodle ',
                              children: [
                                TextSpan(
                                  text: 'clicando aqui',
                                  // ,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      var uri = Uri.parse(
                                          'https://moodle.ufsc.br/user/preferences.php');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    },
                                ),
                                TextSpan(text: '.\n\n'),
                                TextSpan(
                                  text: 'Acesse a opção ',
                                ),
                                TextSpan(
                                  text: 'chaves de segurança',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '.\n\n'),
                                TextSpan(
                                  text: 'Copie a chave do serviço ',
                                ),
                                TextSpan(
                                  text: 'Moodle mobile web service',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Fechar'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'Como obter?',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextFormField(
                    controller: _tokenController,
                    enabled: _isEditingToken,
                    decoration: InputDecoration(
                        labelText: 'Chave do Moodle',
                        hintText: 'Moodle mobile web service',
                        prefixIcon: Icon(Icons.key),
                        suffixIcon: _isEditingToken
                            ? IconButton(
                                icon: Icon(
                                    _isEditingToken ? Icons.save : Icons.edit),
                                onPressed: () {
                                  setState(() {
                                    _isEditingToken = !_isEditingToken;
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_firebaseAuth.currentUser?.uid)
                                        .update({
                                      'moodle_token': _tokenController.text
                                    });
                                  });
                                },
                              )
                            : null),
                  ),
                  if (!_isEditingToken)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditingToken = !_isEditingToken;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.edit),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Notificações'),
                  ),
                  Switch(
                    value: !notificationsOff,
                    onChanged: (value) {
                      if (mounted) {
                        setState(() {
                          notificationsOff = !value;
                          _firebaseStore
                              .collection('users')
                              .doc(_firebaseAuth.currentUser?.uid)
                              .update({'notifications_off': !value});
                        });
                      }
                      NotificationHelper nfhelper = NotificationHelper();
                      if (notificationsOff) {
                        nfhelper.cancelAllNotifications();
                      } else {
                        nfhelper.scheduleUserGrade(userData!);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Campus do Restaurante'),
                  ),
                  DropdownButton<String>(
                    value: campus,
                    onChanged: (value) {
                      setState(() {
                        campus = value!;
                      });
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_firebaseAuth.currentUser?.uid)
                          .update({'campus': value});
                    },
                    items: campusOptions.entries.map((entry) {
                      final value = entry.key;
                      final label = entry.value;
                      return DropdownMenuItem(
                        value: value,
                        child: Text(label),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    isLoadingCagr = true;
                  });
                  String text;
                  await cagrAuth.updateData().then((updated) => {
                        if (updated)
                          {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Os dados foram atualizados com sucesso.'),
                            ))
                          }
                        else
                          {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Erro ao atualizar, tente novamente mais tarde.'),
                            ))
                          }
                      });
                  setState(() {
                    isLoadingCagr = false;
                  });
                },
                icon: isLoadingCagr
                    ? CircularProgressIndicator()
                    : Icon(Icons.refresh),
                label: Text('Atualizar disciplinas/semestre (CAGR)'),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
