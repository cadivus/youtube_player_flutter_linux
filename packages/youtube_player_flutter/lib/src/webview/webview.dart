import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_cef/webview_cef.dart';
import 'dart:io' show Platform;

import 'package:youtube_player_flutter/src/webview/webview_controller.dart';

class Webview extends StatelessWidget {
  final void Function(WebviewController controller) onWebViewCreated;
  final VoidCallback onLoaded;
  final String data;
  final String userAgent;
  final bool useHybridComposition;

  const Webview({
    Key? key,
    required this.data,
    required this.onLoaded,
    required this.onWebViewCreated,
    required this.userAgent,
    required this.useHybridComposition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isLinux) {
      return _LinuxWebview(
        data: data,
        onLoaded: onLoaded,
        onWebViewCreated: onWebViewCreated,
        userAgent: userAgent,
        useHybridComposition: useHybridComposition,
      );
    }

    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: data,
        baseUrl: WebUri.uri(Uri.https('www.youtube.com')),
        encoding: 'utf-8',
        mimeType: 'text/html',
      ),
      initialSettings: InAppWebViewSettings(
        userAgent: userAgent,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: true,
        disableContextMenu: true,
        supportZoom: false,
        disableHorizontalScroll: false,
        disableVerticalScroll: false,
        allowsInlineMediaPlayback: true,
        allowsAirPlayForMediaPlayback: true,
        allowsPictureInPictureMediaPlayback: true,
        useWideViewPort: false,
        useHybridComposition: useHybridComposition,
      ),
      onWebViewCreated: (inAppViewController) {
        onWebViewCreated(
          WebviewController(inAppWebViewController: inAppViewController),
        );
      },
      onLoadStop: (_, __) {
        onLoaded();
      },
    );
  }
}

class _LinuxWebview extends StatefulWidget {
  final void Function(WebviewController controller) onWebViewCreated;
  final VoidCallback onLoaded;
  final String data;
  final String userAgent;
  final bool useHybridComposition;

  const _LinuxWebview({
    Key? key,
    required this.data,
    required this.onLoaded,
    required this.userAgent,
    required this.onWebViewCreated,
    this.useHybridComposition = false,
  }) : super(key: key);

  @override
  _LinuxWebviewState createState() => _LinuxWebviewState();
}

class _LinuxWebviewState extends State<_LinuxWebview> {
  InAppWebViewController? webViewController;
  late WebViewController _controller;

  void initState() {
    _controller = WebviewManager().createWebView(
      loading: const Text("not initialized"),
    );
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await WebviewManager().initialize(userAgent: widget.userAgent);
    _controller.setWebviewListener(WebviewEventsListener(
      onUrlChanged: (_) {
        widget.onLoaded();
      },
    ));

    await _controller.initialize("about:blank");

    await _controller.executeJavaScript(
      "document.open(); document.write(\"" +
          widget.data.replaceAll('"', r'\"').replaceAll('\n', r'\n') +
          "\"); document.close();",
    );

    widget.onWebViewCreated(
      WebviewController(webViewController: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, child) {
        return _controller.value
            ? _controller.webviewWidget
            : _controller.loadingWidget;
      },
    );
  }
}
