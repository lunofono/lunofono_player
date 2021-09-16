import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

/// A widget to display errors instead of a player.
///
/// This widget is used to display an error message when a [VideoPlayer] or an
/// [ImagePlayer] can't really start.
class MediaPlayerError extends StatelessWidget {
  /// The error object to be displayed by this widget.
  final dynamic error;

  /// Constructs a new [MediaPlayerError].
  ///
  /// The widget will display the error description provided by [error].
  const MediaPlayerError(this.error, {Key? key}) : super(key: key);

  /// Builds this [error] message.
  ///
  /// The message will be constructed depending on what type of error needs to
  /// be shown.
  String buildMessage() {
    var details = '';
    String? message = error.toString();
    if (error is PlatformException) {
      final platformError = error as PlatformException;
      if (platformError.details != null) {
        details = ' (${platformError.details})';
      }
      message = platformError.message;
    }
    return '$message$details';
  }

  /// Builds the UI for this widget.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Media could not be played: ${buildMessage()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline6!.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
