import 'package:flutter/material.dart';
import 'package:lunofono_bundle/lunofono_bundle.dart' show Playlist;

import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;

import 'playlist_state.dart' show PlaylistState;
import 'playlist_widget.dart' show PlaylistWidget;

/// A [Playlist] player.
///
/// The player can play a [Playlist]. It handles the asynchronous nature of
/// the player controllers, by showing a progress indicator while the media is
/// loading, and the media afterwards, or an error message if an error occurred.
///
/// All the orchestration behind the scenes is performed by
/// a [PlaylistState] that is provided via a [ChangeNotifierProvider].
class PlaylistPlayer extends StatelessWidget {
  @visibleForTesting
  static Widget Function() createPlaylistWidget = () => PlaylistWidget();

  /// The [Playlist] to play by this player.
  final Playlist playlist;

  /// The background [Color] for this player.
  final Color backgroundColor;

  /// The action to perform when this player stops.
  final void Function(BuildContext)? onMediaStopped;

  /// Creates a new [PlaylistPlayer].
  ///
  /// The player will play the [playlist] with a background color
  /// [backgroundColor] (or black if null is used). When the media stops
  /// playing, either because it was played completely or because it was stopped
  /// by the user, the [onMediaStopped] callback will be called (if non-null).
  const PlaylistPlayer({
    required this.playlist,
    Color? backgroundColor,
    this.onMediaStopped,
    Key? key,
  })  : backgroundColor = backgroundColor ?? Colors.black,
        super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<PlaylistState>(
        create: (context) => PlaylistState(playlist, onFinished: onMediaStopped)
          ..initialize(context, startPlaying: true),
        child: Builder(
          builder: (context) {
            final state = Provider.of<PlaylistState>(context, listen: false);
            return GestureDetector(
              onTap: () {
                // TODO: For now the stop reaction is hardcoded to the tap.
                // Also we should handle errors in the pause()'s future
                state.pause(context);
                onMediaStopped?.call(context);
              },
              child: Material(
                elevation: 0,
                color: backgroundColor,
                child: Center(
                  child: createPlaylistWidget(),
                ),
              ),
            );
          },
        ),
      );
}
