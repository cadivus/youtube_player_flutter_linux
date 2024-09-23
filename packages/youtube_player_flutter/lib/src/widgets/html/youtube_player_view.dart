import 'package:flutter/services.dart' show rootBundle;

import '../../../youtube_player_flutter.dart';

class YoutubePlayerView {
  static String? _loadedString;

  static Future<void> initPlayerViewRenderer() async {
    if (playerViewIsInited) {
      return;
    }
    _loadedString = await rootBundle.loadString(
      'packages/youtube_player_flutter/lib/src/widgets/html/youtube_player_view.html',
    );
  }

  static get playerViewIsInited => _loadedString != null;

  static String _replaceVariableValue(String input, String variableName, String variableValue) {
    final pattern = RegExp(r'/\*>' + variableName + r' START<\*/.*?/\*>' + variableName + r' END<\*/', dotAll: true);

    return input.replaceAllMapped(pattern, (match) {
      return variableValue;
    });
  }

  static String _boolean(bool value) => value == true ? "'1'" : "'0'";

  static String renderPlayerView(YoutubePlayerController controller) {
    String content = _loadedString!;

    content = _replaceVariableValue(content, 'initialVideoId', "'${controller.initialVideoId}'");
    content = _replaceVariableValue(content, 'enableCaption', _boolean(controller.flags.enableCaption));
    content = _replaceVariableValue(content, 'captionLanguage', "'${controller.flags.captionLanguage}'");
    content = _replaceVariableValue(content, 'autoPlay', _boolean(controller.flags.autoPlay));
    content = _replaceVariableValue(content, 'startAt', "${controller.flags.startAt}");
    content = _replaceVariableValue(content, 'endAt', "${controller.flags.endAt}");

    return content;
  }
}


