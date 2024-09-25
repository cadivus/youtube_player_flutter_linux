// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/webview/webview.dart';

import '../enums/player_state.dart';
import '../utils/youtube_meta_data.dart';
import '../utils/youtube_player_controller.dart';
import '../widgets/html/youtube_player_view.dart';

/// A raw youtube player widget which interacts with the underlying webview inorder to play YouTube videos.
///
/// Use [YoutubePlayer] instead.
class RawYoutubePlayer extends StatefulWidget {
  /// Creates a [RawYoutubePlayer] widget.
  const RawYoutubePlayer({
    super.key,
    this.onEnded,
  });

  /// {@macro youtube_player_flutter.onEnded}
  final void Function(YoutubeMetaData metaData)? onEnded;

  @override
  State<RawYoutubePlayer> createState() => _RawYoutubePlayerState();
}

class _RawYoutubePlayerState extends State<RawYoutubePlayer>
    with WidgetsBindingObserver {
  YoutubePlayerController? controller;
  PlayerState? _cachedPlayerState;
  bool _isPlayerReady = false;
  bool _onLoadStopCalled = false;

  late bool _playerViewIsInited;

  @override
  void initState() {
    super.initState();
    _playerViewIsInited = YoutubePlayerView.playerViewIsInited;
    if (!_playerViewIsInited) {
      YoutubePlayerView.initPlayerViewRenderer().then((_) {
        setState(() {
          _playerViewIsInited = true;
        });
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_cachedPlayerState != null &&
            _cachedPlayerState == PlayerState.playing) {
          controller?.play();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _cachedPlayerState = controller!.value.playerState;
        controller?.pause();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    controller = YoutubePlayerController.of(context);
    return IgnorePointer(
      ignoring: true,
      child: !_playerViewIsInited
          ? SizedBox.shrink()
          : Webview(
              data: YoutubePlayerView.renderPlayerView(controller!),
              onWebViewCreated: (webController) {
                controller!.updateValue(
                  controller!.value.copyWith(webViewController: webController),
                );
                webController
                  ..addJavaScriptHandler(
                    handlerName: 'Ready',
                    callback: (_) {
                      _isPlayerReady = true;
                      if (_onLoadStopCalled) {
                        controller!.updateValue(
                          controller!.value.copyWith(isReady: true),
                        );
                      }
                    },
                  )
                  ..addJavaScriptHandler(
                    handlerName: 'StateChange',
                    callback: (args) {
                      switch (args.first as int) {
                        case -1:
                          controller!.updateValue(
                            controller!.value.copyWith(
                              playerState: PlayerState.unStarted,
                              isLoaded: true,
                            ),
                          );
                          break;
                        case 0:
                          widget.onEnded?.call(controller!.metadata);
                          controller!.updateValue(
                            controller!.value.copyWith(
                              playerState: PlayerState.ended,
                            ),
                          );
                          break;
                        case 1:
                          controller!.updateValue(
                            controller!.value.copyWith(
                              playerState: PlayerState.playing,
                              isPlaying: true,
                              hasPlayed: true,
                              errorCode: 0,
                            ),
                          );
                          break;
                        case 2:
                          controller!.updateValue(
                            controller!.value.copyWith(
                              playerState: PlayerState.paused,
                              isPlaying: false,
                            ),
                          );
                          break;
                        case 3:
                          controller!.updateValue(
                            controller!.value.copyWith(
                              playerState: PlayerState.buffering,
                            ),
                          );
                          break;
                        case 5:
                          controller!.updateValue(
                            controller!.value.copyWith(
                              playerState: PlayerState.cued,
                            ),
                          );
                          break;
                        default:
                          throw Exception("Invalid player state obtained.");
                      }
                    },
                  )
                  ..addJavaScriptHandler(
                    handlerName: 'PlaybackQualityChange',
                    callback: (args) {
                      controller!.updateValue(
                        controller!.value
                            .copyWith(playbackQuality: args.first as String),
                      );
                    },
                  )
                  ..addJavaScriptHandler(
                    handlerName: 'PlaybackRateChange',
                    callback: (args) {
                      final num rate = args.first;
                      controller!.updateValue(
                        controller!.value
                            .copyWith(playbackRate: rate.toDouble()),
                      );
                    },
                  )
                  ..addJavaScriptHandler(
                    handlerName: 'Errors',
                    callback: (args) {
                      controller!.updateValue(
                        controller!.value
                            .copyWith(errorCode: int.parse(args.first)),
                      );
                    },
                  )
                  ..addJavaScriptHandler(
                    handlerName: 'VideoData',
                    callback: (args) {
                      controller!.updateValue(
                        controller!.value.copyWith(
                            metaData: YoutubeMetaData.fromRawData(args.first)),
                      );
                    },
                  )
                  ..addJavaScriptHandler(
                    handlerName: 'VideoTime',
                    callback: (args) {
                      final position = args.first * 1000;
                      final num buffered = args.last;
                      controller!.updateValue(
                        controller!.value.copyWith(
                          position: Duration(milliseconds: position.floor()),
                          buffered: buffered.toDouble(),
                        ),
                      );
                    },
                  );
              },
              userAgent: userAgent,
              useHybridComposition: controller!.flags.useHybridComposition,
              onLoaded: () {
                _onLoadStopCalled = true;
                if (_isPlayerReady) {
                  controller!.updateValue(
                    controller!.value.copyWith(isReady: true),
                  );
                }
              },
            ),
    );
  }

  String get userAgent => controller!.flags.forceHD
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
      : '';
}
