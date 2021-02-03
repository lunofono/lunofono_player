@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart' show DiagnosticableTreeMixin;
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:provider/provider.dart' show ChangeNotifierProvider;

import 'package:lunofono_player/src/media_player/media_player_error.dart'
    show MediaPlayerError;
import 'package:lunofono_player/src/media_player/media_progress_indicator.dart'
    show MediaProgressIndicator;
import 'package:lunofono_player/src/media_player/multi_medium_state.dart'
    show MultiMediumState;
import 'package:lunofono_player/src/media_player/multi_medium_widget.dart'
    show MultiMediumWidget;
import 'package:lunofono_player/src/media_player/playable_state.dart'
    show PlayableState;
import 'package:lunofono_player/src/media_player/playlist_state.dart'
    show PlaylistState;
import 'package:lunofono_player/src/media_player/playlist_widget.dart'
    show PlaylistWidget;
import 'package:lunofono_player/src/media_player/single_medium_widget.dart'
    show SingleMediumWidget;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;

import '../../util/finders.dart' show findSubString;

void main() {
  test('PlaylistWidget.createSingleMediumWidget()', () {
    expect(
        PlaylistWidget.createSingleMediumWidget(), isA<SingleMediumWidget>());
  });
  test('PlaylistWidget.createMultiMediumWidget()', () {
    expect(PlaylistWidget.createMultiMediumWidget(), isA<MultiMediumWidget>());
  });

  group('PlaylistWidget', () {
    final createSingleMediumWidget = PlaylistWidget.createSingleMediumWidget;
    final createMultiMediumWidget = PlaylistWidget.createMultiMediumWidget;
    setUpAll(() {
      PlaylistWidget.createSingleMediumWidget = () => _FakeSingleMediumWidget();
      PlaylistWidget.createMultiMediumWidget = () => _FakeMultiMediumWidget();
    });
    tearDownAll(() {
      PlaylistWidget.createSingleMediumWidget = createSingleMediumWidget;
      PlaylistWidget.createMultiMediumWidget = createMultiMediumWidget;
    });

    Widget createWidget(_MockPlaylistState state) => Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<PlaylistState>.value(
            value: state,
            child: PlaylistWidget(),
          ),
        );

    testWidgets('shows a MediaProgressIndicator if initializing',
        (WidgetTester tester) async {
      final state = _MockPlaylistState();
      when(state.isInitialized).thenReturn(false);
      await tester.pumpWidget(createWidget(state));
      verify(state.isInitialized).called(1);
      expect(find.byType(MediaProgressIndicator), findsOneWidget);
    });

    testWidgets('shows a MediaPlayerError if current is of unknown type',
        (WidgetTester tester) async {
      final state = _MockPlaylistState();
      when(state.isInitialized).thenReturn(true);
      when(state.current).thenReturn(_MockUnknownMediumState());
      await tester.pumpWidget(createWidget(state));
      verify(state.isInitialized).called(1);
      expect(find.byType(MediaPlayerError), findsOneWidget);
      expect(findSubString('Unsupported type'), findsOneWidget);
    });

    testWidgets('shows a SingleMediumWidget if current is a SingleMediumState',
        (WidgetTester tester) async {
      final state = _MockPlaylistState();
      when(state.isInitialized).thenReturn(true);
      final current = _MockSingleMediumState();
      when(state.current).thenReturn(current);
      when(current.isErroneous).thenReturn(true);
      when(current.isVisualizable).thenReturn(true);
      await tester.pumpWidget(createWidget(state));
      expect(find.byType(_FakeSingleMediumWidget), findsOneWidget);
    });

    testWidgets('shows a MultiMediumWidget if current is a MultiMediumState',
        (WidgetTester tester) async {
      final state = _MockPlaylistState();
      when(state.isInitialized).thenReturn(true);
      when(state.current).thenReturn(_MockMultiMediumState());
      await tester.pumpWidget(createWidget(state));
      expect(find.byType(_FakeMultiMediumWidget), findsOneWidget);
    });

    testWidgets('shows the last state if current is null',
        (WidgetTester tester) async {
      final state = _MockPlaylistState();
      when(state.isInitialized).thenReturn(true);
      when(state.current).thenReturn(null);
      when(state.last).thenReturn(_MockMultiMediumState());
      await tester.pumpWidget(createWidget(state));
      expect(find.byType(_FakeMultiMediumWidget), findsOneWidget);
    });
  });
}

class _MockUnknownMediumState extends Mock
    with DiagnosticableTreeMixin
    implements PlayableState {}

class _MockSingleMediumState extends Mock
    with DiagnosticableTreeMixin
    implements SingleMediumState {}

class _FakeSingleMediumWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

class _MockMultiMediumState extends Mock
    with DiagnosticableTreeMixin
    implements MultiMediumState {}

class _FakeMultiMediumWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

class _MockPlaylistState extends Mock
    with DiagnosticableTreeMixin
    implements PlaylistState {}
