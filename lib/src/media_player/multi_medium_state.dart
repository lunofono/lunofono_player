import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext, Widget;

import 'package:meta/meta.dart' show protected;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show
        MultiMedium,
        SingleMedium,
        NoTrack,
        MultiMediumTrack,
        BackgroundMultiMediumTrack,
        VisualizableMultiMediumTrack,
        VisualizableBackgroundMultiMediumTrack;

import 'controller_registry.dart' show ControllerRegistry;
import 'single_medium_controller.dart' show SingleMediumController, Size;

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

/// A player state for playing a [MultiMediumTrack] and notifying changes.
class MultiMediumTrackState with ChangeNotifier, DiagnosticableTreeMixin {
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
  /// [registry] should also be non-null and it will be used to create the
  /// [SingleMediumController] instances. If [onMediumFinished] is provided and
  /// non-null, it will be called when all the tracks finished playing.
  ///
  /// When the underlaying [SingleMediumController] is created, its
  /// `onMediumFinished` callback will be used to play the next media in the
  /// [media] list. If last medium finished playing, then this
  /// [onMediumFinished] will be called.
  ///
  /// If a [singleMediumStateFactory] is specified, it will be used to create
  /// the [mediaState] elements, otherwise a default const
  /// [SingleMediumStateFactory()] will be used.
  @protected
  MultiMediumTrackState.internal({
    @required List<SingleMedium> media,
    @required bool visualizable,
    @required ControllerRegistry registry,
    void Function(BuildContext context) onMediumFinished,
    SingleMediumStateFactory singleMediumStateFactory =
        const SingleMediumStateFactory(),
  })  : assert(media != null),
        assert(media.isNotEmpty),
        assert(visualizable != null),
        assert(registry != null),
        assert(singleMediumStateFactory != null),
        isVisualizable = visualizable {
    for (var i = 0; i < media.length; i++) {
      final medium = media[i];
      final create = registry.getFunction(medium);
      if (create == null) {
        mediaState.add(singleMediumStateFactory.bad(medium,
            'Unsupported type ${medium.runtimeType} for ${medium.resource}'));
        continue;
      }

      final controller = create(medium, onMediumFinished: (context) {
        currentIndex++;
        if (isFinished) {
          onMediumFinished?.call(context);
        } else {
          playCurrent(context);
        }
        notifyListeners();
      });
      mediaState.add(singleMediumStateFactory.good(controller));
    }
  }

  /// Constructs an empty track state that [isFinished].
  @protected
  MultiMediumTrackState.empty()
      : isVisualizable = false,
        currentIndex = 1;

  /// Constructs a [MultiMediumTrackState] for a [MultiMediumTrack].
  ///
  /// [track] and [registry] must be non-null. If [onMediumFinished] is
  /// provided and non-null, it will be called when all the tracks finished
  /// playing.
  MultiMediumTrackState.main({
    @required MultiMediumTrack track,
    @required ControllerRegistry registry,
    void Function(BuildContext context) onMediumFinished,
    SingleMediumStateFactory singleMediumStateFactory =
        const SingleMediumStateFactory(),
  }) : this.internal(
          media: track?.media,
          visualizable: track is VisualizableMultiMediumTrack,
          registry: registry,
          onMediumFinished: onMediumFinished,
          singleMediumStateFactory: singleMediumStateFactory,
        );

  /// Constructs a [MultiMediumTrackState] for
  /// a [BackgroundMultiMediumTrack].
  ///
  /// If [track] is [NoTrack], an empty [MultiMediumTrackState] will be
  /// created, which is not visualizable and has already finished (and has an
  /// empty [mediaState]). Otherwise a regular [MultiMediumTrackState] will
  /// be constructed.
  ///
  /// [track] and [registry] must be non-null.
  static MultiMediumTrackState background({
    @required BackgroundMultiMediumTrack track,
    @required ControllerRegistry registry,
    SingleMediumStateFactory singleMediumStateFactory =
        const SingleMediumStateFactory(),
  }) =>
      track is NoTrack
          ? MultiMediumTrackState.empty()
          : MultiMediumTrackState.internal(
              media: track?.media,
              visualizable: track is VisualizableBackgroundMultiMediumTrack,
              registry: registry,
              singleMediumStateFactory: singleMediumStateFactory,
            );

  /// Plays the current [SingleMediumState].
  Future<void> playCurrent(BuildContext context) => current?.play(context);

