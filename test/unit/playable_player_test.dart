@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Image;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart';
import 'package:lunofono_player/src/media_player.dart'
    show MediaPlayer, SingleMediumPlayer;
import 'package:lunofono_player/src/playable_player.dart';

void main() {
  group('PlayablePlayer', () {
    final oldPlayableRegistry = PlayablePlayer.registry;
    FakeContext fakeContext;
    FakePlayable fakePlayable;
    Color color;

    setUp(() {
      fakePlayable = FakePlayable();
      fakeContext = FakeContext();
      color = Color(0x3845bd34);
    });

    tearDown(() => PlayablePlayer.registry = oldPlayableRegistry);

    test('empty', () {
      PlayablePlayer.registry = PlayablePlayerRegistry();
      expect(PlayablePlayer.registry, isEmpty);
      expect(() => PlayablePlayer.wrap(fakePlayable), throwsAssertionError);
    });

    test('registration and calling from empty', () {
      PlayablePlayer.registry = PlayablePlayerRegistry();
      PlayablePlayer.registry.register(FakePlayable,
          (playable) => FakePlayablePlayer(playable as FakePlayable));
      PlayablePlayer.wrap(fakePlayable).play(fakeContext, color);
      expect(fakePlayable.calledPlayable, same(fakePlayable));
      expect(fakePlayable.calledContext, same(fakeContext));
      expect(fakePlayable.calledColor, same(color));
    });

    group('SingleMedium', () {
      final homeKey = GlobalKey(debugLabel: 'homeKey');

      void testPlayable(WidgetTester tester, Widget homeWidget) async {
        // We need a MaterialApp to use the Navigator
        await tester.pumpWidget(MaterialApp(home: homeWidget));
        final homeFinder = find.byKey(homeKey);
        expect(homeFinder, findsOneWidget);
        expect(find.byType(SingleMediumPlayer), findsNothing);

        // We tap on the HomeWidget to call playable.play()
        await tester.tap(homeFinder);
        // One pump seems to be needed to process the Navigator.push(), this
        // idiom is also being used in Flutter Navigator tests:
        // https://github.com/flutter/flutter/blob/1.20.3/packages/flutter/test/widgets/navigator_test.dart
        await tester.pump();
        // The second pump we wait a bit because Navigator is animated
        await tester.pump(Duration(seconds: 1));
        expect(find.byKey(homeKey), findsNothing);
        final playerFinder = find.byType(SingleMediumPlayer);
        expect(playerFinder, findsOneWidget);
        final mediaPlayer = tester.widget(playerFinder) as SingleMediumPlayer;
        final context = tester.element(playerFinder);

        // The HomeWidget should be back
        mediaPlayer.onMediaStopped(context); // Should call Navigator.pop()
        await tester.pump(); // Same with .push() about the double pump()
        await tester.pump(Duration(seconds: 1));
        expect(find.byKey(homeKey), findsOneWidget);
        expect(find.byType(SingleMediumPlayer), findsNothing);
      }

      testWidgets('Audio', (WidgetTester tester) async {
        final audio = PlayablePlayer.wrap(Audio(Uri.parse('audio')));
        await testPlayable(tester, HomeWidgetPlayable(audio, key: homeKey));
      });

      testWidgets('Image', (WidgetTester tester) async {
        final image = PlayablePlayer.wrap(Image(Uri.parse('image')));
        await testPlayable(tester, HomeWidgetPlayable(image, key: homeKey));
      });

      testWidgets('Video', (WidgetTester tester) async {
        final video = PlayablePlayer.wrap(Video(Uri.parse('video')));
        await testPlayable(tester, HomeWidgetPlayable(video, key: homeKey));
      });
    });

    group('MultiMedium', () {
      final homeKey = GlobalKey(debugLabel: 'homeKey');

      void testPlayable(WidgetTester tester, Widget homeWidget) async {
        // We need a MaterialApp to use the Navigator
        await tester.pumpWidget(MaterialApp(home: homeWidget));
        final homeFinder = find.byKey(homeKey);
        expect(homeFinder, findsOneWidget);
        expect(find.byType(MediaPlayer), findsNothing);

        // We tap on the HomeWidget to call playable.play()
        await tester.tap(homeFinder);
        // One pump seems to be needed to process the Navigator.push(), this
        // idiom is also being used in Flutter Navigator tests:
        // https://github.com/flutter/flutter/blob/1.20.3/packages/flutter/test/widgets/navigator_test.dart
        await tester.pump();
        // The second pump we wait a bit because Navigator is animated
        await tester.pump(Duration(seconds: 1));
        expect(find.byKey(homeKey), findsNothing);
        final playerFinder = find.byType(MediaPlayer);
        expect(playerFinder, findsOneWidget);
        final mediaPlayer = tester.widget(playerFinder) as MediaPlayer;
        final context = tester.element(playerFinder);

        // The HomeWidget should be back
        mediaPlayer.onMediaStopped(context); // Should call Navigator.pop()
        await tester.pump(); // Same with .push() about the double pump()
        await tester.pump(Duration(seconds: 1));
        expect(find.byKey(homeKey), findsOneWidget);
        expect(find.byType(MediaPlayer), findsNothing);
      }

      testWidgets('MultiMedium', (WidgetTester tester) async {
        final multimedium = PlayablePlayer.wrap(
          MultiMedium(
            AudibleMultiMediumTrack(
              <Audible>[Video(Uri.parse('video'))],
            ),
            backgroundTrack: VisualizableBackgroundMultiMediumTrack(
              <Visualizable>[Image(Uri.parse('image'))],
            ),
          ),
        );
        await testPlayable(
            tester, HomeWidgetPlayable(multimedium, key: homeKey));
      });
    });
  });
}

class FakeContext extends Fake implements BuildContext {}

class FakePlayable extends Playable {
  Playable calledPlayable;
  BuildContext calledContext;
  Color calledColor;
}

class FakePlayablePlayer extends PlayablePlayer {
  @override
  final FakePlayable playable;
  @override
  void play(BuildContext context, [Color backgroundColor]) {
    playable.calledPlayable = playable;
    playable.calledContext = context;
    playable.calledColor = backgroundColor;
  }

  FakePlayablePlayer(this.playable) : assert(playable != null);
}

class HomeWidgetPlayable extends StatelessWidget {
  final Color color = Colors.red;
  final PlayablePlayer playable;
  const HomeWidgetPlayable(this.playable, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        playable.play(context, color);
      },
      child: Container(
        child: const Text('home'),
      ),
    );
  }
}
