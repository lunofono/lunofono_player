import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:lunofono_bundle/lunofono_bundle.dart' show MultiMedium;

import 'multi_medium_track_state.dart' show MultiMediumTrackState;

/// A player state for playing a [MultiMedium] and notifying changes.
class MultiMediumState with ChangeNotifier, DiagnosticableTreeMixin {
  MultiMediumTrackState _mainTrackState;

  /// The state of the main track.
  MultiMediumTrackState get mainTrackState => _mainTrackState;

  MultiMediumTrackState _backgroundTrackState;

  /// The state of the background track.
  MultiMediumTrackState get backgroundTrackState => _backgroundTrackState;

  /// True when all the media in both tracks is initialized.
  bool get isInitialized => _allInitialized;
  bool _allInitialized = false;

  /// The function that will be called when the main track finishes playing.
  final void Function(BuildContext context) onMediumFinished;

  /// Constructs a [MultiMediumState] for playing [multimedium].
  ///
  /// The [multimedium] must be non-null. If [onMediumFinished]
  /// is provided, it will be called when the medium finishes playing the
  /// [multimedium.mainTrack].
  MultiMediumState(MultiMedium multimedium, {this.onMediumFinished})
      : assert(multimedium != null) {
    _mainTrackState = MultiMediumTrackState.main(
      track: multimedium.mainTrack,
      onMediumFinished: _onMainTrackFinished,
    );
    _backgroundTrackState = MultiMediumTrackState.background(
      track: multimedium.backgroundTrack,
    );
  }

  void _onMainTrackFinished(BuildContext context) {
    backgroundTrackState.pause(context);
    onMediumFinished?.call(context);
  }

  /// Initializes all media in both tracks.
  ///
  /// When initialization is done, [isInitialized] is set to true, it starts
  /// playing the first medium in both tracks and it notifies the listeners.
  ///
  /// If [startPlaying] is true, then [play()] will be called after the
  /// initialization is done (if there was no error).
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
  Future<void> play(BuildContext context) async {
    await mainTrackState.play(context);
    await backgroundTrackState.play(context);
  }

  /// Pauses the playing of this [MultiMediumState].
  ///
  /// It does nothing if it was already paused.
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
      ..add(ObjectFlagProperty('onMediumFinished', onMediumFinished,
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
