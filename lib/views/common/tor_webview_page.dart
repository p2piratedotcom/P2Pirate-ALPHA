import 'package:flutter/material.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:webview_all/webview_all.dart' as webview;

class TorWebViewPage extends StatefulWidget {
  const TorWebViewPage({
    required this.url,
    required this.title,
    this.onConsoleMessage,
    super.key,
  });

  final Uri url;
  final String title;
  final void Function(String)? onConsoleMessage;

  @override
  State<TorWebViewPage> createState() => _TorWebViewPageState();
}

class _TorWebViewPageState extends State<TorWebViewPage> {
  late final webview.WebViewController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = webview.WebViewController();
    _load();
  }

  Future<void> _load() async {
    try {
      await _controller.setJavaScriptMode(webview.JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        webview.NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            return uri != null &&
                    (uri.scheme == 'https' || uri.scheme == 'http')
                ? webview.NavigationDecision.navigate
                : webview.NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame != false) {
              setState(() => _error = error.description);
            }
          },
        ),
      );
      if (widget.onConsoleMessage != null) {
        await _controller.setOnConsoleMessage(
          (message) => widget.onConsoleMessage!(message.message),
        );
      }
      await _controller.loadRequest(widget.url);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: _error == null
            ? ScreenshotSensitive(
                child: webview.WebViewWidget(controller: _controller),
              )
            : Center(child: Text('Page unavailable: $_error')),
      ),
    );
  }
}
