import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Webview extends StatefulWidget {
  final void Function(InAppWebViewController controller)? onWebViewCreated;
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
  _WebviewState createState() => _WebviewState();
}

class _WebviewState extends State<Webview> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      key: widget.key,
      initialData: InAppWebViewInitialData(
        data: widget.data,
        baseUrl: WebUri.uri(Uri.https('www.youtube.com')),
        encoding: 'utf-8',
        mimeType: 'text/html',
      ),
      initialSettings: InAppWebViewSettings(
        userAgent: widget.userAgent,
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
        useHybridComposition: widget.useHybridComposition,
      ),
      onWebViewCreated: widget.onWebViewCreated,
      onLoadStop: (_, __) {
        widget.onLoaded();
      },
    );
  }
}
