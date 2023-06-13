import 'package:flutter/material.dart';
import 'package:gradufsc/functions/cagr.dart';
import 'package:uni_links/uni_links.dart';

class AuthCAGRPage extends StatefulWidget {
  const AuthCAGRPage({super.key});

  @override
  State<AuthCAGRPage> createState() => _AuthCAGRPageState();
}

class _AuthCAGRPageState extends State<AuthCAGRPage> {
  CagrAuth cagrAuth = CagrAuth();
  bool authenticating = false;

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    // Verifica se o aplicativo foi aberto através de um link personalizado
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      handleLink(initialLink);
    }

    linkStream.listen((link) {
      handleLink(link);
    });
  }

  void handleLink(String? link) async {
    setState(() {
      authenticating = true;
    });

    if (link != null) {
      final uri = Uri.parse(link);
      String? code = uri.queryParameters['code'];
      if (code != null) {
        bool authenticated = await cagrAuth.updateData(authCode: code);
        if (authenticated) {
          Navigator.pushReplacementNamed(
            context,
            '/moodle-token',
            arguments: {'moodleTokenNavigate': true},
          );
        } else {
          setState(() {
            authenticating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Autenticação com CAGR'),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Primeiro passo:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(height: 16), // Espaçamento entre os títulos
                    Text(
                      'Para obter as informações sobre sua grade de horários é necessário realizar a autenticação com o CAGR.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  child: authenticating
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : Text('Autenticar'),
                  onPressed: () async {
                    setState(() {
                      authenticating = true;
                    });
                    bool authenticated = false;

                    try {
                      authenticated = await cagrAuth.updateData();
                    } on Exception {
                      authenticated = false;
                    }

                    setState(() {
                      authenticating = false;
                    });

                    if (authenticated) {
                      Navigator.pushReplacementNamed(
                        context,
                        '/moodle-token',
                        arguments: {'moodleTokenNavigate': true},
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Erro ao autenticar, tente novamente mais tarde.'),
                      ));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
