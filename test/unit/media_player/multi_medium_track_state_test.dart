@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart';
import 'package:lunofono_player/src/media_player/single_medium_controller.dart'
    show Size;

import 'package:lunofono_player/src/media_player/multi_medium_track_state.dart'
    show MultiMediumTrackState;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;

import 'mocks.mocks.dart' show MockSingleMediumState;

void main() {
  group('MultiMediumTrackState', () {
    MultiMediumTrackState.createSingleMediumState = (
      SingleMedium medium, {
      required bool isVisualizable,
      void Function(BuildContext)? onFinished,
    }) {
      final state = _MockSingleMediumState(
        medium,
        isVisualizable: isVisualizable,
        onFinished: onFinished,
      );
      throwOnMissingStub(state);
      return state;
    };

    final fakeContext = _FakeContext();

    final audibleMedium = _FakeAudibleSingleMedium(
        name: 'audibleMedium1', size: const Size(0.0, 0.0));
    final audibleMedium2 = _FakeAudibleSingleMedium(
        name: 'audibleMedium2', size: const Size(10.0, 12.0));
    final audibleMainTrack2 = _FakeAudibleMultiMediumTrack([
      audibleMedium,
      audibleMedium2,
    ]);
    final audibleBackTrack2 = _FakeAudibleBackgroundMultiMediumTrack([
      audibleMedium,
      audibleMedium2,
    ]);

    void stubAll(List<SingleMediumState> media) {
      for (var s in media) {
        when(s.initialize(fakeContext, startPlaying: false))
            .thenAnswer((_) => Future<void>.value());
        when(s.play(fakeContext)).thenAnswer((_) => Future<void>.value());
        when(s.pause(fakeContext)).thenAnswer((_) => Future<void>.value());
        when(s.dispose()).thenAnswer((_) => Future<void>.value());
      }
    }

    group('constructor', () {
      group('.internal() asserts on', () {
        test('empty media', () {
          expect(
            () => _TestMultiMediumTrackState(media: [], visualizable: true),
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
        expect(state.current!.playable, media.first);
        expect(state.current!.isVisualizable, state.isVisualizable);
        expect(state.current!.onFinished, isNotNull);
        expect(state.last!.playable, media.last);
        expect(state.last!.isVisualizable, state.isVisualizable);
        expect(state.last!.onFinished, isNotNull);
      }

      test('.main() create mediaState correctly', () {
        final state = MultiMediumTrackState.main(track: audibleMainTrack2);
        testContructorWithMedia(state, audibleMainTrack2.media);
      });

      test('.background() create mediaState correctly', () {
        final state =
            MultiMediumTrackState.background(track: audibleBackTrack2);
        testContructorWithMedia(state, audibleBackTrack2.media);
      });

      test('.background() create empty track with NoTrack', () {
        final state = MultiMediumTrackState.background(track: const NoTrack());
        expect(state.isVisualizable, isFalse);
        expect(state.isFinished, isTrue);
        expect(state.isEmpty, isTrue);
        expect(state.isNotEmpty, isFalse);
      });
    });

    test('initialize() initializes media states', () async {
      final state = MultiMediumTrackState.main(track: audibleMainTrack2);
      state.mediaState.forEach(verifyNoMoreInteractions);
      stubAll(state.mediaState);
      await state.initialize(fakeContext);
      expect(state.isFinished, isFalse);
      for (var s in state.mediaState) {
        verifyInOrder([
          s.initialize(fakeContext),
        ]);
        verifyNoMoreInteractions(s);
      }
    });

    test('initialize(startPlaying) initializes media and starts playing',
        () async {
      final state = MultiMediumTrackState.main(track: audibleMainTrack2);
      stubAll(state.mediaState);

      await state.initialize(fakeContext, startPlaying: true);
      expect(state.isFinished, isFalse);
      verifyInOrder([
        state.mediaState.first.initialize(fakeContext, startPlaying: false),
        state.mediaState.first.play(fakeContext),
      ]);
      verifyInOrder([
        state.mediaState.last.initialize(fakeContext, startPlaying: false),
      ]);
      state.mediaState.forEach(verifyNoMoreInteractions);
    });

    test('play-pause-next cycle with onFinished works', () async {
      final track = _FakeAudibleMultiMediumTrack([
        audibleMedium,
        audibleMedium2,
      ]);
      var onFinishedCalled = false;
      final state = MultiMediumTrackState.main(
          track: track, onFinished: (context) => onFinishedCalled = true);
      expect(onFinishedCalled, false);
      stubAll(state.mediaState);

      await state.initialize(fakeContext);

      final first = state.current;
      state.mediaState.forEach(clearInteractions);
      await state.play(fakeContext);
      expect(onFinishedCalled, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      verify(state.current!.play(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      state.mediaState.forEach(clearInteractions);
      await state.pause(fakeContext);
      expect(onFinishedCalled, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      verify(state.current!.pause(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      state.mediaState.forEach(clearInteractions);
      await state.play(fakeContext);
      expect(onFinishedCalled, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      verify(state.current!.play(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      // after the current track finished, the next one is played
      state.mediaState.forEach(clearInteractions);
      state.current!.onFinished!(fakeContext);
      expect(onFinishedCalled, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(state.last));
      verify(state.current!.play(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      // after the last track finished, the controller should be finished
      state.mediaState.forEach(clearInteractions);
      state.current!.onFinished!(fakeContext);
      expect(onFinishedCalled, true);
      expect(state.isFinished, isTrue);
      expect(state.current, isNull);
      state.mediaState.forEach(verifyNoMoreInteractions);

      // If we dispose the controller,
      state.mediaState.forEach(clearInteractions);
      await state.dispose();
      for (var s in state.mediaState) {
        verify(s.dispose()).called(1);
        verifyNoMoreInteractions(s);
      }
    });

    test('listening for updates work', () async {
      final state = MultiMediumTrackState.main(track: audibleMainTrack2);
      stubAll(state.mediaState);

      var notifyCalls = 0;
      state.addListener(() => notifyCalls += 1);

      await state.initialize(fakeContext);
      expect(notifyCalls, 1);
      // plays first
      await state.play(fakeContext);
      expect(notifyCalls, 1);
      // ends first, second starts playing
      state.current!.onFinished!(fakeContext);
      expect(notifyCalls, 2);
      // ends second, onFinished should be called
      state.current!.onFinished!(fakeContext);
      expect(notifyCalls, 3);
      await state.pause(fakeContext);
      expect(notifyCalls, 3);
      await state.dispose();
      expect(notifyCalls, 3);
    });

    test('toString()', () async {
      var state = MultiMediumTrackState.main(track: audibleMainTrack2);
      stubAll(state.mediaState);

      expect(state.toString(),
          'MultiMediumTrackState(audible, current: 0, media: 2)');
      await state.initialize(fakeContext);
      expect(state.toString(),
          'MultiMediumTrackState(initialized, audible, current: 0, media: 2)');

      state = MultiMediumTrackState.background(track: const NoTrack());
      stubAll(state.mediaState);
      expect(
        MultiMediumTrackState.background(track: const NoTrack()).toString(),
        'MultiMediumTrackState(empty)',
      );
    });

    test('debugFillProperties()', () async {
      final state = MultiMediumTrackState.main(track: audibleMainTrack2);
      var builder = DiagnosticPropertiesBuilder();
      state.debugFillProperties(builder);
      expect(
          builder.properties.toString(),
          [
            FlagProperty('isInitialized',
                value: false, ifTrue: 'all tracks are initialized'),
            FlagProperty('visualizable',
                value: false, ifTrue: 'visualizble', ifFalse: 'audible'),
            IntProperty('currentIndex', 0),
            IntProperty('mediaState.length', 2),
          ].toString());

      await state.initialize(fakeContext);
      builder = DiagnosticPropertiesBuilder();
      state.debugFillProperties(builder);
      expect(
          builder.properties.toString(),
          [
            FlagProperty('isInitialized',
                value: true, ifTrue: 'all tracks are initialized'),
            FlagProperty('visualizable',
                value: false, ifTrue: 'visualizble', ifFalse: 'audible'),
            IntProperty('currentIndex', 0),
            IntProperty('mediaState.length', 2),
          ].toString());
    });

    test('debugDescribeChildren()', () async {
      final state = MultiMediumTrackState.main(track: audibleMainTrack2);
      final fakeNode = _FakeDiagnosticsNode();
      for (var s in state.mediaState) {
        when(s.toDiagnosticsNode(
                name: captureAnyNamed('name'), style: captureAnyNamed('style')))
            .thenReturn(fakeNode);
      }

      expect(state.debugDescribeChildren(), [fakeNode, fakeNode]);
      state.mediaState.asMap().forEach(
            (i, s) => expect(
              verify(s.toDiagnosticsNode(
                      name: captureAnyNamed('name'),
                      style: captureThat(isNull, named: 'style')))
                  .captured,
              ['$i', null],
            ),
          );

      await state.initialize(fakeContext);
      expect(state.debugDescribeChildren(), [fakeNode, fakeNode]);
      state.mediaState.asMap().forEach(
            (i, s) => expect(
              verify(s.toDiagnosticsNode(
                      name: captureAnyNamed('name'),
                      style: captureThat(isNull, named: 'style')))
                  .captured,
              ['$i', null],
            ),
          );
    });
  });
}

class _TestMultiMediumTrackState extends MultiMediumTrackState {
  _TestMultiMediumTrackState({
    required List<SingleMedium> media,
    required bool visualizable,
    void Function(BuildContext context)? onFinished,
  }) : super.internal(
          media: media,
          visualizable: visualizable,
          onFinished: onFinished,
        );
}

class _FakeContext extends Fake implements BuildContext {}

abstract class _FakeSingleMedium extends Fake implements SingleMedium {
  final String? name;
  final Size? size;
  final dynamic error;
  final Key widgetKey;
  _FakeSingleMedium({
    this.name,
    this.size,
    this.error,
    Key? widgetKey,
  })  : assert(error != null && size == null || error == null && size != null),
        widgetKey = widgetKey ?? GlobalKey(debugLabel: 'widgetKey');

  @override
  Uri get resource => Uri.parse('medium.resource');

  @override
  String toString() => '$runtimeType($name)';
}

class _FakeAudibleSingleMedium extends _FakeSingleMedium implements Audible {
  _FakeAudibleSingleMedium({
    String? name,
    Size? size,
    dynamic error,
    Key? widgetKey,
  }) : super(name: name, size: size, error: error, widgetKey: widgetKey);
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

class _FakeDiagnosticsNode extends Fake implements DiagnosticsNode {
  @override
  String toString(
          {TextTreeConfiguration? parentConfiguration,
          DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeNode';
}

class _MockSingleMediumState extends MockSingleMediumState {
  @override
  final SingleMedium playable;
  @override
  final bool isVisualizable;
  @override
  final void Function(BuildContext)? onFinished;
  _MockSingleMediumState(
    this.playable, {
    required this.isVisualizable,
    this.onFinished,
  });
}
