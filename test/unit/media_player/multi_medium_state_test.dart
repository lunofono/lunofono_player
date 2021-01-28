@Tags(['unit', 'player'])

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart';
import 'package:lunofono_player/src/media_player/controller_registry.dart'
    show ControllerRegistry;
import 'package:lunofono_player/src/media_player/single_medium_controller.dart'
    show SingleMediumController, Size;

import 'package:lunofono_player/src/media_player/multi_medium_state.dart'
    show MultiMediumState;

// XXX: This test should ideally fake the ControllerRegistry, but we can't do so
// now because of a very obscure problem with the dart compiler/flutter test
// driver. For details please see this issue:
// https://github.com/flutter/flutter/issues/65324
void main() {
  group('MultiMediumState', () {
    final registry = ControllerRegistry();
    _registerControllers(registry);

    final audibleMedium =
        _FakeAudibleSingleMedium('audible', size: Size(0.0, 0.0));
    final audibleMedium2 =
        _FakeAudibleSingleMedium('visualizable', size: Size(10.0, 12.0));

    final audibleMultiMedium = MultiMedium(
        AudibleMultiMediumTrack(<Audible>[audibleMedium, audibleMedium2]));

    final multiMedium = MultiMedium(
      AudibleMultiMediumTrack(<Audible>[audibleMedium, audibleMedium2]),
      backgroundTrack: _FakeVisualizableBackgroundMultiMediumTrack(
        <Visualizable>[
          _FakeVisualizableSingleMedium('visualizable1', size: Size(1.0, 1.0)),
          _FakeVisualizableSingleMedium('visualizable2', size: Size(2.0, 2.0)),
        ],
      ),
    );

    group('constructor', () {
      group('asserts on', () {
        test('null multimedium', () {
          expect(() => MultiMediumState(null, registry), throwsAssertionError);
        });
        test('null registry', () {
          expect(() => MultiMediumState(audibleMultiMedium, null),
              throwsAssertionError);
        });
      });
    });

    test('play/pause cycle works with main track only', () async {
      var finished = false;
      final state = MultiMediumState(audibleMultiMedium, registry,
          onMediumFinished: (context) => finished = true);
      expect(finished, isFalse);
      expect(state.allInitialized, isFalse);
      expect(state.backgroundTrackState, isEmpty);
      state.mainTrackState.mediaState
          .forEach((s) => expect(s.controller.asFake.calls, isEmpty));

      var notifyCalled = false;
      final checkInitialized = () {
        expect(finished, isFalse);
        expect(state.allInitialized, isTrue);
        expect(state.backgroundTrackState, isEmpty);
        expect(state.mainTrackState.current.controller.asFake.calls,
            ['initialize', 'play']);
        expect(
            state.mainTrackState.last.controller.asFake.calls, ['initialize']);
        notifyCalled = true;
      };
      state.addListener(checkInitialized);

      await state.initialize(_FakeContext());
      expect(notifyCalled, isTrue);
      final first = state.mainTrackState.current;

      // Pause
      state.removeListener(checkInitialized);
      notifyCalled = false;
      await state.pause(_FakeContext());
      expect(finished, isFalse);
      expect(state.allInitialized, isTrue);
      expect(state.backgroundTrackState, isEmpty);
      expect(state.mainTrackState.current.controller.asFake.calls,
          ['initialize', 'play', 'pause']);
      expect(state.mainTrackState.last.controller.asFake.calls, ['initialize']);
      notifyCalled = true;
      expect(notifyCalled, isTrue);
      final updateNotifyCalled = () => notifyCalled = true;
      state.addListener(updateNotifyCalled);

      // Play
      notifyCalled = false;
      await state.play(_FakeContext());
      expect(finished, isFalse);
      expect(state.allInitialized, isTrue);
      expect(state.backgroundTrackState, isEmpty);
      expect(state.mainTrackState.current.controller.asFake.calls,
          ['initialize', 'play', 'pause', 'play']);
      expect(state.mainTrackState.last.controller.asFake.calls, ['initialize']);
      notifyCalled = true;
      expect(notifyCalled, isTrue);
      state.addListener(updateNotifyCalled);

      // First medium finishes
      notifyCalled = false;
      state.mainTrackState.current.controller.onMediumFinished(_FakeContext());
      expect(notifyCalled, isFalse);

      state.removeListener(updateNotifyCalled);

      // Second (and last) medium finishes, onMediumFinished should be called.
      state.mainTrackState.current.controller.onMediumFinished(_FakeContext());
      expect(notifyCalled, isFalse);
      expect(finished, isTrue);
      expect(state.allInitialized, isTrue);
      expect(state.backgroundTrackState, isEmpty);
      expect(state.mainTrackState.current, isNull);
      expect(first.controller.asFake.calls,
          ['initialize', 'play', 'pause', 'play']);
      expect(state.mainTrackState.last.controller.asFake.calls,
          ['initialize', 'play']);

      await state.dispose();
      expect(first.controller.asFake.calls,
          ['initialize', 'play', 'pause', 'play', 'dispose']);
      expect(state.mainTrackState.last.controller.asFake.calls,
          ['initialize', 'play', 'dispose']);
    });

    group('play cycle works with main and background track', () {
      bool finished;
      int notifyCalls;

      setUp(() {
        finished = false;
        notifyCalls = 0;
      });

      void updateNotifyCalled() => notifyCalls++;

      Future<MultiMediumState> testInitialize() async {
        final state = MultiMediumState(multiMedium, registry,
            onMediumFinished: (context) => finished = true);
        expect(finished, isFalse);
        expect(state.allInitialized, isFalse);
        expect(state.backgroundTrackState, isNotEmpty);
        state.mainTrackState.mediaState
            .forEach((s) => expect(s.controller.asFake.calls, isEmpty));
        state.backgroundTrackState.mediaState
            .forEach((s) => expect(s.controller.asFake.calls, isEmpty));

        var notifyCalled = false;
        final checkInitialized = () {
          expect(finished, isFalse);
          expect(state.allInitialized, isTrue);
          expect(state.backgroundTrackState, isNotEmpty);
          expect(state.mainTrackState.current.controller.asFake.calls,
              ['initialize', 'play']);
          expect(state.mainTrackState.last.controller.asFake.calls,
              ['initialize']);
          expect(state.backgroundTrackState.current.controller.asFake.calls,
              ['initialize', 'play']);
          expect(state.backgroundTrackState.last.controller.asFake.calls,
              ['initialize']);
          notifyCalled = true;
        };
        state.addListener(checkInitialized);

        await state.initialize(_FakeContext());
        expect(notifyCalled, isTrue);

        state.removeListener(checkInitialized);
        return state;
      }

      void testFirstMediaPlayed(MultiMediumState state) async {
        final firstMain = state.mainTrackState.current;
        final firstBack = state.backgroundTrackState.current;

        // First main medium finishes
        state.mainTrackState.current.controller
            .onMediumFinished(_FakeContext());
        expect(notifyCalls, 0);
        expect(state.mainTrackState.current, same(state.mainTrackState.last));
        expect(firstMain.controller.asFake.calls, ['initialize', 'play']);
        expect(state.mainTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);
        expect(state.backgroundTrackState.current, same(firstBack));
        expect(firstBack.controller.asFake.calls, ['initialize', 'play']);
        expect(state.backgroundTrackState.last.controller.asFake.calls,
            ['initialize']);

        // First background medium finishes
        state.backgroundTrackState.current.controller
            .onMediumFinished(_FakeContext());
        expect(notifyCalls, 0);
        expect(state.mainTrackState.current, same(state.mainTrackState.last));
        expect(firstMain.controller.asFake.calls, ['initialize', 'play']);
        expect(state.mainTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);
        expect(state.backgroundTrackState.current,
            same(state.backgroundTrackState.last));
        expect(firstBack.controller.asFake.calls, ['initialize', 'play']);
        expect(state.backgroundTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);
      }

      test('when background track finishes first', () async {
        final state = await testInitialize();
        final firstMain = state.mainTrackState.current;
        final firstBack = state.backgroundTrackState.current;

        state.addListener(updateNotifyCalled);

        await testFirstMediaPlayed(state);

        // Second background medium finishes
        state.backgroundTrackState.current.controller
            .onMediumFinished(_FakeContext());
        expect(notifyCalls, 0);
        expect(state.mainTrackState.current, same(state.mainTrackState.last));
        expect(firstMain.controller.asFake.calls, ['initialize', 'play']);
        expect(state.mainTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);
        expect(state.backgroundTrackState.current, isNull);
        expect(firstBack.controller.asFake.calls, ['initialize', 'play']);
        expect(state.backgroundTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);

        state.removeListener(updateNotifyCalled);

        // Second (and last) main medium finishes, onMediumFinished should be
        // called.
        state.mainTrackState.current.controller
            .onMediumFinished(_FakeContext());
        expect(notifyCalls, 0);
        expect(finished, isTrue);
        expect(state.allInitialized, isTrue);
        expect(state.backgroundTrackState, isNotEmpty);
        expect(state.mainTrackState.current, isNull);
        expect(firstMain.controller.asFake.calls, ['initialize', 'play']);
        expect(state.mainTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);
        expect(state.backgroundTrackState.current, isNull);
        expect(firstBack.controller.asFake.calls, ['initialize', 'play']);
        expect(state.backgroundTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);

        await state.dispose();
        expect(firstMain.controller.asFake.calls,
            ['initialize', 'play', 'dispose']);
        expect(state.mainTrackState.last.controller.asFake.calls,
            ['initialize', 'play', 'dispose']);
        expect(firstBack.controller.asFake.calls,
            ['initialize', 'play', 'dispose']);
        expect(state.backgroundTrackState.last.controller.asFake.calls,
            ['initialize', 'play', 'dispose']);
      });

      test('when main track finishes first', () async {
        final state = await testInitialize();
        final firstMain = state.mainTrackState.current;
        final firstBack = state.backgroundTrackState.current;

        state.addListener(updateNotifyCalled);

        await testFirstMediaPlayed(state);

        // Second (and last) main medium finishes, onMediumFinished should be
        // called.
        state.mainTrackState.current.controller
            .onMediumFinished(_FakeContext());
        expect(notifyCalls, 0);
        expect(finished, isTrue);
        expect(state.allInitialized, isTrue);
        expect(state.backgroundTrackState, isNotEmpty);
        expect(state.mainTrackState.current, isNull);
        expect(firstMain.controller.asFake.calls, ['initialize', 'play']);
        expect(state.mainTrackState.last.controller.asFake.calls,
            ['initialize', 'play']);
        expect(state.backgroundTrackState.current,
            state.backgroundTrackState.last);
        expect(firstBack.controller.asFake.calls, ['initialize', 'play']);
        expect(state.backgroundTrackState.last.controller.asFake.calls,
            ['initialize', 'play', 'pause']);

        state.removeListener(updateNotifyCalled);

        await state.dispose();
        expect(firstMain.controller.asFake.calls,
            ['initialize', 'play', 'dispose']);
        expect(state.mainTrackState.last.controller.asFake.calls,
            ['initialize', 'play', 'dispose']);
        expect(firstBack.controller.asFake.calls,
            ['initialize', 'play', 'dispose']);
        expect(state.backgroundTrackState.last.controller.asFake.calls,
            ['initialize', 'play', 'pause', 'dispose']);
      });
    });

    test('toString()', () {
      expect(
        MultiMediumState(multiMedium, registry,
            onMediumFinished: (context) => null).toString(),
        'MultiMediumState(main: MultiMediumTrackState(audible, '
        'current: 0, media: 2), '
        'background: MultiMediumTrackState(visualizable, '
        'current: 0, media: 2))',
      );
      expect(
        MultiMediumState(audibleMultiMedium, registry).toString(),
        'MultiMediumState(main: MultiMediumTrackState(audible, '
        'current: 0, media: 2))',
      );
    });

    test('debugFillProperties() and debugDescribeChildren()', () {
      final identityHash = RegExp(r'#[0-9a-f]{5}');

      expect(
          MultiMediumState(multiMedium, registry,
                  onMediumFinished: (context) => null)
              .toStringDeep()
              .replaceAll(identityHash, ''),
          'MultiMediumState\n'
          ' │ notifies when all media finished\n'
          ' │ main:\n'
          ' │   MultiMediumTrackState(audible, currentIndex: 0, mediaState.length: 2)\n'
          ' │ background:\n'
          ' │   MultiMediumTrackState(visualizble, currentIndex: 0, mediaState.length: 2)\n'
          ' │\n'
          ' ├─main: MultiMediumTrackState\n'
          ' │ │ audible\n'
          ' │ │ currentIndex: 0\n'
          ' │ │ mediaState.length: 2\n'
          ' │ │\n'
          ' │ ├─0: SingleMediumState\n'
          ' │ │   medium: _FakeAudibleSingleMedium(resource: audible, maxDuration:\n'
          ' │ │     8760:00:00.000000)\n'
          ' │ │   size: <uninitialized>\n'
          ' │ │\n'
          ' │ └─1: SingleMediumState\n'
          ' │     medium: _FakeAudibleSingleMedium(resource: visualizable,\n'
          ' │       maxDuration: 8760:00:00.000000)\n'
          ' │     size: <uninitialized>\n'
          ' │\n'
          ' └─background: MultiMediumTrackState\n'
          '   │ visualizble\n'
          '   │ currentIndex: 0\n'
          '   │ mediaState.length: 2\n'
          '   │\n'
          '   ├─0: SingleMediumState\n'
          '   │   medium: _FakeVisualizableSingleMedium(resource: visualizable1,\n'
          '   │     maxDuration: 8760:00:00.000000)\n'
          '   │   size: <uninitialized>\n'
          '   │\n'
          '   └─1: SingleMediumState\n'
          '       medium: _FakeVisualizableSingleMedium(resource: visualizable2,\n'
          '         maxDuration: 8760:00:00.000000)\n'
          '       size: <uninitialized>\n'
          '');

      expect(
          MultiMediumState(audibleMultiMedium, registry)
              .toStringDeep()
              .replaceAll(identityHash, ''),
          'MultiMediumState\n'
          ' │ main:\n'
          ' │   MultiMediumTrackState(audible, currentIndex: 0, mediaState.length: 2)\n'
          ' │\n'
          ' ├─main: MultiMediumTrackState\n'
          ' │ │ audible\n'
          ' │ │ currentIndex: 0\n'
          ' │ │ mediaState.length: 2\n'
          ' │ │\n'
          ' │ ├─0: SingleMediumState\n'
          ' │ │   medium: _FakeAudibleSingleMedium(resource: audible, maxDuration:\n'
          ' │ │     8760:00:00.000000)\n'
          ' │ │   size: <uninitialized>\n'
          ' │ │\n'
          ' │ └─1: SingleMediumState\n'
          ' │     medium: _FakeAudibleSingleMedium(resource: visualizable,\n'
          ' │       maxDuration: 8760:00:00.000000)\n'
          ' │     size: <uninitialized>\n'
          ' │\n'
          ' └─background: MultiMediumTrackState\n'
          '     empty\n'
          '');
    });
  });
}

