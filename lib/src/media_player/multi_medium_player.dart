import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;

import 'package:lunofono_bundle/lunofono_bundle.dart' show MultiMedium;

import 'media_player_error.dart' show MediaPlayerError;
import 'multi_medium_widget.dart' show MultiMediumWidget;
import 'multi_medium_state.dart' show MultiMediumState;

/// A media player widget.
///
/// The player can play a [MultiMedium]. It handles the playing and
/// synchronization of the [medium.mainTrack] and [medium.backgroundTrack] and
/// also the asynchronous nature of the player controllers, by showing
/// a progress indicator while the media is loading, and the media afterwards,
/// or a [MediaPlayerError] if an error occurred.
///
/// All the orchestration behind the scenes is performed by
/// a [MultiMediumState] that is provided via a [ChangeNotifierProvider].
class MultiMediumPlayer extends StatelessWidget {
  /// The medium to play by this player.
  final MultiMedium medium;

  /// The background color for this player.
  final Color backgroundColor;

  /// The action to perform when this player stops.
  final void Function(BuildContext)? onMediaStopped;

  /// Constructs a new [MultiMediumPlayer].
  ///
  /// The player will play the [medium] with a background color
  /// [backgroundColor] (or black if null is used). When the media stops
  /// playing, either because it was played completely or because it was stopped
  /// by the user, the [onMediaStopped] callback will be called (if non-null).
  ///
  const MultiMediumPlayer({
    required this.medium,
    Color? backgroundColor,
    this.onMediaStopped,
    Key? key,
  })  : backgroundColor = backgroundColor ?? Colors.black,
        super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<MultiMediumState>(
        create: (context) => MultiMediumState(
          medium,
          onFinished: onMediaStopped,
        )..initialize(context, startPlaying: true),
        child: Consumer<MultiMediumState>(
            child: Material(
              elevation: 0,
              color: backgroundColor,
              child: Center(
                child: MultiMediumWidget(),
              ),
            ),
            builder: (context, dynamic state, child) {
              return GestureDetector(
                onTap: () {
                  // XXX: For now the stop reaction is hardcoded to the tap.
                  // Also we should handle errors in the pause()'s future
                  state.mainTrackState.pause(context);
                  state.backgroundTrackState.pause(context);
                  onMediaStopped?.call(context);
                },
                child: child,
              );
            }),
      );
}
