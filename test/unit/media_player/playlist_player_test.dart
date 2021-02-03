@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart';
import 'package:lunofono_player/src/media_player/controller_registry.dart';
import 'package:lunofono_player/src/media_player/playlist_player.dart';
import 'package:lunofono_player/src/media_player/playlist_widget.dart';

void main() {
  test('PlaylistWidget.createSingleMediumWidget()', () {
    expect(PlaylistPlayer.createPlaylistWidget(), isA<PlaylistWidget>());
  });

  group('PlaylistPlayer', () {
    final mockPlaylist = _MockPlaylist();

    setUp(() => reset(mockPlaylist));

    test('constructor asserts on null media', () {
      expect(() => PlaylistPlayer(playlist: null), throwsAssertionError);
    });

    test('default constructor uses the expected defaults', () {
      final player = PlaylistPlayer(playlist: mockPlaylist);
      expect(player.playlist, same(mockPlaylist));
      expect(player.backgroundColor, same(Colors.black));
      expect(player.onMediaStopped, isNull);
    });

    test('default constructor saves extra arguments as expected', () {
      final callback = (BuildContext context) {};
      final player = PlaylistPlayer(
        playlist: mockPlaylist,
        backgroundColor: Colors.red,
        onMediaStopped: callback,
      );
      expect(player.playlist, same(mockPlaylist));
      expect(player.backgroundColor, same(Colors.red));
      expect(player.onMediaStopped, same(callback));
    });

    testWidgets('initialization is triggered', (WidgetTester tester) async {
      // first mock the widget displayed by the player, so we don't have to deal
      // with internal consumers and states
      final createPlaylistPlayer = PlaylistPlayer.createPlaylistWidget;
      PlaylistPlayer.createPlaylistWidget = () => _FakePlaylistWidget();
      addTearDown(
          () => PlaylistPlayer.createPlaylistWidget = createPlaylistPlayer);

      // then we mock the controller, so we can mock a normal play (otherwise
      // just an error will be shown if the mock medium doesn't have
      // a registered controller
      final mockController = _MockSingleMediumController();
      ControllerRegistry.instance.register(_MockSingleMedium, (medium,
          {onMediumFinished}) {
        when(mockController.medium).thenReturn(medium);
        when(mockController.onMediumFinished).thenReturn(onMediumFinished);
        return mockController;
      });

      // finally we add a stub to the mock playlist to return a mock medium
      final mockMedium = _MockSingleMedium();
      when(mockPlaylist.media).thenReturn(<Medium>[mockMedium]);
      when(mockMedium.resource).thenReturn(Uri.parse('medium/path'));

      // and we created the PlaylistPlayer registering a callback to know if it
      // was called
      var stopped = false;
      final player = PlaylistPlayer(
          playlist: mockPlaylist, onMediaStopped: (context) => stopped = true);

      // we pump the player and expect to find the widget, that it hasn't
      // stopped, and that the controller's initialization and play was called.
      await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: player));
      final widgetFinder = find.byType(_FakePlaylistWidget);
      expect(widgetFinder, findsOneWidget);
      expect(stopped, isFalse);
      verifyInOrder([
        mockController.initialize(any),
        mockController.play(any),
      ]);

      // then we tap on the player, the onMediaStopped callback should be
      // called, and the controller should be paused.
      await tester.tap(widgetFinder);
      await tester.pump();
      expect(stopped, isTrue);
      verifyInOrder([
        mockController.pause(any),
      ]);
    });
  });
}

class _MockSingleMediumController extends Mock
    implements SingleMediumController {}

class _MockSingleMedium extends Mock implements SingleMedium {}

class _FakePlaylistWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

class _MockPlaylist extends Mock
    with DiagnosticableTreeMixin
    implements Playlist {}
