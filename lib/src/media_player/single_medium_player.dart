import 'package:flutter/material.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;

import 'package:lunofono_bundle/lunofono_bundle.dart' show SingleMedium;

import 'controller_registry.dart' show ControllerRegistry;
import 'single_medium_state.dart' show SingleMediumState;
import 'single_medium_widget.dart' show SingleMediumWidget;

/// A [SingleMedium] player.
///
/// The player can play a [SingleMedium] via [SingleMediumController] plug-ins
/// that are obtained via the [ControllerRegistry]. It handles the asynchronous
/// nature of the player controllers, by showing a progress indicator while the
/// media is loading, and the media afterwards, or a [MediaPlayerError] if an
/// error occurred.
///
/// If a medium is played for which there is no [SingleMediumController]
/// registered in the [ControllerRegistry], a [MediaPlayerError] will be shown
/// instead of that medium.
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

  /// The [ControllerRegistry] to create [SingleMediumController]s.
  final ControllerRegistry registry;

  /// Creates a new [SingleMediumPlayer].
  ///
  /// The player will play the [medium] with a background color
  /// [backgroundColor] (or black if null is used). When the media stops
  /// playing, either because it was played completely or because it was stopped
  /// by the user, the [onMediaStopped] callback will be called (if non-null).
  ///
  /// If a [registry] is provided, then it is used to create the controller for
  /// the media inside the [medium]. Otherwise [ControllerRegistry.instance] is
  /// used.
  const SingleMediumPlayer({
    @required this.medium,
    Color backgroundColor,
    this.onMediaStopped,
    this.registry,
    Key key,
  })  : assert(medium != null),
        backgroundColor = backgroundColor ?? Colors.black,
        super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) {
    final registry = this.registry ?? ControllerRegistry.instance;
    final createController = registry.getFunction(medium);
    return ChangeNotifierProvider<SingleMediumState>(
      create: (context) {
        if (createController == null) {
          return SingleMediumState.erroneous(
            medium,
            'Unsupported type ${medium.runtimeType} for ${medium.resource}',
          );
        }
        final controller =
            createController(medium, onMediumFinished: onMediaStopped);
        final state = SingleMediumState(controller);
        state.initialize(context).then((_) => state.play(context));
        return state;
      },
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
}
