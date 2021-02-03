@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart' show DiagnosticableTreeMixin;
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart'
    show Fake, Mock, any, throwOnMissingStub, when;

import 'package:provider/provider.dart' show ChangeNotifierProvider;

import 'package:lunofono_player/src/media_player/media_player_error.dart'
    show MediaPlayerError;
import 'package:lunofono_player/src/media_player/media_progress_indicator.dart'
    show MediaProgressIndicator;
import 'package:lunofono_player/src/media_player/single_medium_controller.dart'
    show SingleMediumController;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;
import 'package:lunofono_player/src/media_player/single_medium_widget.dart'
    show SingleMediumWidget;

void main() {
  group('SingleMediumWidget', () {
    final uninitializedState = _FakeSingleMediumState(
        widgetKey: GlobalKey(debugLabel: 'uninitializedStateKey'));
    final errorState = _FakeSingleMediumState(
        error: Exception('Error'),
        widgetKey: GlobalKey(debugLabel: 'errorStateKey'));

    Future<void> pumpPlayer(
            WidgetTester tester, _FakeSingleMediumState state) async =>
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChangeNotifierProvider<SingleMediumState>.value(
              value: state,
              child: SingleMediumWidget(),
            ),
          ),
        );

    testWidgets('shows error if state is erroneous',
        (WidgetTester tester) async {
      await pumpPlayer(tester, errorState);

      expect(find.byKey(errorState.controller.widgetKey), findsNothing);
      expect(find.byType(MediaProgressIndicator), findsNothing);
      expect(find.byType(RotatedBox), findsNothing);

      expect(find.byType(MediaPlayerError), findsOneWidget);
    });

    group('shows progress indicator if initializing a', () {
      Future<void> testProgress(WidgetTester tester, bool visualizable) async {
        final state = _FakeSingleMediumState(
          widgetKey: GlobalKey(debugLabel: 'uninitialized [vis:$visualizable]'),
          isVisualizable: visualizable,
        );

        await pumpPlayer(tester, state);
        expect(find.byType(MediaPlayerError), findsNothing);
        expect(find.byKey(state.controller.widgetKey), findsNothing);
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
        _FakeSingleMediumState state,
      ) async {
        await pumpPlayer(tester, state);
        expect(find.byType(MediaPlayerError), findsNothing);
        expect(find.byKey(errorState.controller.widgetKey), findsNothing);
        expect(
            find.byKey(uninitializedState.controller.widgetKey), findsNothing);
        expect(find.byType(MediaProgressIndicator), findsNothing);

        final playerFinder = find.byKey(state.controller.widgetKey);
        expect(playerFinder, findsOneWidget);
        return tester.widget(playerFinder);
      }

      testWidgets('a Container for an initialized non-visualizable state',
          (WidgetTester tester) async {
        final state =
            _FakeSingleMediumState(size: Size(2.0, 1.0), isVisualizable: false);
        final playerWidget = await testPlayer(tester, state);
        expect(playerWidget, isA<Container>());
        expect(find.byType(RotatedBox), findsNothing);
      });

      testWidgets('the player for a visualizable state',
          (WidgetTester tester) async {
        final state = _FakeSingleMediumState(size: Size(1.0, 2.0));
        await testPlayer(tester, state);
      });

      testWidgets('no RotatedBox for square media',
          (WidgetTester tester) async {
        final state = _FakeSingleMediumState(size: Size(1.0, 1.0));
        await testPlayer(tester, state);
        expect(find.byType(RotatedBox), findsNothing);
      });

      testWidgets('no RotatedBox for portrait media',
          (WidgetTester tester) async {
        final state = _FakeSingleMediumState(size: Size(1.0, 2.0));
        await testPlayer(tester, state);
        expect(find.byType(RotatedBox), findsNothing);
      });

      testWidgets('a RotatedBox for landscape media',
          (WidgetTester tester) async {
        final state = _FakeSingleMediumState(size: Size(2.0, 1.0));
        await testPlayer(tester, state);
        expect(find.byType(RotatedBox), findsOneWidget);
      });
    });
  });
}

class _MockSingleMediumController extends Mock
    implements SingleMediumController {}

class _FakeSingleMediumState extends Fake
    with DiagnosticableTreeMixin, ChangeNotifier
    implements SingleMediumState {
  @override
  bool isVisualizable;
  @override
  dynamic error;
  @override
  Size size;
  @override
  Future<void> dispose() async => super.dispose();
  @override
  final controller = _MockSingleMediumController();
  @override
  bool get isInitialized => size != null;
  @override
  bool get isErroneous => error != null;
  @override
  String toStringShort() => 'FakeSingleMediumState('
      'error: $error, '
      'size: $size, '
      'widgetKey: $controller.widgetKey'
      ')';
  _FakeSingleMediumState({
    this.error,
    this.size,
    this.isVisualizable = true,
    Key widgetKey,
  }) {
    // Make sure any non-stubbed interaction throws and stub the build method
    // and widgetKey property.
    final key = widgetKey ?? GlobalKey(debugLabel: 'widgetKey');
    throwOnMissingStub(controller as _MockSingleMediumController);
    when(controller.build(any)).thenReturn(Container(key: key));
    when(controller.widgetKey).thenReturn(key);
  }
}
