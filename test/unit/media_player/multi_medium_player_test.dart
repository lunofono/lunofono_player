@Tags(['unit', 'player'])

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;

import 'package:lunofono_player/src/media_player/multi_medium_state.dart'
    show MultiMediumState, MultiMediumTrackState, SingleMediumState;
import 'package:lunofono_player/src/media_player/media_player_error.dart'
    show MediaPlayerError;
import 'package:lunofono_player/src/media_player/multi_medium_player.dart'
    show MediaProgressIndicator, MultiMediumPlayer, MultiMediumTrackPlayer;

import '../../util/foundation.dart' show FakeDiagnosticableMixin;

void main() {
  group('MediaProgressIndicator', () {
    testWidgets('constructor asserts if visualizable is null',
        (WidgetTester tester) async {
      expect(() => MediaProgressIndicator(visualizable: null),
          throwsAssertionError);
    });

    Future<void> testInnerWidgets(WidgetTester tester,
        {@required IconData icon, @required bool visualizable}) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaProgressIndicator(visualizable: visualizable),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);
      expect((tester.widget(iconFinder) as Icon).icon, icon);
    }

    testWidgets(
        'if not visualizable has a CircularProgressIndicator and '
        'a musical note icon', (WidgetTester tester) async {
      await testInnerWidgets(tester,
          visualizable: false, icon: Icons.music_note);
    });

    testWidgets(
        'if t is visualizable has a CircularProgressIndicator and '
        'a movie film icon', (WidgetTester tester) async {
      await testInnerWidgets(tester,
          visualizable: true, icon: Icons.local_movies);
    });
  });

  group('MultiMediumTrackPlayer', () {
    final uninitializedState = FakeSingleMediumState(
        widgetKey: GlobalKey(debugLabel: 'uninitializedStateKey'));
    final errorState = FakeSingleMediumState(
        error: Exception('Error'),
        widgetKey: GlobalKey(debugLabel: 'errorStateKey'));
    final initializedState = FakeSingleMediumState(
        size: Size(10.0, 10.0),
        widgetKey: GlobalKey(debugLabel: 'initializedStateKey'));

    Future<void> pumpPlayer(
            WidgetTester tester, FakeMultiMediumTrackState state) async =>
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChangeNotifierProvider<MultiMediumTrackState>.value(
              value: state,
              child: MultiMediumTrackPlayer(),
            ),
          ),
        );

    group('error if', () {
      Future<void> testError(
        WidgetTester tester,
        FakeMultiMediumTrackState state,
      ) async {
        await pumpPlayer(tester, state);

        expect(find.byKey(errorState.widgetKey), findsNothing);
        expect(find.byKey(initializedState.widgetKey), findsNothing);
        expect(find.byKey(uninitializedState.widgetKey), findsNothing);
        expect(find.byType(MediaProgressIndicator), findsNothing);
        expect(find.byType(RotatedBox), findsNothing);

        expect(find.byType(MediaPlayerError), findsOneWidget);
      }

      testWidgets('current is erroneous', (WidgetTester tester) async {
        final state = FakeMultiMediumTrackState(
            current: errorState, last: initializedState, isVisualizable: true);
        await testError(tester, state);
      });

      testWidgets('last is erroneous', (WidgetTester tester) async {
        final state = FakeMultiMediumTrackState(last: errorState);
        await testError(tester, state);
      });
    });

    group('progress indicator if initializing a', () {
      Future<void> testProgress(WidgetTester tester, bool visualizable) async {
        final state = FakeMultiMediumTrackState(
            current: uninitializedState,
            last: initializedState,
            isVisualizable: visualizable);

        await pumpPlayer(tester, state);
        expect(find.byType(MediaPlayerError), findsNothing);
        expect(find.byKey(errorState.widgetKey), findsNothing);
        expect(find.byKey(initializedState.widgetKey), findsNothing);
        expect(find.byKey(uninitializedState.widgetKey), findsNothing);
        expect(find.byType(RotatedBox), findsNothing);

        final progressFinder = find.byType(MediaProgressIndicator);
        expect(progressFinder, findsOneWidget);
        final widget = tester.widget(progressFinder) as MediaProgressIndicator;
        expect(widget.isVisualizable, state.isVisualizable);
      }

      testWidgets('visualizable state', (WidgetTester tester) async {
        await testProgress(tester, true);
      });
      testWidgets('non-visualizable state', (WidgetTester tester) async {
        await testProgress(tester, false);
      });
    });
    group('initialized shows', () {
      Future<Widget> testPlayer(
        WidgetTester tester,
        FakeMultiMediumTrackState state, [
        FakeSingleMediumState playerState,
      ]) async {
        playerState ??= initializedState;
        await pumpPlayer(tester, state);
        expect(find.byType(MediaPlayerError), findsNothing);
        expect(find.byKey(errorState.widgetKey), findsNothing);
        expect(find.byKey(uninitializedState.widgetKey), findsNothing);
        expect(find.byType(MediaProgressIndicator), findsNothing);

        final playerFinder = find.byKey(playerState.widgetKey);
        expect(playerFinder, findsOneWidget);
        return tester.widget(playerFinder);
      }

      group('a Container for non-visualizable', () {
        testWidgets('initialized current state', (WidgetTester tester) async {
          final state = FakeMultiMediumTrackState(
            current: initializedState,
            last: uninitializedState,
            isVisualizable: false,
          );
          final playerWidget = await testPlayer(tester, state);
          expect(playerWidget, isA<Container>());
          expect(find.byType(RotatedBox), findsNothing);
        });

        testWidgets('initialized last state', (WidgetTester tester) async {
          final state = FakeMultiMediumTrackState(
            last: initializedState,
            isVisualizable: false,
          );
          final playerWidget = await testPlayer(tester, state);
          expect(playerWidget, isA<Container>());
          expect(find.byType(RotatedBox), findsNothing);
        });
      });

      testWidgets('player for last state', (WidgetTester tester) async {
        final state = FakeMultiMediumTrackState(
          last: initializedState,
          isVisualizable: true,
        );
        await testPlayer(tester, state);
      });

      testWidgets('no RotatedBox for square media',
          (WidgetTester tester) async {
        final squareState = FakeSingleMediumState(
          size: Size(10.0, 10.0),
          widgetKey: GlobalKey(debugLabel: 'squareKey'),
        );
        final state = FakeMultiMediumTrackState(
          current: squareState,
          last: errorState,
          isVisualizable: true,
        );
        await testPlayer(tester, state, squareState);
        expect(find.byType(RotatedBox), findsNothing);
      });

      testWidgets('no RotatedBox for portrait media',
          (WidgetTester tester) async {
        final portraitState = FakeSingleMediumState(
          size: Size(100.0, 180.0),
          widgetKey: GlobalKey(debugLabel: 'portraitKey'),
        );
        final state = FakeMultiMediumTrackState(
          current: portraitState,
          last: errorState,
          isVisualizable: true,
        );
        await testPlayer(tester, state, portraitState);
        expect(find.byType(RotatedBox), findsNothing);
      });

      testWidgets('a RotatedBox for landscape media',
          (WidgetTester tester) async {
        final landscapeState = FakeSingleMediumState(
          size: Size(100.0, 80.0),
          widgetKey: GlobalKey(debugLabel: 'landscapeKey'),
        );
        final state = FakeMultiMediumTrackState(
          current: landscapeState,
          last: errorState,
          isVisualizable: true,
        );
        await testPlayer(tester, state, landscapeState);
        expect(find.byType(RotatedBox), findsOneWidget);
      });
    });
  });

  group('MultiMediumPlayer', () {
    testWidgets('createTrackPlayer() returns a MultiMediumTrackPlayer',
        (WidgetTester tester) async {
      final player = TestMultiMediumPlayer();
      expect(
          player.createTrackPlayerFromSuper(), isA<MultiMediumTrackPlayer>());
    });

    Future<void> pumpPlayer(
        WidgetTester tester, FakeMultiMediumState controller) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<MultiMediumState>.value(
            value: controller,
            child: TestMultiMediumPlayer(),
          ),
        ),
      );
    }

    testWidgets('shows progress if not all initialized',
        (WidgetTester tester) async {
      final controller = FakeMultiMediumState(allInitialized: false);

      await pumpPlayer(tester, controller);
      expect(find.byType(MediaPlayerError), findsNothing);
      expect(find.byType(MultiMediumTrackPlayer), findsNothing);

      expect(find.byType(MediaProgressIndicator), findsOneWidget);
    });

    group('shows MultiMediumTrackPlayer', () {
      final audibleTrack = FakeMultiMediumTrackState(
        current: FakeSingleMediumState(size: Size(0.0, 0.0)),
        isVisualizable: false,
      );
      final visualTrack = FakeMultiMediumTrackState(
        current: FakeSingleMediumState(size: Size(10.0, 10.0)),
        isVisualizable: true,
      );

      Future<void> testMainTrackOnly(
          WidgetTester tester, FakeMultiMediumTrackState track) async {
        final controller = FakeMultiMediumState(mainTrack: track);

        await pumpPlayer(tester, controller);
        expect(find.byType(MediaPlayerError), findsNothing);
        expect(find.byType(MediaProgressIndicator), findsNothing);

        final stackFinder = find.byType(Stack);
        expect(stackFinder, findsOneWidget);
        final stack = tester.widget(stackFinder) as Stack;
        expect(stack.children.length, 1);
        expect(stack.children.first, isA<Center>());
        expect(
            find.descendant(
              of: find.byWidget(stack.children.first),
              matching: find.byType(TestMultiMediumTrackPlayer),
            ),
            findsOneWidget);
      }

      testWidgets('with main track only', (WidgetTester tester) async {
        await testMainTrackOnly(tester, audibleTrack);
        await testMainTrackOnly(tester, visualTrack);
      });

      Future<void> test2Tracks(
          WidgetTester tester, FakeMultiMediumState controller) async {
        await pumpPlayer(tester, controller);
        expect(find.byType(MediaPlayerError), findsNothing);
        expect(find.byType(MediaProgressIndicator), findsNothing);

        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(TestMultiMediumTrackPlayer), findsNWidgets(2));

        final stackFinder = find.byType(Stack);
        expect(stackFinder, findsOneWidget);
        final stack = tester.widget(stackFinder) as Stack;
        expect(stack.children.length, 2);

        // First track should be the visualizable track and centered
        expect(stack.children.first, isA<Center>());
        final firstTrackFinder = find.descendant(
          of: find.byWidget(stack.children.first),
          matching: find.byType(TestMultiMediumTrackPlayer),
        );
        expect(firstTrackFinder, findsOneWidget);
        final firstState = Provider.of<MultiMediumTrackState>(
            tester.element(firstTrackFinder),
            listen: false);
        expect(firstState, same(visualTrack));

        // Second track should be the audible one
        final secondTrackFinder = find.descendant(
          of: find.byWidget(stack.children.last),
          matching: find.byType(TestMultiMediumTrackPlayer),
        );
        expect(secondTrackFinder, findsOneWidget);
        expect(
            find.descendant(
              of: find.byWidget(stack.children.last),
              matching: find.byType(Center),
            ),
            findsNothing);
        final secondState = Provider.of<MultiMediumTrackState>(
            tester.element(secondTrackFinder),
            listen: false);
        expect(secondState, same(audibleTrack));
      }

      testWidgets('with 2 tracks the visualizable track is always the first',
          (WidgetTester tester) async {
        await test2Tracks(
            tester,
            FakeMultiMediumState(
              mainTrack: audibleTrack,
              backgroundTrack: visualTrack,
            ));
        await test2Tracks(
            tester,
            FakeMultiMediumState(
              mainTrack: visualTrack,
              backgroundTrack: audibleTrack,
            ));
      });
    });
  });
}

