import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:lunofono_bundle/lunofono_bundle.dart' show MultiMedium;

import 'multi_medium_track_state.dart' show MultiMediumTrackState;
import 'playable_state.dart' show PlayableState;

/// A player state for playing a [MultiMedium] and notifying changes.
class MultiMediumState
    with ChangeNotifier, DiagnosticableTreeMixin
    implements PlayableState {
  /// The medium this state represents.
  @override
  final MultiMedium playable;

  /// The function that will be called when the main track finishes playing.
  @override
  final void Function(BuildContext context)? onFinished;

  /// The state of the main track.
  MultiMediumTrackState get mainTrackState => _mainTrackState;
  late final MultiMediumTrackState _mainTrackState;

  /// The state of the background track.
  MultiMediumTrackState get backgroundTrackState => _backgroundTrackState;
  late final MultiMediumTrackState _backgroundTrackState;

  /// True when all the media in both tracks is initialized.
  bool get isInitialized => _allInitialized;
  bool _allInitialized = false;

  /// Constructs a [MultiMediumState] for playing [multimedium].
  ///
  /// The [multimedium] must be non-null. If [onFinished]
  /// is provided, it will be called when the medium finishes playing the
  /// [multimedium.mainTrack].
  MultiMediumState(MultiMedium multimedium, {this.onFinished})
      : playable = multimedium {
    _mainTrackState = MultiMediumTrackState.main(
      track: multimedium.mainTrack,
      onFinished: _onMainTrackFinished,
    );
    _backgroundTrackState = MultiMediumTrackState.background(
      track: multimedium.backgroundTrack,
    );
  }

  void _onMainTrackFinished(BuildContext context) {
    backgroundTrackState.pause(context);
    onFinished?.call(context);
  }

  /// Initializes all media in both tracks.
  ///
  /// When initialization is done, [isInitialized] is set to true, it starts
  /// playing the first medium in both tracks and it notifies the listeners.
  ///
  /// If [startPlaying] is true, then [play()] will be called after the
  /// initialization is done (if there was no error).
  @override
  Future<void> initialize(BuildContext context,
      {bool startPlaying = false}) async {
    await Future.forEach([mainTrackState, backgroundTrackState],
        (MultiMediumTrackState ts) => ts.initialize(context));
    _allInitialized = true;
    notifyListeners();
    if (startPlaying) await play(context);
  }

  /// Starts or resumes playing this [MultiMediumState].
  ///
  /// It does nothing if it was already playing or finished.
  @override
  Future<void> play(BuildContext context) async {
    await mainTrackState.play(context);
    await backgroundTrackState.play(context);
  }

  /// Pauses the playing of this [MultiMediumState].
  ///
  /// It does nothing if it was already paused.
  @override
  Future<void> pause(BuildContext context) async {
    await mainTrackState.pause(context);
    await backgroundTrackState.pause(context);
  }

  /// Disposes both tracks.
  @override
  Future<void> dispose() async {
    await Future.wait(
        [mainTrackState.dispose(), backgroundTrackState.dispose()]);
    super.dispose();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final initialized = isInitialized ? 'initialized, ' : '';
    final main = 'main: $mainTrackState';
    final back = backgroundTrackState.isEmpty
        ? ''
        : ', background: $backgroundTrackState';
    return '$runtimeType($initialized$main$back)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('isInitialized',
          value: isInitialized, ifTrue: 'all tracks are initialized'))
      ..add(ObjectFlagProperty('onFinished', onFinished,
          ifPresent: 'notifies when all media finished'))
      ..add(DiagnosticsProperty('main', mainTrackState, expandableValue: true));
    if (backgroundTrackState.isNotEmpty) {
      properties.add(DiagnosticsProperty('background', backgroundTrackState,
          expandableValue: true));
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[
        mainTrackState.toDiagnosticsNode(name: 'main'),
        backgroundTrackState.toDiagnosticsNode(name: 'background'),
      ];
}
