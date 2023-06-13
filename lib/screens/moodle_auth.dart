import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MoodleAuthPage extends StatefulWidget {
  const MoodleAuthPage({super.key});

  @override
  State<MoodleAuthPage> createState() => _MoodleAuthPageState();
}

class _MoodleAuthPageState extends State<MoodleAuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body is the majority of the screen.
      body: Center(
        child: OutlinedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/moodle-login');
          },
          child: Text('Autenticar com o Moodle'),
        ),
      ),
    );
  }
}

class MoodleAuthHelper {
  static Future<String?> getAuthCode() async {
    Uri url = Uri.parse(
        "https://sistemas.ufsc.br/login?service=https://moodle.ufsc.br/login/index.php");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }

    final urlBack = await linkStream.first;

    if (urlBack != null) {
      return Uri.parse(urlBack).queryParameters['code'];
    }

    return null;
  }
}

class MoodleLoginScreen extends StatefulWidget {
  const MoodleLoginScreen({super.key});

  @override
  State<MoodleLoginScreen> createState() => _MoodleLoginScreenState();
}

class _MoodleLoginScreenState extends State<MoodleLoginScreen> {
  final _authUrl =
      'https://sistemas.ufsc.br/login?service=https://moodle.ufsc.br/login/index.php';
  final _redirectUrl = 'https://moodle.ufsc.br/login/index.php';
  final String _passport = '803.7381226657849';
  final String _tokenUrl =
      'https://moodle.ufsc.br/admin/tool/mobile/launch.php?service=moodle_mobile_app';
  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('moodlemobile')) {
              String url_a = request.url;
              String? token = Uri.parse(request.url).queryParameters['token'];
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith(_redirectUrl)) {
              // Extrai o token da URL de redirecionamento
              String? ticket = Uri.parse(request.url).queryParameters['ticket'];
              if (ticket != null) {
                _webViewController
                    .loadRequest(Uri.parse('$_tokenUrl&passport=$_passport'));
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_authUrl));

    return Scaffold(
      appBar: AppBar(
        title: Text('Login Moodle UFSC'),
      ),
      body: WebViewWidget(
        controller: _webViewController,
      ),
    );
  }
}
