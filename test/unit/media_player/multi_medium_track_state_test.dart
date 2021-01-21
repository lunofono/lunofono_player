@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart';
import 'package:lunofono_player/src/media_player/controller_registry.dart'
    show ControllerRegistry;
import 'package:lunofono_player/src/media_player/single_medium_controller.dart'
    show SingleMediumController, Size;

import 'package:lunofono_player/src/media_player/multi_medium_track_state.dart'
    show MultiMediumTrackState;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState, SingleMediumStateFactory;

import '../../util/foundation.dart' show FakeDiagnosticableMixin;

void main() {
  group('MultiMediumTrackState', () {
    final registry = ControllerRegistry();
    _registerControllers(registry);

    final _fakeSingleMediumStateFactory = _FakeSingleMediumStateFactory();

    final audibleMedium = _FakeAudibleSingleMedium(size: Size(0.0, 0.0));
    final audibleMedium2 = _FakeAudibleSingleMedium(size: Size(10.0, 12.0));
    final audibleMainTrack = _FakeAudibleMultiMediumTrack([audibleMedium]);
    final audibleBakgroundTrack =
        _FakeAudibleBackgroundMultiMediumTrack([audibleMedium]);

    group('constructor', () {
      group('.internal() asserts on', () {
        test('null media', () {
          expect(
            () => _TestMultiMediumTrackState(
              media: null,
              visualizable: true,
              registry: registry,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('empty media', () {
          expect(
            () => _TestMultiMediumTrackState(
              media: [],
              visualizable: true,
              registry: registry,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('null visualizable', () {
          expect(
            () => _TestMultiMediumTrackState(
              visualizable: null,
              media: audibleMainTrack.media,
              registry: registry,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('null registry', () {
          expect(
            () => _TestMultiMediumTrackState(
              registry: null,
              media: audibleMainTrack.media,
              visualizable: true,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('null singleMediumStateFactory', () {
          expect(
            () => _TestMultiMediumTrackState(
              singleMediumStateFactory: null,
              media: audibleMainTrack.media,
              visualizable: true,
              registry: registry,
            ),
            throwsAssertionError,
          );
        });
      });

      group('.main() asserts on', () {
        test('null track', () {
          expect(
            () => MultiMediumTrackState.main(
              track: null,
              registry: registry,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('null registry', () {
          expect(
            () => MultiMediumTrackState.main(
              registry: null,
              track: audibleMainTrack,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('null singleMediumStateFactory', () {
          expect(
            () => MultiMediumTrackState.main(
              singleMediumStateFactory: null,
              track: audibleMainTrack,
              registry: registry,
            ),
            throwsAssertionError,
          );
        });
      });

      group('.background() asserts on', () {
        test('null track', () {
          expect(
            () => MultiMediumTrackState.background(
              track: null,
              registry: registry,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('null registry', () {
          expect(
            () => MultiMediumTrackState.background(
              registry: null,
              track: audibleBakgroundTrack,
              singleMediumStateFactory: _fakeSingleMediumStateFactory,
            ),
            throwsAssertionError,
          );
        });
        test('null singleMediumStateFactory', () {
          expect(
            () => MultiMediumTrackState.background(
              singleMediumStateFactory: null,
              track: audibleBakgroundTrack,
              registry: registry,
            ),
            throwsAssertionError,
          );
        });
      });

      void testContructorWithMedia(
          MultiMediumTrackState state, List<SingleMedium> media) {
        expect(state.isVisualizable, isFalse);
        expect(state.mediaState.length, media.length);
        expect(state.currentIndex, 0);
        expect(state.isFinished, isFalse);
        expect(state.isEmpty, isFalse);
        expect(state.isNotEmpty, isTrue);
        expect(state.current, state.mediaState.first);
        expect(state.last, state.mediaState.last);
        // The current/fist one is OK but uninitialized
        expect(state.current.controller, isNotNull);
        expect(state.current.isInitialized, isFalse);
        expect(state.current.isErroneous, isFalse);
        // The last one is an unregistered medium, so it is erroneous
        expect(state.last.controller, isNull);
        expect(state.last.isInitialized, isFalse);
        expect(state.last.isErroneous, isTrue);
      }

      test('.main() create mediaState correctly', () {
        final track = _FakeAudibleMultiMediumTrack([
          audibleMedium,
          _FakeUnregisteredAudibleSingleMedium(),
        ]);
        final state = MultiMediumTrackState.main(
          track: track,
          registry: registry,
          singleMediumStateFactory: _fakeSingleMediumStateFactory,
        );
        testContructorWithMedia(state, track.media);
      });

      test('.background() create mediaState correctly', () {
        final track = _FakeAudibleBackgroundMultiMediumTrack([
          audibleMedium,
          _FakeUnregisteredAudibleSingleMedium(),
        ]);
        final state = MultiMediumTrackState.background(
          track: track,
          registry: registry,
          singleMediumStateFactory: _fakeSingleMediumStateFactory,
        );
        testContructorWithMedia(state, track.media);
      });

      test('.background() create empty track with NoTrack', () {
        final track = NoTrack();
        final state = MultiMediumTrackState.background(
          track: track,
          registry: registry,
          singleMediumStateFactory: _fakeSingleMediumStateFactory,
        );
        expect(state.isVisualizable, isFalse);
        expect(state.isFinished, isTrue);
        expect(state.isEmpty, isTrue);
        expect(state.isNotEmpty, isFalse);
      });
    });

    test('initializeAll() initializes media states', () async {
      final track = _FakeAudibleMultiMediumTrack([
        audibleMedium,
        _FakeUnregisteredAudibleSingleMedium(),
      ]);
      final state = MultiMediumTrackState.main(
        track: track,
        registry: registry,
        singleMediumStateFactory: _fakeSingleMediumStateFactory,
      );
      await state.initializeAll(_FakeContext());
      expect(state.isFinished, isFalse);
      expect(state.current.isInitialized, isTrue);
      expect(state.current.isErroneous, isFalse);
      expect(state.current.asFake.calls, ['initialize']);
      expect(state.last.isInitialized, isFalse);
      expect(state.last.isErroneous, isTrue);
    });

    test("play() doesn't end with state without controller", () async {
      final track = _FakeAudibleMultiMediumTrack([
        audibleMedium,
        _FakeUnregisteredAudibleSingleMedium(),
      ]);
      final state = MultiMediumTrackState.main(
        track: track,
        registry: registry,
        singleMediumStateFactory: _fakeSingleMediumStateFactory,
      );

      await state.initializeAll(_FakeContext());
      var first = state.current;

      await state.playCurrent(_FakeContext());
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      expect(state.current.asFake.calls, ['initialize', 'play']);
      expect(state.last.isInitialized, isFalse);
      expect(state.last.isErroneous, isTrue);

      // after the current track finished, the next should be played, but since
      // it is erroneous without controller, nothing happens (we'll have to
      // implement a default or error SingleMediumController eventually)
      state.current.controller.onMediumFinished(_FakeContext());
      expect(first.asFake.calls, ['initialize', 'play']);
      expect(state.isFinished, isFalse);
      expect(state.current, same(state.last));
      expect(state.last.isInitialized, isFalse);
      expect(state.last.isErroneous, isTrue);
    });

    test('play-pause-next cycle works without onMediumFinished', () async {
      final track = _FakeAudibleMultiMediumTrack([
        audibleMedium,
        audibleMedium2,
      ]);
      final state = MultiMediumTrackState.main(
        track: track,
        registry: registry,
        singleMediumStateFactory: _fakeSingleMediumStateFactory,
      );

      await state.initializeAll(_FakeContext());
      expect(state.current.asFake.calls, ['initialize']);
      expect(state.last.asFake.calls, ['initialize']);
      final first = state.current;

      await state.playCurrent(_FakeContext());
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      expect(state.current.asFake.calls, ['initialize', 'play']);
      expect(state.last.asFake.calls, ['initialize']);

      await state.pauseCurrent(_FakeContext());
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      expect(state.current.asFake.calls, ['initialize', 'play', 'pause']);
      expect(state.last.asFake.calls, ['initialize']);

      await state.playCurrent(_FakeContext());
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      expect(
          state.current.asFake.calls, ['initialize', 'play', 'pause', 'play']);
      expect(state.last.asFake.calls, ['initialize']);

      // after the current track finished, the next one is played
      state.current.controller.onMediumFinished(_FakeContext());
      expect(state.isFinished, isFalse);
      expect(state.current, same(state.last));
      expect(first.asFake.calls, ['initialize', 'play', 'pause', 'play']);
      expect(state.last.asFake.calls, ['initialize', 'play']);

      // after the last track finished, the controller should be finished
      state.current.controller.onMediumFinished(_FakeContext());
      expect(state.isFinished, isTrue);
      expect(state.current, isNull);
      expect(first.asFake.calls, ['initialize', 'play', 'pause', 'play']);
      expect(state.last.asFake.calls, ['initialize', 'play']);

      // If we dispose the controller,
      await state.dispose();
      expect(first.asFake.calls,
          ['initialize', 'play', 'pause', 'play', 'dispose']);
      expect(state.last.asFake.calls, ['initialize', 'play', 'dispose']);
    });

    test('onMediumFinished is called', () async {
      final track =
          _FakeAudibleMultiMediumTrack([audibleMedium, audibleMedium2]);

      var finished = false;

      final state = MultiMediumTrackState.main(
          track: track,
          registry: registry,
          singleMediumStateFactory: _fakeSingleMediumStateFactory,
          onMediumFinished: (BuildContext context) => finished = true);

      await state.initializeAll(_FakeContext());
      expect(finished, isFalse);
      // plays first
      await state.playCurrent(_FakeContext());
      expect(finished, isFalse);
      // ends first, second starts playing
      state.current.controller.onMediumFinished(_FakeContext());
      expect(finished, isFalse);
      // ends second, onMediumFinished should be called
      state.current.controller.onMediumFinished(_FakeContext());
      expect(finished, isTrue);
      expect(state.isFinished, isTrue);
    });

    test('listening for updates work', () async {
      final track =
          _FakeAudibleMultiMediumTrack([audibleMedium, audibleMedium2]);
      final state = MultiMediumTrackState.main(
          track: track,
          registry: registry,
          singleMediumStateFactory: _fakeSingleMediumStateFactory);

      var notifyCalls = 0;
      state.addListener(() => notifyCalls += 1);

      await state.initializeAll(_FakeContext());
      expect(notifyCalls, 0);
      // plays first
      await state.playCurrent(_FakeContext());
      expect(notifyCalls, 0);
      // ends first, second starts playing
      state.current.controller.onMediumFinished(_FakeContext());
      expect(notifyCalls, 1);
      // ends second, onMediumFinished should be called
      state.current.controller.onMediumFinished(_FakeContext());
      expect(notifyCalls, 2);
      await state.pauseCurrent(_FakeContext());
      expect(notifyCalls, 2);
      await state.dispose();
      expect(notifyCalls, 2);
    });

    test('toString()', () async {
      var state = MultiMediumTrackState.main(
        track: _FakeAudibleMultiMediumTrack([audibleMedium, audibleMedium2]),
        registry: registry,
        singleMediumStateFactory: _fakeSingleMediumStateFactory,
      );

      expect(state.toString(),
          'MultiMediumTrackState(audible, current: 0, media: 2)');
      await state.initializeAll(_FakeContext());
      expect(state.toString(),
          'MultiMediumTrackState(audible, current: 0, media: 2)');

      state = MultiMediumTrackState.background(
        track: const NoTrack(),
        registry: registry,
      );
      expect(
        MultiMediumTrackState.background(
          track: const NoTrack(),
          registry: registry,
          singleMediumStateFactory: _fakeSingleMediumStateFactory,
        ).toString(),
        'MultiMediumTrackState(empty)',
      );
    });

    test('debugFillProperties() and debugDescribeChildren()', () async {
      final identityHash = RegExp(r'#[0-9a-f]{5}');

      // XXX: No fake singleMediumStateFactory here because we would have to
      // fake all the diagnostics class hierarchy too, which is overkill.
      expect(
        MultiMediumTrackState.main(
          track: _FakeAudibleMultiMediumTrack([audibleMedium, audibleMedium2]),
          registry: registry,
        ).toStringDeep().replaceAll(identityHash, ''),
        'MultiMediumTrackState\n'
        ' │ audible\n'
        ' │ currentIndex: 0\n'
        ' │ mediaState.length: 2\n'
        ' │\n'
        ' ├─0: SingleMediumState\n'
        ' │   medium: Instance of \'_FakeAudibleSingleMedium\'\n'
        ' │   size: <uninitialized>\n'
        ' │\n'
        ' └─1: SingleMediumState\n'
        '     medium: Instance of \'_FakeAudibleSingleMedium\'\n'
        '     size: <uninitialized>\n'
        '',
      );
      expect(
        MultiMediumTrackState.background(
          track: const NoTrack(),
          registry: registry,
        ).toStringDeep().replaceAll(identityHash, ''),
        'MultiMediumTrackState\n'
        '   empty\n'
        '',
      );
    });
  });
}

class _TestMultiMediumTrackState extends MultiMediumTrackState {
  _TestMultiMediumTrackState({
    @required List<SingleMedium> media,
    @required bool visualizable,
    @required ControllerRegistry registry,
    void Function(BuildContext context) onMediumFinished,
    SingleMediumStateFactory singleMediumStateFactory,
  }) : super.internal(
            media: media,
            visualizable: visualizable,
            registry: registry,
            onMediumFinished: onMediumFinished,
            singleMediumStateFactory: singleMediumStateFactory);
}

class _FakeContext extends Fake implements BuildContext {}

abstract class _FakeSingleMedium extends Fake implements SingleMedium {
  final Size size;
  final dynamic error;
  final Key widgetKey;
  _FakeSingleMedium({
    this.size,
    this.error,
    Key widgetKey,
  })  : assert(error != null && size == null || error == null && size != null),
        widgetKey = widgetKey ?? GlobalKey(debugLabel: 'widgetKey');

  @override
  Uri get resource => Uri.parse('medium.resource');
}

class _FakeAudibleSingleMedium extends _FakeSingleMedium implements Audible {
  _FakeAudibleSingleMedium({
    Size size,
    dynamic error,
    Key widgetKey,
  }) : super(size: size, error: error, widgetKey: widgetKey);
}

class _FakeAudibleMultiMediumTrack extends Fake
    implements AudibleMultiMediumTrack {
  @override
  final List<SingleMedium> media;
  _FakeAudibleMultiMediumTrack(this.media);
}

class _FakeAudibleBackgroundMultiMediumTrack extends Fake
    implements AudibleBackgroundMultiMediumTrack {
  @override
  final List<SingleMedium> media;
  _FakeAudibleBackgroundMultiMediumTrack(this.media);
}

class _FakeUnregisteredAudibleSingleMedium extends Fake
    implements SingleMedium, Audible {
  @override
  Uri get resource => Uri.parse('medium.resource');
}

void _registerControllers(ControllerRegistry registry) {
  SingleMediumController createController(SingleMedium medium,
      {void Function(BuildContext) onMediumFinished}) {
    final fakeMedium = medium as _FakeSingleMedium;
    final c = _FakeSingleMediumController(fakeMedium,
        onMediumFinished: onMediumFinished);
    return c;
  }

  registry.register(_FakeAudibleSingleMedium, createController);
}

class _FakeSingleMediumStateFactory extends Fake
    implements SingleMediumStateFactory {
  @override
  SingleMediumState good(SingleMediumController controller,
          {bool isVisualizable = true}) =>
      _FakeSingleMediumState(
          medium: controller.medium,
          controller: controller as _FakeSingleMediumController,
          isVisualizable: isVisualizable);

  @override
  SingleMediumState bad(SingleMedium medium, dynamic error) =>
      _FakeSingleMediumState(medium: medium, error: error);
}

class _FakeSingleMediumState extends Fake
    with FakeDiagnosticableMixin
    implements SingleMediumState {
  @override
  SingleMedium medium;

  @override
  final _FakeSingleMediumController controller;

  @override
  final bool isVisualizable;

  @override
  Size size;

  @override
  dynamic error;

  _FakeSingleMediumState(
      {this.medium, this.controller, this.error, this.isVisualizable});

  final calls = <String>[];

  Future<void> _errorOrOk(String name, [Size size]) async {
    calls.add(name);
    if (controller?.medium?.error != null) {
      throw controller.medium.error;
    }
    if (size != null) {
      this.size = size;
    }
  }

  @override
  bool get isInitialized => size != null;

  @override
  bool get isErroneous => error != null;

  @override
  Future<void> initialize(BuildContext context) =>
      _errorOrOk('initialize', controller?.medium?.size);

  @override
  Future<void> play(BuildContext context) => _errorOrOk('play');

  @override
  Future<void> pause(BuildContext context) => _errorOrOk('pause');

  @override
  Future<void> dispose() => _errorOrOk('dispose');

  @override
  Widget build(BuildContext context) {
    calls.add('build');
    return Container(key: controller.widgetKey);
  }
}

class _FakeSingleMediumController extends Fake
    implements SingleMediumController {
  @override
  _FakeSingleMedium medium;
  @override
  final void Function(BuildContext) onMediumFinished;
  _FakeSingleMediumController(
    this.medium, {
    this.onMediumFinished,
  }) : assert(medium != null);
}

extension _AsFakeSingleMediumState on SingleMediumState {
  _FakeSingleMediumState get asFake => this as _FakeSingleMediumState;
}
