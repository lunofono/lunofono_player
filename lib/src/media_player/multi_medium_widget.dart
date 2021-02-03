import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;

import 'media_player_error.dart' show MediaPlayerError;
import 'media_progress_indicator.dart' show MediaProgressIndicator;
import 'multi_medium_state.dart' show MultiMediumState;
import 'multi_medium_track_widget.dart' show MultiMediumTrackWidget;

/// A player for a [MultiMedium].
///
/// This player is a [Consumer] of [MultiMediumState], which controls the
/// playing of the medium and just notifies this widget about updates.
///
/// If the state has an error, then a [MediaPlayerError] will be show to
/// display the error.
///
/// Otherwise, if both main and background tracks initialization is completed,
/// then the state of the current medium of the visualizable track will be shown
/// using a [MultiMediumTrackWidget]. But only if a track is visualizable. If
/// none of the tracks are visualizable (for example, it is an [Audible] main
/// track and an empty background track, then an empty [Container] will be
/// shown.
///
/// If there is no error and tracks are not done with initialization, then
/// a [CircularProgressIndicator] will be shown to let the user know
/// initialization is still in progress.
class MultiMediumWidget extends StatelessWidget {
  /// Constructs a [MultiMediumWidget].
  const MultiMediumWidget({
    Key key,
  }) : super(key: key);

  /// Creates a [MultiMediumTrackWidget].
  ///
  /// This is mainly useful for testing.
  @protected
  MultiMediumTrackWidget createTrackWidget() => MultiMediumTrackWidget();

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) => Consumer<MultiMediumState>(
        builder: (context, state, child) {
          final mainTrack = state.mainTrackState;
          final backgroundTrack = state.backgroundTrackState;

          if (state.isInitialized) {
            final mainWidget = ChangeNotifierProvider.value(
              value: mainTrack,
              child: createTrackWidget(),
            );
            final backgroundWiget = ChangeNotifierProvider.value(
              value: backgroundTrack,
              child: createTrackWidget(),
            );

            // The first widget in the stack, should be visualizable track. If
            // there is no visualizable track, then the mainTrack takes
            // precedence, so it will be centered in the stack.
            final firstWidget = mainTrack.isVisualizable
                ? mainWidget
                : backgroundTrack.isVisualizable
                    ? backgroundWiget
                    : mainWidget;
            final children = <Widget>[Center(child: firstWidget)];

            // The second widget in the stack should be the main track if the
            // first widget was the background track (as we know there is a main
            // track too). If the first widget in the stack is the main track,
            // we only add the background track if it is not empty.
            if (identical(firstWidget, backgroundWiget)) {
              children.add(mainWidget);
            } else if (backgroundTrack.isNotEmpty) {
              children.add(backgroundWiget);
            }

            return Stack(
              // This alignment will count only for the seconds widget in the
              // stack, as the first one will be forcibly centered.
              alignment: Alignment.bottomCenter,
              children: children,
            );
          }

          // Still initializing
          return MediaProgressIndicator(
            visualizable:
                mainTrack.isVisualizable || backgroundTrack.isVisualizable,
          );
        },
      );
}
