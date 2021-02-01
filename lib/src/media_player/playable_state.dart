import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:lunofono_bundle/lunofono_bundle.dart' show Playable;

/// A common interface for a state of a [Playable].
abstract class PlayableState implements ChangeNotifier, DiagnosticableTree {
  /// The playable this state represents.
  Playable get playable;

  /// The function to call when this playable finishes playing.
  @visibleForTesting
  void Function(BuildContext context) get onFinished;

  /// Initializes this playable state.
  ///
  /// If [startPlaying] is true, then [play()] will be called after the
  /// initialization is done.
  Future<void> initialize(BuildContext context, {bool startPlaying = false});

  /// Plays this playable.
  ///
  /// It does nothing if the playable was already playing or finished.
  Future<void> play(BuildContext context);

  /// Pauses this playable.
  ///
  /// It does nothing if the playable was already paused or finished.
  Future<void> pause(BuildContext context);

  /// Disposes this playable.
  ///
  /// After it is done, the playable will disposed, so it can't be played
  /// again, but it also can become [isErroneous].
  @override
  Future<void> dispose();
}