class FakeSingleMediumState extends Fake
    with FakeDiagnosticableMixin
    implements SingleMediumState {
  @override
  dynamic error;
  @override
  Size size;
  @override
  final Key widgetKey;
  @override
  Widget build(BuildContext context) => Container(key: widgetKey);
  @override
  bool get isInitialized => size != null;
  @override
  bool get isErroneous => error != null;
  @override
  String toStringShort() => 'FakeSingleMediumState('
      'error: $error, '
      'size: $size, '
      'widgetKey: $widgetKey'
      ')';
  FakeSingleMediumState({
    this.error,
    this.size,
    Key widgetKey,
  }) : widgetKey = widgetKey ?? GlobalKey(debugLabel: 'widgetKey');
}

class FakeMultiMediumTrackState extends Fake
    with FakeDiagnosticableMixin, ChangeNotifier
    implements MultiMediumTrackState {
  @override
  FakeSingleMediumState current;
  @override
  FakeSingleMediumState last;
  @override
  final bool isVisualizable;
  @override
  bool get isEmpty => current == null && last == null;
  @override
  bool get isNotEmpty => !isEmpty;
  @override
  Future<void> dispose() async => super.dispose();
  @override
  String toStringShort() => 'FakeMultiMediumTrackState('
      'current: $current, '
      'last: $last, '
      'isVisualizable: $isVisualizable'
      ')';
  FakeMultiMediumTrackState({
    this.current,
    FakeSingleMediumState last,
    this.isVisualizable = false,
  }) : last = last ?? current;
}

