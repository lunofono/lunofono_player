import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show Consumer;

import 'media_player_error.dart' show MediaPlayerError;
import 'media_progress_indicator.dart' show MediaProgressIndicator;
import 'single_medium_state.dart' show SingleMediumState;

/// A player for a [SingleMediumState].
///
/// This player is a [Consumer] of [SingleMediumState], which controls
/// the playing of the track and just notifies this widget about updates.
///
/// If the medium has an error, then a [MediaPlayerError] will be show to
/// display the error.
///
/// Otherwise, if the medium is done with the initialization, then the
/// medium is displayed using [SingleMediumController.build()]. If the aspect
/// ratio of the medium is landscape, then it will be wrapped in a [RotatedBox]
/// too.
///
/// If there is no error and initialization is not done yet, then
/// a [MediaProgressIndicator] will be shown to let the user know initialization
/// is still in progress.
class SingleMediumWidget extends StatelessWidget {
  /// Creates a [SingleMediumWidget].
  const SingleMediumWidget({Key? key}) : super(key: key);

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) => Consumer<SingleMediumState>(
        builder: (context, state, child) {
          if (state.isErroneous) {
            return MediaPlayerError(state.error);
          }

          if (state.isInitialized) {
            final controller = state.controller!;
            final size = state.size!;

            // FIXME: This is a bit hacky. At some point it might be better to
            // have 2 build methods in SingleMediumController: buildAudible()
            // and buildVisualizable() and use then depeding on what kind of
            // track we are showing.
            if (!state.isVisualizable) {
              return Container(key: controller.widgetKey);
            }

            var widget = controller.build(context);
            if (size.width > size.height) {
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
