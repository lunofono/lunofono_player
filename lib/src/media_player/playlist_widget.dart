import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;

import 'media_player_error.dart' show MediaPlayerError;
import 'media_progress_indicator.dart' show MediaProgressIndicator;
import 'multi_medium_state.dart' show MultiMediumState;
import 'multi_medium_widget.dart' show MultiMediumWidget;
import 'playlist_state.dart' show PlaylistState;
import 'single_medium_state.dart' show SingleMediumState;
import 'single_medium_widget.dart' show SingleMediumWidget;

/// A widget to show the state of a [PlaylistState].
///
/// This widget is a [Consumer] of [PlaylistState], which controls
/// the playing of the playlist's media and just notifies this widget about
/// updates.
///
/// If a [Medium] type in the [Playlist] is unsupported, then
/// a [MediaPlayerError] will be show to display the error.
///
/// If initialization is not done yet, then a [CircularProgressIndicator] will
/// be shown to let the user know initialization is still in progress.
///
/// Otherwise, if all media in the playlist is done with the initializing, the
/// current medium is displayed (or the last if playing is done).
class PlaylistWidget extends StatelessWidget {
  @visibleForTesting
  static Widget Function() createSingleMediumWidget =
      () => SingleMediumWidget();

  @visibleForTesting
  static Widget Function() createMultiMediumWidget = () => MultiMediumWidget();

  /// Constructs a [MultiMediumTrackWidget].
  const PlaylistWidget({Key? key}) : super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) => Consumer<PlaylistState>(
        builder: (context, state, child) {
          if (state.isInitialized) {
            final shown = state.current ?? state.last;
            // we need this type casting because ChangeNotifierProvider needs
            // a concrete type so then Consumer and Provider.of can find it.
            if (shown is SingleMediumState) {
              return ChangeNotifierProvider.value(
                  value: shown, child: createSingleMediumWidget());
            }
            if (shown is MultiMediumState) {
              return ChangeNotifierProvider.value(
                  value: shown, child: createMultiMediumWidget());
            }
            return MediaPlayerError('Unsupported type ${shown.runtimeType}');
          }

          // Still initializing
          return MediaProgressIndicator(visualizable: true);
        },
      );
}