class _FakeContext extends Fake implements BuildContext {}

class _SingleMediumInfo {
  final Size size;
  final Exception exception;
  final Key widgetKey;
  _SingleMediumInfo(
    String location, {
    this.size,
    this.exception,
  })  : assert(location != null),
        assert(exception != null && size == null ||
            exception == null && size != null),
        widgetKey = GlobalKey(debugLabel: 'widgetKey(${location}');
}

abstract class _FakeSingleMedium extends SingleMedium {
  final _SingleMediumInfo info;
  _FakeSingleMedium(
    String location, {
    Size size,
    Exception exception,
  })  : info = _SingleMediumInfo(location, size: size, exception: exception),
        super(Uri.parse(location));
}

class _FakeAudibleSingleMedium extends _FakeSingleMedium implements Audible {
  _FakeAudibleSingleMedium(
    String location, {
    Size size,
    Exception exception,
  }) : super(location, size: size, exception: exception);
}

class _FakeVisualizableSingleMedium extends _FakeSingleMedium
    implements Visualizable {
  _FakeVisualizableSingleMedium(
    String location, {
    Size size,
    Exception exception,
  }) : super(location, size: size, exception: exception);
}

class _FakeVisualizableBackgroundMultiMediumTrack
    extends VisualizableBackgroundMultiMediumTrack implements Visualizable {
  _FakeVisualizableBackgroundMultiMediumTrack(List<Visualizable> media)
      : super(media);
}

