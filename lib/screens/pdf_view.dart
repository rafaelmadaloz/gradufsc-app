import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfWebView extends StatelessWidget {
  final String pdfUrl;

  const PdfWebView({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    var controller = WebViewController()
      // ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..setBackgroundColor(const Color(0x00000000))

      ..loadRequest(Uri.parse(pdfUrl));
    return Scaffold(
      body: WebViewWidget(controller: controller),
    );
  }
}
