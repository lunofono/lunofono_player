import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:meta/meta.dart' show protected;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show
        SingleMedium,
        NoTrack,
        MultiMediumTrack,
        BackgroundMultiMediumTrack,
        VisualizableMultiMediumTrack,
        VisualizableBackgroundMultiMediumTrack;

import 'single_medium_state.dart' show SingleMediumState;

/// A player state for playing a [MultiMediumTrack] and notifying changes.
class MultiMediumTrackState with ChangeNotifier, DiagnosticableTreeMixin {
  /// Function used to create [SingleMediumState] instances.
  @visibleForTesting
  static var createSingleMediumState = (
    SingleMedium medium, {
    bool isVisualizable,
    void Function(BuildContext) onMediumFinished,
  }) =>
      SingleMediumState(
        medium,
        isVisualizable: isVisualizable,
        onMediumFinished: onMediumFinished,
      );

  /// If true, then a proper widget needs to be shown for this track.
  final bool isVisualizable;

  /// The list of [SingleMediumState] for this track.
  ///
  /// This stores the state of every individual medium in this track.
  final mediaState = <SingleMediumState>[];

  /// The [mediaState]'s index of the current medium being played.
  ///
  /// It can be as big as [mediaState.length], in which case it means the track
  /// finished playing.
  int currentIndex = 0;

  /// True when all [mediaState] is initialized.
  bool get isInitialized => _allInitialized;
  bool _allInitialized = false;

  /// If true, all the media in this track has finished playing.
  bool get isFinished => currentIndex >= mediaState.length;

  /// If true, then the track is empty ([mediaState] is empty).
  bool get isEmpty => mediaState.isEmpty;

  /// If true, then the track is not empty (has some [mediaState]).
  bool get isNotEmpty => mediaState.isNotEmpty;

  /// The current [SingleMediumState] being played, or null if [isFinished].
  SingleMediumState get current => isFinished ? null : mediaState[currentIndex];

  /// The last [SingleMediumState] in this track.
  SingleMediumState get last => mediaState.last;

  /// Constructs a [MultiMediumTrackState] from a [SingleMedium] list.
  ///
  /// The [media] list must be non-null and not empty. Also [visualizable] must
  /// not be null and it indicates if the media should be displayed or not.
  /// If [onMediumFinished] is provided and non-null, it will be called when all
  /// the tracks finished playing.
  ///
  /// When the underlaying [SingleMediumState] are created, its
  /// [onMediumFinished] callback will be used to play the next media in the
  /// [media] list. If last medium finished playing, then this
  /// [onMediumFinished] will be called.
  @protected
  MultiMediumTrackState.internal({
    @required List<SingleMedium> media,
    @required bool visualizable,
    void Function(BuildContext context) onMediumFinished,
  })  : assert(media != null),
        assert(media.isNotEmpty),
        assert(visualizable != null),
        isVisualizable = visualizable {
    void _playNext(BuildContext context) {
      currentIndex++;
      if (isFinished) {
        onMediumFinished?.call(context);
      } else {
        play(context);
      }
      notifyListeners();
    }

    mediaState.addAll(media.map((medium) => createSingleMediumState(
          medium,
          isVisualizable: isVisualizable,
          onMediumFinished: _playNext,
        )));
  }

  /// Constructs an empty track state that [isFinished].
  @protected
  MultiMediumTrackState.empty()
      : isVisualizable = false,
        currentIndex = 1;

  /// Constructs a [MultiMediumTrackState] for a [MultiMediumTrack].
  ///
  /// [track] must be non-null. If [onMediumFinished] is provided and non-null,
  /// it will be called when all the tracks finished playing.
  MultiMediumTrackState.main({
    @required MultiMediumTrack track,
    void Function(BuildContext context) onMediumFinished,
  }) : this.internal(
          media: track?.media,
          visualizable: track is VisualizableMultiMediumTrack,
          onMediumFinished: onMediumFinished,
        );

  /// Constructs a [MultiMediumTrackState] for
  /// a [BackgroundMultiMediumTrack].
  ///
  /// If [track] is [NoTrack], an empty [MultiMediumTrackState] will be
  /// created, which is not visualizable and has already finished (and has an
  /// empty [mediaState]). Otherwise a regular [MultiMediumTrackState] will
  /// be constructed.
  ///
  /// [track] must be non-null.
  static MultiMediumTrackState background({
    @required BackgroundMultiMediumTrack track,
  }) =>
      track is NoTrack
          ? MultiMediumTrackState.empty()
          : MultiMediumTrackState.internal(
              media: track?.media,
              visualizable: track is VisualizableBackgroundMultiMediumTrack,
            );

  /// Plays the current [SingleMediumState].
  Future<void> play(BuildContext context) => current?.play(context);

  /// Pauses the current [SingleMediumState].
  Future<void> pause(BuildContext context) => current?.pause(context);

  /// Disposes all the [SingleMediumState] in [mediaState].
  @override
  Future<void> dispose() async {
    // FIXME: Will only report the first error and discard the next.
    await Future.forEach(mediaState, (SingleMediumState s) => s.dispose());
    super.dispose();
  }

  /// Initialize all (non-erroneous) [mediaState] states.
  ///
  /// If a state is already erroneous, it is because there was a problem
  /// creating the controller, so in this case it won't be initialized.
  ///
  /// If [startPlaying] is true, then [play()] will be called after the
  /// initialization is done.
  Future<void> initialize(BuildContext context,
      {bool startPlaying = false}) async {
    await Future.wait(mediaState.map((s) => s.initialize(context)));
    _allInitialized = true;
    notifyListeners();
    if (startPlaying) await play(context);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (isEmpty) {
      return '$runtimeType(empty)';
    }
    final initialized = isInitialized ? 'initialized, ' : '';
    final visualizable = isVisualizable ? 'visualizable' : 'audible';
    return '$runtimeType($initialized$visualizable, current: $currentIndex, '
        'media: ${mediaState.length})';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (isEmpty) {
      properties.add(FlagProperty('isEmpty', value: isEmpty, ifTrue: 'empty'));
      return;
    }
    properties
      ..add(FlagProperty('isInitialized',
          value: isInitialized, ifTrue: 'all tracks are initialized'))
      ..add(FlagProperty('visualizable',
          value: isVisualizable, ifTrue: 'visualizble', ifFalse: 'audible'))
      ..add(IntProperty('currentIndex', currentIndex))
      ..add(IntProperty('mediaState.length', mediaState.length));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[
        for (var i = 0; i < mediaState.length; i++)
          mediaState[i].toDiagnosticsNode(name: '$i')
      ];
}
