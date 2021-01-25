import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show SingleMedium, MultiMedium, Playable;

import 'media_player/controller_registry.dart' show ControllerRegistry;
import 'media_player/media_player_error.dart' show MediaPlayerError;
import 'media_player/multi_medium_widget.dart' show MultiMediumWidget;
import 'media_player/multi_medium_state.dart' show MultiMediumState;
import 'media_player/single_medium_state.dart'
    show SingleMediumState, SingleMediumStateFactory;
import 'media_player/single_medium_widget.dart' show SingleMediumWidget;

/// A media player widget.
///
/// The player can play a [MultiMedium] via [SingleMediumController] plug-ins
/// that are obtained via the [ControllerRegistry]. It handles the playing and
/// synchronization of the [playable.mainTrack] and
/// [playable.backgroundTrack] and also the asynchronous nature of the player
/// controllers, by showing a progress indicator while the media is loading, and
/// the media afterwards, or a [MediaPlayerError] if an error occurred.
///
/// If a medium is played for which there is no [SingleMediumController]
/// registered in the [ControllerRegistry], a [MediaPlayerError] will be shown
/// instead of that medium.
///
/// All the orchestration behind the scenes is performed by
/// a [MultiMediumState] that is provided via a [ChangeNotifierProvider].
class MediaPlayer extends StatelessWidget {
  /// The medium to play by this player.
  final Playable playable;

  /// The background color for this player.
  final Color backgroundColor;

  /// The action to perform when this player stops.
  final void Function(BuildContext) onMediaStopped;

  /// The [ControllerRegistry] to create [SingleMediumController]s.
  final ControllerRegistry registry;

  /// The factory used to create [SingleMediumState]s.
  final SingleMediumStateFactory singleMediumStateFactory;

  /// Constructs a new [MediaPlayer].
  ///
  /// The player will play the [playable] with a background color
  /// [backgroundColor] (or black if null is used). When the media stops
  /// playing, either because it was played completely or because it was stopped
  /// by the user, the [onMediaStopped] callback will be called (if non-null).
  ///
  /// If a [registry] is provided, then it is used to create the controller for
  /// the media inside the [playable]. Otherwise
  /// [ControllerRegistry.instance] is used.
  const MediaPlayer({
    @required this.playable,
    Color backgroundColor,
    this.onMediaStopped,
    this.registry,
    this.singleMediumStateFactory = const SingleMediumStateFactory(),
    Key key,
  })  : assert(playable != null),
        backgroundColor = backgroundColor ?? Colors.black,
        super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) {
    final registry = this.registry ?? ControllerRegistry.instance;

    if (playable is SingleMedium) {
      final medium = playable as SingleMedium;
      SingleMediumState state;
      final create = registry.getFunction(medium);
      if (create == null) {
        state = singleMediumStateFactory.bad(medium,
            'Unsupported type ${medium.runtimeType} for ${medium.resource}');
      } else {
        final controller = create(medium, onMediumFinished: onMediaStopped);
        state = singleMediumStateFactory.good(controller, isVisualizable: true);
      }
      state.initialize(context).then((_) => state.play(context));
      return ChangeNotifierProvider<SingleMediumState>.value(
        value: state,
        child: Consumer<SingleMediumState>(
            child: Material(
              elevation: 0,
              color: backgroundColor,
              child: Center(
                child: SingleMediumWidget(),
              ),
            ),
            builder: (context, dynamic state, child) {
              return GestureDetector(
                onTap: () {
                  // XXX: For now the stop reaction is hardcoded to the tap.
                  // Also we should handle errors in the pause()'s future
                  state.pause(context);
                  onMediaStopped?.call(context);
                },
                child: child,
              );
            }),
      );
    }
    if (playable is MultiMedium) {
      final medium = playable as MultiMedium;
      return ChangeNotifierProvider<MultiMediumState>(
        create: (context) => MultiMediumState(
          medium,
          registry,
          onMediumFinished: onMediaStopped,
        )..initialize(context),
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
                  state.mainTrackState.pauseCurrent(context);
                  state.backgroundTrackState.pauseCurrent(context);
                  onMediaStopped?.call(context);
                },
                child: child,
              );
            }),
      );
    }

    return MediaPlayerError('Unsupported media type ${playable.runtimeType}');
  }
}