void _registerControllers(ControllerRegistry registry) {
  SingleMediumController createController(SingleMedium medium,
      {void Function(BuildContext) onMediumFinished}) {
    final fakeMedium = medium as _FakeSingleMedium;
    final c = _FakeSingleMediumController(fakeMedium,
        widgetKey: fakeMedium.info.widgetKey,
        onMediumFinished: onMediumFinished);
    return c;
  }

  registry.register(_FakeAudibleSingleMedium, createController);
  registry.register(_FakeVisualizableSingleMedium, createController);
}

class _FakeSingleMediumController extends Fake
    implements SingleMediumController {
  @override
  _FakeSingleMedium medium;

  @override
  Key widgetKey;

  @override
  void Function(BuildContext context) onMediumFinished;

  final calls = <String>[];

  _FakeSingleMediumController(
    this.medium, {
    Key widgetKey,
    this.onMediumFinished,
  })  : assert(medium != null),
        widgetKey = widgetKey ?? GlobalKey(debugLabel: 'mediumKey');

  Future<T> _errorOr<T>(String name, [T value]) {
    calls.add(name);
    return medium.info.exception != null
        ? Future.error(medium.info.exception)
        : Future<T>.value(value);
  }

  @override
  Future<Size> initialize(BuildContext context) =>
      _errorOr('initialize', medium.info.size);

  @override
  Future<void> play(BuildContext context) => _errorOr<void>('play');

  @override
  Future<void> pause(BuildContext context) => _errorOr<void>('pause');

  @override
  Future<void> dispose() => _errorOr<void>('dispose');

  @override
  Widget build(BuildContext context) {
    calls.add('build');
    return Container(key: widgetKey);
  }
}

extension _AsFakeSingleMediumController on SingleMediumController {
  _FakeSingleMediumController get asFake => this as _FakeSingleMediumController;
}