  /// Pauses the current [SingleMediumState].
  Future<void> pauseCurrent(BuildContext context) => current?.pause(context);

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
  Future<void> initializeAll(BuildContext context) => Future.wait(mediaState
      .where((s) => !s.isErroneous)
      .map((s) => s.initialize(context)));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (isEmpty) {
      return '$runtimeType(empty)';
    }
    final visualizable = isVisualizable ? 'visualizable' : 'audible';
    return '$runtimeType($visualizable, current: $currentIndex, '
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

/// Factory to construct [SingleMediumState].
///
/// This is used only for testing.
class SingleMediumStateFactory {
  const SingleMediumStateFactory();
  SingleMediumState good(SingleMediumController controller) =>
      SingleMediumState(controller);
  SingleMediumState bad(SingleMedium medium, dynamic error) =>
      SingleMediumState.erroneous(medium, error);
}

/// A state of a medium on a [MultiMediumTrack].
///
/// The medium can have 3 states:
/// 1. Uninitialized, represented by [error] and [size] being null.
/// 2. Successfully initialized: represented by [size] being non-null.
/// 3. Erroneous: represented by [error] being non-null. The error can occur
///    while constructing the controller, [initialize()]ing, [play()]ing,
///    [pause()]ing, etc. Having both [error] and [size] non-null can happen if
///    the error happens after initialization is successful.
class SingleMediumState with DiagnosticableTreeMixin {
  /// The medium this state tracks.
  final SingleMedium medium;

  /// The player controller used to control this medium.
  final SingleMediumController controller;

  /// The last error that happened while using this medium.
  ///
  /// It can be null, meaning there was no error so far.
  dynamic error;

  /// The size of this medium.
  ///
  /// The size is only available after [initialize()] is successful, so if this
  /// is non-null, it means the [controller] for this medium was initialized
  /// successfully.
  Size size;

  /// True if there was an error ([error] is non-null).
  bool get isErroneous => error != null;

  /// True if it was successfully initialized ([size] != null).
  ///
  /// Even if it is initialized successfully, there could be an error after
  /// that, so [isErroneous] should be always checked first before assuming this
  /// medium is in a good state.
  bool get isInitialized => size != null;

  /// The Key used by the widget produced by this [controller].
  Key get widgetKey => controller?.widgetKey;

  /// Constructs a new state using a [controller].
  ///
  /// The  [controller] must be non-null, [medium] will be set to
  /// [controller.medium].
  SingleMediumState(this.controller)
      : assert(controller != null),
        medium = controller.medium;

  /// Constructs a new erroneous state.
  ///
  /// This is typically used when a [controller] couldn't be created. The
  /// [medium] and [error] must be non-null and [controller] will be set to
  /// null.
  SingleMediumState.erroneous(this.medium, this.error)
      : assert(medium != null),
        assert(error != null),
        controller = null;

  /// Initializes this medium's [controller].
  ///
  /// Sets [size] on success, and [error] on error. Should be called only once
  /// and before invoking any other method of this class.
  Future<void> initialize(BuildContext context) {
    assert(size == null);
    return controller.initialize(context).then<void>((size) {
      this.size = size;
    }).catchError((dynamic error) => this.error = error);
  }

  /// Plays this medium using [controller].
  ///
  /// Sets [error] on error.
  // FIXME: For now we show the error forever, eventually we probably have to
  // show the error only for some time and then move to the next medium in the
  // track.
  Future<void> play(BuildContext context) => controller
      ?.play(context)
      ?.catchError((dynamic error) => this.error = error);

  /// Pauses this medium using [controller].
  ///
  /// Sets [error] on error.
  // FIXME: For now we ignore pause() when isErroneous, eventually we probably
  // have to show the error only for some time and then move to the next medium
  // in the track.
  Future<void> pause(BuildContext context) => controller
      ?.pause(context)
      ?.catchError((dynamic error) => this.error = error);

  /// Disposes this medium's [controller].
  ///
  /// Sets [error] on error. This state can't be used anymore after this method
  /// is called, except for checking for [error].
  Future<void> dispose() =>
      controller?.dispose()?.catchError((dynamic error) => this.error = error);

  /// Builds the widget to display this controller.
  Widget build(BuildContext context) => controller.build(context);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final sizeStr =
        size == null ? 'uninitialized' : '${size.width}x${size.height}';
    final errorStr = error == null ? '' : 'error: $error';
    return '$runtimeType($sizeStr$errorStr)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('medium', medium))
      ..add(DiagnosticsProperty<dynamic>('error', error, defaultValue: null))
      ..add(DiagnosticsProperty('size',
          size == null ? '<uninitialized>' : '${size.width}x${size.height}'));
  }
}
