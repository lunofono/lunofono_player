@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart';

import 'package:lunofono_player/src/media_player/multi_medium_state.dart'
    show MultiMediumState;
import 'package:lunofono_player/src/media_player/playable_state.dart'
    show PlayableState;
import 'package:lunofono_player/src/media_player/playlist_state.dart'
    show PlaylistState, UnsupportedMediumTypeError;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;

import 'mocks.mocks.dart';

void main() {
  group('PlaylistState.createPlayableState()', () {
    test('creates SingleMediumState for SingleMedium', () {
      final medium = _FakeSingleMedium();
      final onFinished = (BuildContext context) {};
      final state =
          PlaylistState.createPlayableState(medium, onFinished: onFinished);
      expect(state, isA<SingleMediumState>());
      expect((state as SingleMediumState).playable, same(medium));
    });

    test('creates SingleMediumState for SingleMedium', () {
      final medium = _FakeMultiMedium();
      final onFinished = (BuildContext context) {};
      final state =
          PlaylistState.createPlayableState(medium, onFinished: onFinished);
      expect(state, isA<MultiMediumState>());
      expect((state as MultiMediumState).playable, same(medium));
    });

    test('throws UnsupportedMediumType on unsupported Medium type', () {
      final medium = _FakeMedium();
      final onFinished = (BuildContext context) {};
      expect(
          () =>
              PlaylistState.createPlayableState(medium, onFinished: onFinished),
          throwsA(isA<UnsupportedMediumTypeError>()));
    });
  });

  group('PlaylistState', () {
    final fakeContext = _FakeContext();

    final testMedia = <Medium>[
      _FakeMedium('first'),
      _FakeMedium('second'),
    ];

    final originalCreatePlayableState = PlaylistState.createPlayableState;
    setUpAll(() => PlaylistState.createPlayableState = (medium, {onFinished}) {
          expect(medium, isA<_FakeMedium>());
          final state = _MockPlayableState(
            medium,
            onFinished: onFinished,
          );
          throwOnMissingStub(state);
          return state;
        });
    tearDownAll(
        () => PlaylistState.createPlayableState = originalCreatePlayableState);

    void stubAll(List<PlayableState> states) {
      states.forEach((state) {
        final s = state as _MockPlayableState;
        when(s.initialize(fakeContext, startPlaying: anyNamed('startPlaying')))
            .thenAnswer((_) => Future<void>.value());
        when(s.play(fakeContext)).thenAnswer((_) => Future<void>.value());
        when(s.pause(fakeContext)).thenAnswer((_) => Future<void>.value());
        when(s.dispose()).thenAnswer((_) => Future<void>.value());
      });
    }

    PlaylistState createPlaylistState(
        {List<Medium>? media,
        void Function(BuildContext context)? onFinished}) {
      final state =
          PlaylistState(Playlist(media ?? testMedia), onFinished: onFinished);
      stubAll(state.mediaState);
      return state;
    }

    group('constructor', () {
      void testContructorWithMedia(PlaylistState state, List<Medium> media) {
        expect(state.mediaState.length, media.length);
        expect(state.currentIndex, 0);
        expect(state.isFinished, isFalse);
        expect(state.current, state.mediaState.first);
        expect(state.last, state.mediaState.last);
        expect(state.current!.playable, same(media.first));
        expect(state.current!.onFinished, isNotNull);
        expect(state.last!.playable, same(media.last));
        expect(state.last!.onFinished, isNotNull);
      }

      test('create mediaState correctly', () {
        final state = PlaylistState(Playlist(testMedia));
        testContructorWithMedia(state, testMedia);
      });
    });

    test('initialize() initializes media states', () async {
      final state = createPlaylistState();
      await state.initialize(fakeContext);
      expect(state.isFinished, isFalse);
      state.mediaState.forEach((s) {
        verifyInOrder([
          s.initialize(fakeContext),
        ]);
        verifyNoMoreInteractions(s);
      });
    });

    test('initialize(startPlaying) initializes media and starts playing',
        () async {
      final state = createPlaylistState();

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
      var onFinished = false;
      final state =
          createPlaylistState(onFinished: (context) => onFinished = true);
      expect(onFinished, false);

      await state.initialize(fakeContext);

      final first = state.current;
      state.mediaState.forEach(clearInteractions);
      await state.play(fakeContext);
      expect(onFinished, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      verify(state.current!.play(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      state.mediaState.forEach(clearInteractions);
      await state.pause(fakeContext);
      expect(onFinished, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      verify(state.current!.pause(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      state.mediaState.forEach(clearInteractions);
      await state.play(fakeContext);
      expect(onFinished, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(first));
      verify(state.current!.play(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      // after the current track finished, the next one is played
      state.mediaState.forEach(clearInteractions);
      state.current!.onFinished!(fakeContext);
      expect(onFinished, false);
      expect(state.isFinished, isFalse);
      expect(state.current, same(state.last));
      verify(state.current!.play(fakeContext)).called(1);
      state.mediaState.forEach(verifyNoMoreInteractions);

      // after the last track finished, the controller should be finished
      state.mediaState.forEach(clearInteractions);
      state.current!.onFinished!(fakeContext);
      expect(onFinished, true);
      expect(state.isFinished, isTrue);
      expect(state.current, isNull);
      state.mediaState.forEach(verifyNoMoreInteractions);

      // If we dispose the controller,
      state.mediaState.forEach(clearInteractions);
      await state.dispose();
      state.mediaState.forEach((s) {
        verify(s.dispose()).called(1);
        verifyNoMoreInteractions(s);
      });
    });

    test('listening for updates work', () async {
      final state = createPlaylistState();

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
      final state = createPlaylistState();

      expect(state.toString(),
          'PlaylistState(<uninitialized> current: 0, media: 2)');
      await state.initialize(fakeContext);
      expect(state.toString(), 'PlaylistState(current: 0, media: 2)');
    });

    test('debugFillProperties()', () async {
      final state = createPlaylistState();

      var builder = DiagnosticPropertiesBuilder();
      state.debugFillProperties(builder);
      expect(
          builder.properties.toString(),
          [
            FlagProperty('isInitialized',
                value: false, ifFalse: '<uninitialized>'),
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
                value: true, ifFalse: '<uninitialized>'),
            IntProperty('currentIndex', 0),
            IntProperty('mediaState.length', 2),
          ].toString());
    });

    test('debugDescribeChildren()', () async {
      final state = createPlaylistState();
      final fakeNode = _FakeDiagnosticsNode();
      state.mediaState.forEach((s) => when(s.toDiagnosticsNode(
              name: captureAnyNamed('name'), style: captureAnyNamed('style')))
          .thenReturn(fakeNode));

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

class _FakeContext extends Fake implements BuildContext {}

class _FakeMedium extends Fake implements Medium {
  final String? name;
  _FakeMedium([this.name]);

  @override
  String toString() => '$runtimeType(${name ?? ''})';
}

class _FakeSingleMedium extends _FakeMedium implements SingleMedium {
  @override
  Uri get resource => Uri.parse(name ?? '');
  _FakeSingleMedium([String? name]) : super(name);
}

class _FakeMultiMedium extends _FakeMedium implements MultiMedium {
  @override
  MultiMediumTrack get mainTrack =>
      _FakeMultiMediumTrack(_FakeSingleMedium('mainTrack1'));

  @override
  BackgroundMultiMediumTrack get backgroundTrack => NoTrack();

  _FakeMultiMedium([String? name]) : super(name);
}

class _FakeMultiMediumTrack extends Fake implements MultiMediumTrack {
  @override
  final List<SingleMedium> media;

  _FakeMultiMediumTrack(_FakeSingleMedium medium)
      : media = <SingleMedium>[medium];
}

class _FakeDiagnosticsNode extends Fake implements DiagnosticsNode {
  @override
  String toString(
          {TextTreeConfiguration? parentConfiguration,
          DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeNode';
}

class _MockPlayableState extends MockPlayableState {
  @override
  final Medium playable;
  @override
  final void Function(BuildContext)? onFinished;
  _MockPlayableState(
    this.playable, {
    this.onFinished,
  });
}
