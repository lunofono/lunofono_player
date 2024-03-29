@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart' show DiagnosticableTreeMixin;
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;

import 'package:lunofono_player/src/media_player/multi_medium_state.dart'
    show MultiMediumState;
import 'package:lunofono_player/src/media_player/multi_medium_track_state.dart'
    show MultiMediumTrackState;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;
import 'package:lunofono_player/src/media_player/media_player_error.dart'
    show MediaPlayerError;
import 'package:lunofono_player/src/media_player/media_progress_indicator.dart'
    show MediaProgressIndicator;
import 'package:lunofono_player/src/media_player/multi_medium_widget.dart'
    show MultiMediumWidget;
import 'package:lunofono_player/src/media_player/multi_medium_track_widget.dart'
    show MultiMediumTrackWidget;

void main() {
  group('MultiMediumWidget', () {
    testWidgets('createTrackWidget() returns a MultiMediumTrackWidget',
        (WidgetTester tester) async {
      final player = _TestMultiMediumWidget();
      expect(
          player.createTrackWidgetFromSuper(), isA<MultiMediumTrackWidget>());
    });

    Future<void> pumpPlayer(
        WidgetTester tester, _FakeMultiMediumState state) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<MultiMediumState>.value(
            value: state,
            child: _TestMultiMediumWidget(),
          ),
        ),
      );
    }

    testWidgets('shows progress if not all initialized',
        (WidgetTester tester) async {
      final state = _FakeMultiMediumState(isInitialized: false);

      await pumpPlayer(tester, state);
      expect(find.byType(MediaPlayerError), findsNothing);
      expect(find.byType(MultiMediumTrackWidget), findsNothing);

      expect(find.byType(MediaProgressIndicator), findsOneWidget);
    });

    group('shows MultiMediumTrackWidget', () {
      final audibleTrack = _FakeMultiMediumTrackState(
          current: _FakeSingleMediumState('audible'));
      final visualTrack = _FakeMultiMediumTrackState(
        current: _FakeSingleMediumState('visualizable'),
        isVisualizable: true,
      );

      Future<void> testMainTrackOnly(
          WidgetTester tester, _FakeMultiMediumTrackState track) async {
        final state = _FakeMultiMediumState(mainTrack: track);

        await pumpPlayer(tester, state);
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
              matching: find.byType(_FakeMultiMediumTrackWidget),
            ),
            findsOneWidget);
      }

      testWidgets('with main track only', (WidgetTester tester) async {
        await testMainTrackOnly(tester, audibleTrack);
        await testMainTrackOnly(tester, visualTrack);
      });

      Future<void> test2Tracks(
          WidgetTester tester, _FakeMultiMediumState state) async {
        await pumpPlayer(tester, state);
        expect(find.byType(MediaPlayerError), findsNothing);
        expect(find.byType(MediaProgressIndicator), findsNothing);

        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(_FakeMultiMediumTrackWidget), findsNWidgets(2));

        final stackFinder = find.byType(Stack);
        expect(stackFinder, findsOneWidget);
        final stack = tester.widget(stackFinder) as Stack;
        expect(stack.children.length, 2);

        // First track should be the visualizable track and centered
        expect(stack.children.first, isA<Center>());
        final firstTrackFinder = find.descendant(
          of: find.byWidget(stack.children.first),
          matching: find.byType(_FakeMultiMediumTrackWidget),
        );
        expect(firstTrackFinder, findsOneWidget);
        final firstState = Provider.of<MultiMediumTrackState>(
            tester.element(firstTrackFinder),
            listen: false);
        expect(firstState, same(visualTrack));

        // Second track should be the audible one
        final secondTrackFinder = find.descendant(
          of: find.byWidget(stack.children.last),
          matching: find.byType(_FakeMultiMediumTrackWidget),
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
            _FakeMultiMediumState(
              mainTrack: audibleTrack,
              backgroundTrack: visualTrack,
            ));
        await test2Tracks(
            tester,
            _FakeMultiMediumState(
              mainTrack: visualTrack,
              backgroundTrack: audibleTrack,
            ));
      });
    });
  });
}

class _FakeSingleMediumState extends Fake
    with DiagnosticableTreeMixin, ChangeNotifier
    implements SingleMediumState {
  final String name;
  @override
  String toStringShort() => name;
  @override
  Future<void> dispose() async => super.dispose();
  _FakeSingleMediumState(this.name);
}

class _FakeMultiMediumTrackState extends Fake
    with DiagnosticableTreeMixin, ChangeNotifier
    implements MultiMediumTrackState {
  @override
  _FakeSingleMediumState? current;
  @override
  _FakeSingleMediumState? last;
  @override
  final bool isVisualizable;
  @override
  bool get isEmpty => current == null && last == null;
  @override
  bool get isNotEmpty => !isEmpty;
  @override
  Future<void> dispose() async => super.dispose();
  @override
  String toStringShort() => 'current: $current, '
      'last: $last, '
      'isVisualizable: $isVisualizable';
  _FakeMultiMediumTrackState({
    this.current,
    _FakeSingleMediumState? last,
    this.isVisualizable = false,
  }) : last = last ?? current;
}

class _FakeMultiMediumState extends Fake
    with DiagnosticableTreeMixin, ChangeNotifier
    implements MultiMediumState {
  _FakeMultiMediumTrackState mainTrack;
  _FakeMultiMediumTrackState backgroundTrack;
  @override
  bool isInitialized;
  @override
  MultiMediumTrackState get mainTrackState => mainTrack;
  @override
  MultiMediumTrackState get backgroundTrackState => backgroundTrack;
  @override
  String toStringShort() => 'isInitialized: $isInitialized, '
      'mainTrack: $mainTrack, '
      'backgroundTrack: $backgroundTrack';
  @override
  Future<void> dispose() async => super.dispose();
  _FakeMultiMediumState({
    _FakeMultiMediumTrackState? mainTrack,
    _FakeMultiMediumTrackState? backgroundTrack,
    bool? isInitialized,
  })  : isInitialized = isInitialized ?? mainTrack != null,
        mainTrack = mainTrack ??
            _FakeMultiMediumTrackState(current: _FakeSingleMediumState('main')),
        backgroundTrack = backgroundTrack ?? _FakeMultiMediumTrackState();
}

class _TestMultiMediumWidget extends MultiMediumWidget {
  MultiMediumTrackWidget createTrackWidgetFromSuper() =>
      super.createTrackWidget();
  @override
  MultiMediumTrackWidget createTrackWidget() => _FakeMultiMediumTrackWidget();
}

class _FakeMultiMediumTrackWidget extends MultiMediumTrackWidget {
  @override
  Widget build(BuildContext context) => Container();
}
