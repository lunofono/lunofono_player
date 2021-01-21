import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;

import 'media_player_error.dart' show MediaPlayerError;
import 'media_progress_indicator.dart' show MediaProgressIndicator;
import 'multi_medium_state.dart' show MultiMediumState, MultiMediumTrackState;

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
/// using a [MultiMediumTrackPlayer]. But only if a track is visualizable. If
/// none of the tracks are visualizable (for example, it is an [Audible] main
/// track and an empty background track, then an empty [Container] will be
/// shown.
///
/// If there is no error and tracks are not done with initialization, then
/// a [CircularProgressIndicator] will be shown to let the user know
/// initialization is still in progress.
class MultiMediumPlayer extends StatelessWidget {
  /// Constructs a [MultiMediumPlayer].
  const MultiMediumPlayer({
    Key key,
  }) : super(key: key);

  /// Creates a [MultiMediumTrackPlayer].
  ///
  /// This is mainly useful for testing.
  @protected
  MultiMediumTrackPlayer createTrackPlayer() => MultiMediumTrackPlayer();

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) => Consumer<MultiMediumState>(
        builder: (context, state, child) {
          final mainTrack = state.mainTrackState;
          final backgroundTrack = state.backgroundTrackState;

          if (state.allInitialized) {
            final mainWidget = ChangeNotifierProvider.value(
              value: mainTrack,
              child: createTrackPlayer(),
            );
            final backgroundWiget = ChangeNotifierProvider.value(
              value: backgroundTrack,
              child: createTrackPlayer(),
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
class MultiMediumTrackPlayer extends StatelessWidget {
  /// Constructs a [MultiMediumTrackPlayer].
  const MultiMediumTrackPlayer({Key key}) : super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) =>
      // if we finished playing, we still want to show the last medium for the
      // main track, so the fade-out effect has still something to show.
      // For the background track, the user might want to be able to override
      // this behaviour. See:
      // https://gitlab.com/lunofono/lunofono-app/-/issues/37
      Consumer<MultiMediumTrackState>(
        builder: (context, state, child) {
          final current = state.current ?? state.last;

          if (current.isErroneous) {
            return MediaPlayerError(current.error);
          }

          if (current.isInitialized) {
            if (!state.isVisualizable) {
              // FIXME: This is a bit hacky. At some point it might be better to
              // have 2 build methods in SingleMediumController: buildAudible()
              // and buildVisualizable() and use then depeding on what kind of
              // track we are showing.
              return Container(key: current.widgetKey);
            }

            var widget = current.build(context);
            if (current.size.width > current.size.height) {
              widget = RotatedBox(
                quarterTurns: 1,
                child: widget,
              );
            }
            return widget;
          }

          // Still initializing
          return MediaProgressIndicator(visualizable: state.isVisualizable);
        },
      );
}
