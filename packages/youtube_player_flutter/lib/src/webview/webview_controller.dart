import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_cef/webview_cef.dart';

typedef dynamic JavaScriptHandlerCallback(List<dynamic> arguments);

class WebviewController {
  // Private variables
  InAppWebViewController? _inAppWebViewController;
  WebViewController? _webViewController;

  final Set<JavascriptChannel> _jsChannels = {};

  // Constructor to initialize the controller
  WebviewController({
    InAppWebViewController? inAppWebViewController,
    WebViewController? webViewController,
  })  : _inAppWebViewController = inAppWebViewController,
        _webViewController = webViewController;

  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    _inAppWebViewController?.addJavaScriptHandler(
      handlerName: handlerName,
      callback: callback,
    );

    if (_webViewController != null) {
      _jsChannels.add(
        JavascriptChannel(
          name: handlerName,
          onMessageReceived: (JavascriptMessage message) {
            String messageText = "{\"message\":${message.message}}" ;
            messageText = jsonDecode(messageText)["message"];

            List<dynamic> arguments = [];

            if (messageText.trim().startsWith("[")) {
              // A list
              try {
                arguments = jsonDecode(messageText);
              } catch (e) {
                // Error, treat as single object
                arguments = <dynamic>[messageText];
              }
            } else if (messageText.trim().startsWith("{")) {
              // A map, pack as List
              try {
                arguments = [jsonDecode(messageText)];
              } catch (_) {
                // Error, treat as single object
                arguments = <dynamic>[messageText];
              }
            } else {
              // Single object, treat as list
              arguments = <dynamic>[messageText];
            }

            callback(arguments);
          },
        ),
      );
      _webViewController!.setJavaScriptChannels(_jsChannels);
    }
  }

  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    if (_inAppWebViewController != null) {
      return _inAppWebViewController!.evaluateJavascript(
        source: source,
        contentWorld: contentWorld,
      );
    }

    if (_webViewController != null) {
      return _webViewController!.evaluateJavascript(source);
    }
  }

  Future<void> reload() async {
    await _inAppWebViewController?.reload();
    await _webViewController?.reload();
  }

  void dispose() {}
}
