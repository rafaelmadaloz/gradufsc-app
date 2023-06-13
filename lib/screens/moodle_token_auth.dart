import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gradufsc/functions/moodle.dart';
import 'package:url_launcher/url_launcher.dart';

class MoodleTokenScreen extends StatefulWidget {
  MoodleTokenScreen({super.key});

  @override
  State<MoodleTokenScreen> createState() => _MoodleTokenScreenState();
}

class _MoodleTokenScreenState extends State<MoodleTokenScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  MoodleHelper moodleHelper = MoodleHelper();
  bool savingToken = false;

  String tokenError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chave do Moodle'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Para obter informações das disciplinas é necessário adicionar a chave do Moodle.',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32),
                        Text(
                          'Siga as etapas abaixo:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 32),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            textAlign: TextAlign.left,
                            TextSpan(
                              children: [
                                TextSpan(text: '1 - '),
                                TextSpan(
                                  text: 'Clique aqui',
                                  style: TextStyle(
                                    color: Colors.blue,
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
                                TextSpan(text: ' para acessar a página de '),
                                TextSpan(
                                  text: 'Preferências',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ' da sua conta do Moodle'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              text: '2 - Acesse o item ',
                              children: [
                                TextSpan(
                                    text: 'Chaves de Segurança',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold))
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                                text:
                                    '3 - Copie a chave de 32 dígitos correspondente ao serviço ',
                                children: [
                                  TextSpan(
                                      text: 'Moodle mobile web service',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))
                                ]),
                          ),
                        ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '4 - Cole a chave no campo abaixo',
                          ),
                        ),
                        SizedBox(height: 24),
                        TextField(
                          controller: _textEditingController,
                          decoration: InputDecoration(
                            labelText: 'Chave do Moodle',
                            hintText: 'Moodle mobile web service',
                            errorText: tokenError != '' ? tokenError : null,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Você pode editar a chave posteriormente acessando o menu Ajustes do aplicativo',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(4),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: Text('Depois'),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/initial',
                        (route) => false,
                      );
                    },
                  ),
                  TextButton(
                    child: savingToken
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : Text(
                            'Salvar e continuar',
                          ),
                    onPressed: () async {
                      setState(() {
                        savingToken = true;
                      });
                      String moodleToken = _textEditingController.text.trim();
                      if (moodleToken.isNotEmpty) {
                        var userId = await moodleHelper.getUserId(moodleToken);
                        if (userId == null) {
                          setState(() {
                            savingToken = false;
                            tokenError = 'Chave inválida.';
                          });
                        } else {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser?.uid)
                              .update({
                            'moodle_token': moodleToken,
                            'moodle_user_id': userId,
                          });
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/initial',
                            (route) => false,
                          );
                        }
                      } else {
                        setState(() {
                          savingToken = false;
                          tokenError = 'Chave inválida.';
                        });
                      }
                    },
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}
