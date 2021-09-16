import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;

import 'media_player_error.dart' show MediaPlayerError;
import 'multi_medium_track_state.dart' show MultiMediumTrackState;
import 'single_medium_widget.dart' show SingleMediumWidget;

/// A player for a [MultiMediumTrack].
///
/// This player is a [Consumer] of [MultiMediumTrackState], which controls
/// the playing of the track and just notifies this widget about updates.
///
/// If the track has an error, then a [MediaPlayerError] will be show to display
/// the error.
///
/// Otherwise, if all media in the track is done with the initializing, then the
/// current track's medium displayed using [SingleMediumController.build()]. If
/// the aspect ratio of the medium is landscape, then it will be wrapped in
/// a [RotatedBox] too.
///
/// If there is no error and initialization is not done yet, then
/// a [CircularProgressIndicator] will be shown to let the user know
/// initialization is still in progress.
class MultiMediumTrackWidget extends StatelessWidget {
  /// Constructs a [MultiMediumTrackWidget].
  const MultiMediumTrackWidget({Key? key}) : super(key: key);

  /// Creates a [MultiMediumTrackWidget].
  ///
  /// This is mainly useful for testing.
  @protected
  @visibleForTesting
  Widget createSingleMediumWidget() => SingleMediumWidget();

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) => Consumer<MultiMediumTrackState>(
        builder: (context, state, child) => ChangeNotifierProvider.value(
          // if we finished playing, we still want to show the last medium for
          // the main track, so the fade-out effect has still something to show.
          // For the background track, the user might want to be able to
          // override this behaviour. See:
          // https://gitlab.com/lunofono/lunofono-app/-/issues/37
          value: state.current ?? state.last,
          child: createSingleMediumWidget(),
        ),
      );
}
