import 'package:flutter/material.dart';

/// A progress indicator that shows what kind of media is loading.
///
/// If [isVisualizable] is true, a [Icons.local_movies] will be shown, otherwise
/// a [Icons.music_note] will be shown. A [CircularProgressIndicator] is always
/// shown in the back.
class MediaProgressIndicator extends StatelessWidget {
  /// If true, a [Icons.local_movies] is shown, otherwise a [Icons.music_note].
  final bool isVisualizable;

  /// Constructs a [MediaProgressIndicator] setting if it's [visualizable].
  const MediaProgressIndicator({@required bool visualizable})
      : assert(visualizable != null),
        isVisualizable = visualizable;

  /// Builds the widget.
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(isVisualizable ? Icons.local_movies : Icons.music_note),
        CircularProgressIndicator(),
      ],
    );
  }
}
