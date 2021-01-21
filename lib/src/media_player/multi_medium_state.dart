import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:lunofono_bundle/lunofono_bundle.dart' show MultiMedium;

import 'controller_registry.dart' show ControllerRegistry;
import 'multi_medium_track_state.dart' show MultiMediumTrackState;

/// A player state for playing a [MultiMedium] and notifying changes.
class MultiMediumState with ChangeNotifier, DiagnosticableTreeMixin {
  MultiMediumTrackState _mainTrackState;

  /// The state of the main track.
  MultiMediumTrackState get mainTrackState => _mainTrackState;

  MultiMediumTrackState _backgroundTrackState;

  /// The state of the background track.
  MultiMediumTrackState get backgroundTrackState => _backgroundTrackState;

  bool _allInitialized = false;

  /// True when all the media in both tracks is initialized.
  bool get allInitialized => _allInitialized;

  /// The function that will be called when the main track finishes playing.
  final void Function(BuildContext context) onMediumFinished;

  /// Constructs a [MultiMediumState] for playing [multimedium].
  ///
  /// Both [multimedium] and [registry] must be non-null. If [onMediumFinished]
  /// is provided, it will be called when the medium finishes playing the
  /// [multimedium.mainTrack].
  MultiMediumState(MultiMedium multimedium, ControllerRegistry registry,
      {this.onMediumFinished})
      : assert(multimedium != null),
        assert(registry != null) {
    _mainTrackState = MultiMediumTrackState.main(
      track: multimedium.mainTrack,
      registry: registry,
      onMediumFinished: _onMainTrackFinished,
    );
    _backgroundTrackState = MultiMediumTrackState.background(
      track: multimedium.backgroundTrack,
      registry: registry,
    );
  }

  void _onMainTrackFinished(BuildContext context) {
    backgroundTrackState.pauseCurrent(context);
    onMediumFinished?.call(context);
  }

  /// Initializes all media in both tracks.
  ///
  /// When initialization is done, [allInitialized] is set to true, it starts
  /// playing the first medium in both tracks and it notifies the listeners.
  Future<void> initialize(BuildContext context) => Future.forEach(
          [mainTrackState, backgroundTrackState],
          (MultiMediumTrackState ts) => ts.initializeAll(context)).then<void>(
        (dynamic _) {
          _allInitialized = true;
          mainTrackState.playCurrent(context);
          backgroundTrackState.playCurrent(context);
          notifyListeners();
        },
      );

  /// Disposes both tracks.
  @override
  Future<void> dispose() async {
    await Future.wait(
        [mainTrackState.dispose(), backgroundTrackState.dispose()]);
    super.dispose();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final initialized = allInitialized ? 'initialized, ' : '';
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
      ..add(FlagProperty('allInitialized',
          value: allInitialized, ifTrue: 'all tracks are initialized'))
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
