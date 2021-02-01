import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;

import 'package:lunofono_bundle/lunofono_bundle.dart' show SingleMedium;

import 'single_medium_state.dart' show SingleMediumState;
import 'single_medium_widget.dart' show SingleMediumWidget;

/// A [SingleMedium] player.
///
/// The player can play a [SingleMedium]. It handles the asynchronous nature of
/// the player controllers, by showing a progress indicator while the media is
/// loading, and the media afterwards, or a [MediaPlayerError] if an error
/// occurred.
///
/// All the orchestration behind the scenes is performed by
/// a [SingleMediumState] that is provided via a [ChangeNotifierProvider].
class SingleMediumPlayer extends StatelessWidget {
  /// The [SingleMedium] to play by this player.
  final SingleMedium medium;

  /// The background [Color] for this player.
  final Color backgroundColor;

  /// The action to perform when this player stops.
  final void Function(BuildContext) onMediaStopped;

  /// Creates a new [SingleMediumPlayer].
  ///
  /// The player will play the [medium] with a background color
  /// [backgroundColor] (or black if null is used). When the media stops
  /// playing, either because it was played completely or because it was stopped
  /// by the user, the [onMediaStopped] callback will be called (if non-null).
  const SingleMediumPlayer({
    @required this.medium,
    Color backgroundColor,
    this.onMediaStopped,
    Key key,
  })  : assert(medium != null),
        backgroundColor = backgroundColor ?? Colors.black,
        super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<SingleMediumState>(
        create: (context) =>
            SingleMediumState(medium, onMediumFinished: onMediaStopped)
              ..initialize(context, startPlaying: true),
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              // TODO: For now the stop reaction is hardcoded to the tap.
              // Also we should handle errors in the pause()'s future
              Provider.of<SingleMediumState>(context, listen: false)
                  .pause(context);
              onMediaStopped?.call(context);
            },
            child: Material(
              elevation: 0,
              color: backgroundColor,
              child: Center(
                child: SingleMediumWidget(),
              ),
            ),
          ),
        ),
      );
}
