import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:meta/meta.dart' show protected;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Medium, MultiMedium, Playlist, SingleMedium;

import 'playable_state.dart' show PlayableState;
import 'single_medium_state.dart' show SingleMediumState;
import 'multi_medium_state.dart' show MultiMediumState;

/// Exception thrown when an unsupported [Medium] type appears in a [Playlist].
class UnsupportedMediumTypeError implements Exception {}

/// A state for playing a [Playlist].
class PlaylistState
    with ChangeNotifier, DiagnosticableTreeMixin
    implements PlayableState {
  /// Function used to create the concrete [PlayableState] instances.
  @visibleForTesting
  static PlayableState Function(
    Medium medium, {
    void Function(BuildContext) onFinished,
  }) createPlayableState = (medium, {onFinished}) {
    if (medium is SingleMedium) {
      return SingleMediumState(medium, onFinished: onFinished);
    }
    if (medium is MultiMedium) {
      return MultiMediumState(medium, onFinished: onFinished);
    }
    throw UnsupportedMediumTypeError();
  };

  /// The playlist this state represents.
  @override
  final Playlist playable;

  /// The list of [PlayableState] for the [playlist.media].
  final mediaState = <PlayableState>[];

  /// The [mediaState]'s index of the current medium being played.
  ///
  /// It can be as big as [mediaState.length], in which case it means the
  /// playlist finished playing.
  int currentIndex = 0;

  /// True if all [playlist.media] is initialized.
  bool get isInitialized => _allInitialized;
  bool _allInitialized = false;

  /// Function to call when the [playlist] finished playing all the media.
  @override
  final void Function(BuildContext context) onFinished;

  /// If true, all the media in this playlist has finished playing.
  bool get isFinished => currentIndex >= mediaState.length;

  /// The current [PlayableState] being played, or null if [isFinished].
  PlayableState get current => isFinished ? null : mediaState[currentIndex];

  /// The last [PlayableState] in this playlist.
  PlayableState get last => mediaState.last;

  /// Plays the next medium in the [playlist].
  void _playNext(BuildContext context) {
    currentIndex++;
    if (isFinished) {
      onFinished?.call(context);
    } else {
      play(context);
    }
    notifyListeners();
  }

  /// Constructs a [PlaylistState] from a [Playlist].
  ///
  /// The [playlist] must be non-null. If [onFinished] is provided and non-null,
  /// it will be called when all the [playlist.media] finished playing.
  ///
  /// When the underlaying [Medium] state is created, its [onFinished] callback
  /// will be used to play the next media in the [media] list. If last medium
  /// finished playing, then this [onFinished] will be called.
  @protected
  PlaylistState(
    Playlist playlist, {
    this.onFinished,
  })  : assert(playlist != null),
        playable = playlist {
    mediaState.addAll(playlist.media
        .map((m) => createPlayableState(m, onFinished: _playNext)));
  }

  /// Initialize all [PlayableState] in [mediaState].
  @override
  Future<void> initialize(BuildContext context,
      {bool startPlaying = false}) async {
    await Future.wait(mediaState.map((s) => s.initialize(context)));
    _allInitialized = true;
    notifyListeners();
    if (startPlaying) await play(context);
  }

  /// Starts or resume playing the media in this [playlist].
  ///
  /// If it's already playing or it finished playing all the media (and
  /// it's not looping), it does nothing.
  @override
  Future<void> play(BuildContext context) => current?.play(context);

  /// Pauses the playing of the media in this [playlist].
  ///
  /// It does nothing if it's already paused.
  @override
  Future<void> pause(BuildContext context) => current?.pause(context);

  /// Disposes all the [PlayableState] in [mediaState].
  @override
  Future<void> dispose() async {
    // FIXME: Will only report the first error and discard the next.
    await Future.forEach(mediaState, (PlayableState s) => s.dispose());
    super.dispose();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final initialized = isInitialized ? '' : '<uninitialized> ';
    return '$runtimeType(${initialized}current: $currentIndex, '
        'media: ${mediaState.length})';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('isInitialized',
          value: isInitialized, ifFalse: '<uninitialized>'))
      ..add(IntProperty('currentIndex', currentIndex))
      ..add(IntProperty('mediaState.length', mediaState.length));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[
        for (var i = 0; i < mediaState.length; i++)
          mediaState[i].toDiagnosticsNode(name: '$i')
      ];
}