class FakeMultiMediumState extends Fake
    with FakeDiagnosticableMixin, ChangeNotifier
    implements MultiMediumState {
  FakeMultiMediumTrackState mainTrack;
  FakeMultiMediumTrackState backgroundTrack;
  @override
  bool allInitialized;
  @override
  MultiMediumTrackState get mainTrackState => mainTrack;
  @override
  MultiMediumTrackState get backgroundTrackState => backgroundTrack;
  @override
  String toStringShort() => 'FakeMultiMediumState('
      'allInitialized: $allInitialized, '
      'mainTrack: $mainTrack, '
      'backgroundTrack: $backgroundTrack'
      ')';
  @override
  Future<void> dispose() async => super.dispose();
  FakeMultiMediumState({
    FakeMultiMediumTrackState mainTrack,
    FakeMultiMediumTrackState backgroundTrack,
    bool allInitialized,
  })  : allInitialized = allInitialized ?? mainTrack != null,
        mainTrack = mainTrack ??
            FakeMultiMediumTrackState(current: FakeSingleMediumState()),
        backgroundTrack = backgroundTrack ?? FakeMultiMediumTrackState();
}

class TestMultiMediumPlayer extends MultiMediumPlayer {
  MultiMediumTrackPlayer createTrackPlayerFromSuper() =>
      super.createTrackPlayer();
  @override
  MultiMediumTrackPlayer createTrackPlayer() => TestMultiMediumTrackPlayer();
}

class TestMultiMediumTrackPlayer extends MultiMediumTrackPlayer {
  @override
  Widget build(BuildContext context) => Container();
}
