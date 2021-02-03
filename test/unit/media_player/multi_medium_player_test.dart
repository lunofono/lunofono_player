@Tags(['unit', 'player'])

import 'dart:async' show Timer, Completer;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart';
import 'package:lunofono_player/src/media_player/controller_registry.dart';
import 'package:lunofono_player/src/media_player/media_player_error.dart';
import 'package:lunofono_player/src/media_player.dart';

import '../../util/finders.dart' show findSubString;

// XXX: This test should ideally fake the ControllerRegistry, but we can't do so
// now because of a very obscure problem with the dart compiler/flutter test
// driver. For details please see this issue:
// https://github.com/flutter/flutter/issues/65324
void main() {
  group('MultiMediumPlayer', () {
    MediaPlayerTester playerTester;

    tearDown(() => playerTester?.dispose());

    test('constructor asserts on null media', () {
      expect(() => MultiMediumPlayer(medium: null), throwsAssertionError);
    });

    Future<void> testUnregisteredMedium(
        WidgetTester tester, FakeSingleMedium medium) async {
      // TODO: Second medium in a track is unregistered
      final player = MultiMediumPlayer(
        medium: MultiMedium.fromSingleMedium(medium),
      );

      // Since controller creation is done asynchronously, first the progress
      // indicator should always be shown.
      await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: player));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // If we pump again, the controller creation should have failed.
      await tester.pump();
      expect(find.byType(MediaPlayerError), findsOneWidget);
      expect(findSubString('Unsupported type'), findsOneWidget);
    }

    testWidgets(
        'shows a MediaPlayerErrors if audible controller is not registered',
        (WidgetTester tester) async {
      final medium = FakeAudibleSingleMedium(
        'unregisteredAudibleMedium',
        size: Size(0.0, 0.0),
      );
      await testUnregisteredMedium(tester, medium);
    });

    testWidgets(
        'shows a MediaPlayerErrors if visualizable controller is not registered',
        (WidgetTester tester) async {
      final medium = FakeVisualizableSingleMedium(
        'unregisteredVisualizableMedium',
        size: Size(10.0, 10.0),
      );
      await testUnregisteredMedium(tester, medium);
    });

    Future<void> testInitializationError(
        WidgetTester tester, FakeSingleMedium medium) async {
      // TODO: Second medium in a track is unregistered
      playerTester = MediaPlayerTester(tester, medium);

      await playerTester.testInitializationDone();
      playerTester.expectErrorWidget();
      playerTester.expectPlayingStatus(finished: false);
      expect(findSubString(medium.info.exception.toString()), findsOneWidget);
    }

    testWidgets('initializes audible with error', (WidgetTester tester) async {
      final exception = Exception('Initialization Error');
      final medium = FakeAudibleSingleMedium('exceptionAudibleMedium',
          exception: exception);
      await testInitializationError(tester, medium);
    });

    testWidgets('initializes visualizable with error',
        (WidgetTester tester) async {
      final exception = Exception('Initialization Error');
      final medium = FakeVisualizableSingleMedium('exceptionVisualizableMedium',
          exception: exception);
      await testInitializationError(tester, medium);
    });

    testWidgets('player should not be rotated for square visualizable media',
        (WidgetTester tester) async {
      final notRotatedSquareMedium = FakeVisualizableSingleMedium(
        'notRotatedSquareMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );
      playerTester = MediaPlayerTester(tester, notRotatedSquareMedium);

      await playerTester.testInitializationDone();
      playerTester.expectPlayerWidget(rotated: false);
      playerTester.expectPlayingStatus(finished: false);
    });

    testWidgets('player should not be rotated for portrait visualizable media',
        (WidgetTester tester) async {
      final notRotatedPortraitMedium = FakeVisualizableSingleMedium(
        'notRotatedPortraitMedium',
        size: Size(10.0, 20.0),
        duration: Duration(seconds: 1),
      );
      playerTester = MediaPlayerTester(tester, notRotatedPortraitMedium);

      await playerTester.testInitializationDone();
      playerTester.expectPlayerWidget(rotated: false);
      playerTester.expectPlayingStatus(finished: false);
    });

    testWidgets('player should be rotated for landscape visualizable media',
        (WidgetTester tester) async {
      final rotatedLandscapeMedium = FakeVisualizableSingleMedium(
        'rotatedLandscapeMedium',
        size: Size(20.0, 10.0),
        duration: Duration(seconds: 1),
      );
      playerTester = MediaPlayerTester(tester, rotatedLandscapeMedium);

      await playerTester.testInitializationDone();
      playerTester.expectPlayerWidget(rotated: true);
      playerTester.expectPlayingStatus(finished: false);
    });

    Future<void> testPlayMediaUntilEnd(
        WidgetTester tester, FakeSingleMedium medium) async {
      playerTester = MediaPlayerTester(tester, medium);

      await playerTester.testInitializationDone();
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: false);

      // Wait until half of the media was played, it should keep playing
      await tester.pump(medium.info.duration ~/ 2);
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: false);

      // Wait until the media stops playing by itself
      await tester.pump(medium.info.duration ~/ 2);
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: true);
    }

    testWidgets('plays limited audible media until the end',
        (WidgetTester tester) async {
      final medium = FakeAudibleSingleMedium(
        'limitedAudibleMedium',
        size: Size(0.0, 0.0),
        duration: Duration(seconds: 1),
      );
      await testPlayMediaUntilEnd(tester, medium);
    });

    testWidgets('plays limited visualizable media until the end',
        (WidgetTester tester) async {
      final medium = FakeVisualizableSingleMedium(
        'limitedVisualizableMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );
      await testPlayMediaUntilEnd(tester, medium);
    });

    testWidgets('plays unlimited media forever(ish, 10 days)',
        (WidgetTester tester) async {
      final unlimitedMedium = FakeVisualizableSingleMedium('unlimitedMedium',
          size: Size(10.0, 10.0));
      playerTester = MediaPlayerTester(tester, unlimitedMedium);

      await playerTester.testInitializationDone();
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: false);

      // Wait until half of the media was played, it should keep playing
      await tester.pump(Duration(days: 10));
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: false);
    });

    testWidgets('tap stops while initializing', (WidgetTester tester) async {
      final tapInitMedium = FakeVisualizableSingleMedium(
        'tapInitMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
        initDelay: Duration(milliseconds: 100),
      );
      playerTester = MediaPlayerTester(tester, tapInitMedium);

      // The player should be initializing
      await tester.pumpWidget(
          playerTester.player, tapInitMedium.info.initDelay ~/ 2);
      playerTester.expectInitializationWidget();
      playerTester.expectPlayingStatus(finished: false);

      // Tap and the reaction should reach the controller
      final widgetToTap = find.byType(CircularProgressIndicator);
      expect(widgetToTap, findsOneWidget);
      await tester.tap(widgetToTap);
      await tester.pump();
      playerTester.expectInitializationWidget();
      playerTester.expectPlayingStatus(
          finished: false, stoppedTimes: 1, paused: true);
    });

    testWidgets('tap stops while playing', (WidgetTester tester) async {
      final tapPlayMedium = FakeVisualizableSingleMedium(
        'PlaynitMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );
      playerTester = MediaPlayerTester(tester, tapPlayMedium);

      await playerTester.testInitializationDone();
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: false);

      // Wait until half of the media was played, it should keep playing
      await tester.pump(tapPlayMedium.info.duration ~/ 2);
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: false);

      // Tap and the player should stop
      var widgetToTap = find.byKey(tapPlayMedium.info.widgetKey);
      expect(widgetToTap, findsOneWidget);
      await tester.tap(widgetToTap);
      await tester.pump();
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(
          finished: false, stoppedTimes: 1, paused: true);

      // Tap again should do nothing new (but to call the onMediaStopped
      // callback again).
      widgetToTap = find.byKey(tapPlayMedium.info.widgetKey);
      expect(widgetToTap, findsOneWidget);
      await tester.tap(widgetToTap);
      await tester.pump();
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(
          finished: false, stoppedTimes: 2, paused: true);
    });

    testWidgets('tap does nothing when playing is done',
        (WidgetTester tester) async {
      final tapPlayDoneMedium = FakeVisualizableSingleMedium(
        'tapPlayDoneMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );
      playerTester = MediaPlayerTester(tester, tapPlayDoneMedium);

      await playerTester.testInitializationDone();
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: false);

      // Wait until the media stops playing by itself
      await tester.pump(tapPlayDoneMedium.info.duration);
      playerTester.expectPlayerWidget();
      playerTester.expectPlayingStatus(finished: true);

      // Tap again should do nothing but to get a reaction
      final widgetToTap = find.byKey(tapPlayDoneMedium.info.widgetKey);
      expect(widgetToTap, findsOneWidget);
      await tester.tap(widgetToTap);
      await tester.pump();
      playerTester.expectPlayerWidget();
      // In this case it should not be paused, because pause() is only called if
      // the medium didn't finished by itself.
      playerTester.expectPlayingStatus(finished: true, stoppedTimes: 2);
    });

    testWidgets('initialization of visualizable multi-medium mainTrack',
        (WidgetTester tester) async {
      final medium1 = FakeAudibleVisualizableSingleMedium(
        'medium1(audible, visualizable)',
        size: Size(20.0, 10.0),
        duration: Duration(seconds: 7),
        initDelay: Duration(seconds: 2),
      );

      final medium2 = FakeVisualizableSingleMedium(
        'medium2(visualizable)',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
        initDelay: Duration(seconds: 1),
      );

      final medium3 = FakeVisualizableSingleMedium(
        'medium3(visualizable)',
        size: Size(10.0, 20.0),
        duration: Duration(seconds: 1),
        initDelay: Duration(seconds: 3),
      );

      final medium = MultiMedium(
        VisualizableMultiMediumTrack(<Visualizable>[medium1, medium2, medium3]),
      );

      playerTester = MediaPlayerTester(tester, medium);

      final mainTrack = List<FakeSingleMedium>.from(medium.mainTrack.media
          .map<FakeSingleMedium>((m) => m as FakeSingleMedium));

      // The first time the player is pumped, it should be initializing.
      await tester.pumpWidget(playerTester.player);
      playerTester.expectMultiTrackIsInitialzing();

      // Initialization (since it's done in parallel) should take the time it
      // takes to the medium with the maximum initialization time.
      // We'll test this by first waiting for the medium that has the shorter
      // initialization time, the widget should be still initializing. Then wait
      // halfway to the maximum initialization, it should be still initializing,
      // then one millisecond before the maximum initialization, still
      // initializing. Then after the maximum it should be done initializing.
      final minInit = mainTrack
          .map((m) => m.info.initDelay)
          .reduce((d1, d2) => d1 < d2 ? d1 : d2);
      final maxInit = mainTrack
          .map((m) => m.info.initDelay)
          .reduce((d1, d2) => d1 > d2 ? d1 : d2);

      var left = Duration(milliseconds: maxInit.inMilliseconds);
      final pump = (Duration t) async {
        await tester.pump(t);
        left -= t;
      };

      await pump(minInit);
      playerTester.expectMultiTrackIsInitialzing();
      await pump(left ~/ 2);
      playerTester.expectMultiTrackIsInitialzing();
      await pump(left - Duration(milliseconds: 1));
      playerTester.expectMultiTrackIsInitialzing();
      await pump(Duration(milliseconds: 1));

      // Now the first medium should have started playing and not be finished
      playerTester.expectPlayerWidget(mainMediumIndex: 0);
      playerTester.expectPlayingStatus(mainMediumIndex: 0, finished: false);
      expect(playerTester.mainControllers.first.isPlaying, isTrue);

      // And the following media should have not started nor finished
      playerTester.mainTrackIndexes.skip(1).forEach((n) => playerTester
          .expectPlayingStatus(mainMediumIndex: n, finished: false));
      playerTester.mainTrackIndexes.skip(1).forEach(
          (n) => expect(playerTester.mainControllers[n].isPlaying, isFalse));
    });

    testWidgets('plays a audible multi-medium mainTrack until the end',
        (WidgetTester tester) async {
      final medium1 = FakeAudibleSingleMedium(
        'medium1(audible)',
        size: Size(0.0, 0.0),
        duration: Duration(seconds: 1),
      );

      final medium2 = FakeAudibleVisualizableSingleMedium(
        'medium2(audible, visualizable)',
        size: Size(10.0, 20.0),
        duration: Duration(seconds: 7),
      );

      final multiAudibleMainTrackMedium = MultiMedium(
        AudibleMultiMediumTrack(<Audible>[medium1, medium2]),
      );

      playerTester = MediaPlayerTester(tester, multiAudibleMainTrackMedium);
      await playerTester.testMultiTrackPlay(untilFinished: true);
    });

    testWidgets('plays a visualizable multi-medium mainTrack until the end',
        (WidgetTester tester) async {
      final medium1 = FakeAudibleVisualizableSingleMedium(
        'medium1(audible, visualizable)',
        size: Size(20.0, 10.0),
        duration: Duration(seconds: 7),
      );

      final medium2 = FakeVisualizableSingleMedium(
        'medium2(visualizable)',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );

      final medium3 = FakeVisualizableSingleMedium(
        'medium3(visualizable)',
        size: Size(10.0, 20.0),
        duration: Duration(seconds: 1),
      );

      final multiVisualizableMainTrackMedium = MultiMedium(
        VisualizableMultiMediumTrack(<Visualizable>[medium1, medium2, medium3]),
      );

      playerTester =
          MediaPlayerTester(tester, multiVisualizableMainTrackMedium);
      await playerTester.testMultiTrackPlay(untilFinished: true);
    });

    testWidgets(
        'plays an audible multi-medium mainTrack with the same medium 2 times',
        (WidgetTester tester) async {
      final medium1 = FakeAudibleSingleMedium(
        'medium1(audible)',
        size: Size(0.0, 0.0),
        duration: Duration(seconds: 1),
      );

      final medium = MultiMedium(
        AudibleMultiMediumTrack(<Audible>[medium1, medium1]),
      );

      playerTester = MediaPlayerTester(tester, medium);
      await playerTester.testMultiTrackPlay(untilFinished: true);
    });

    testWidgets(
        'plays a visualizable multi-medium mainTrack with the same medium 2 times',
        (WidgetTester tester) async {
      final medium1 = FakeVisualizableSingleMedium(
        'medium1(audible)',
        size: Size(0.0, 0.0),
        duration: Duration(seconds: 1),
      );

      final medium = MultiMedium(
        VisualizableMultiMediumTrack(<Visualizable>[medium1, medium1]),
      );

      playerTester = MediaPlayerTester(tester, medium);
      await playerTester.testMultiTrackPlay(untilFinished: true);
    });

    testWidgets('tap stops while playing the second medium',
        (WidgetTester tester) async {
      final medium1 = FakeAudibleVisualizableSingleMedium(
        'medium1(audible, visualizable)',
        size: Size(20.0, 10.0),
        duration: Duration(seconds: 7),
      );

      final medium2 = FakeVisualizableSingleMedium(
        'medium2(visualizable)',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );

      final medium3 = FakeVisualizableSingleMedium(
        'medium3(visualizable)',
        size: Size(10.0, 20.0),
        duration: Duration(seconds: 1),
      );

      final multiVisualizableMainTrackMedium = MultiMedium(
        VisualizableMultiMediumTrack(<Visualizable>[medium1, medium2, medium3]),
      );

      playerTester =
          MediaPlayerTester(tester, multiVisualizableMainTrackMedium);
      await playerTester.testMultiTrackPlay(untilMainIndex: 1); // plays medium1

      // Now medim2 (index 1) should be playing (and the only one), prev media
      // finished and next media not finished
      playerTester.expectPlayerWidget(mainMediumIndex: 1);
      playerTester.expectPlayingStatus(
          mainMediumIndex: 0, finished: true, stoppedTimes: 0);
      expect(playerTester.mainControllers[0].isPlaying, isFalse);
      playerTester.expectPlayingStatus(mainMediumIndex: 1, finished: false);
      expect(playerTester.mainControllers[1].isPlaying, isTrue);
      playerTester.expectPlayingStatus(mainMediumIndex: 2, finished: false);
      expect(playerTester.mainControllers[2].isPlaying, isFalse);

      // Play medium2 halfway
      await tester.pump(medium2.info.duration ~/ 2);
      playerTester.expectPlayerWidget(mainMediumIndex: 1);
      playerTester.expectPlayingStatus(
          mainMediumIndex: 0, finished: true, stoppedTimes: 0);
      playerTester.expectPlayingStatus(mainMediumIndex: 1, finished: false);
      expect(playerTester.mainControllers[1].isPlaying, isTrue);
      playerTester.expectPlayingStatus(mainMediumIndex: 2, finished: false);

      // Tap and the player should stop
      var widgetToTap = find.byKey(medium2.info.widgetKey);
      expect(widgetToTap, findsOneWidget);
      await tester.tap(widgetToTap);
      await tester.pump();
      playerTester.expectPlayerWidget(mainMediumIndex: 1);
      // medium1 should be finished and the MultiMediumPlayer should have
      // stopped
      playerTester.expectPlayingStatus(
          mainMediumIndex: 0, finished: true, stoppedTimes: 1);
      // medium2 and medium3 should NOT be finished (and the MultiMediumPlayer
      // should have stopped). medium2's controller should have received the
      // stop reaction.
      playerTester.expectPlayingStatus(
          mainMediumIndex: 1, finished: false, stoppedTimes: 1, paused: true);
      playerTester.expectPlayingStatus(
          mainMediumIndex: 2, finished: false, stoppedTimes: 1);
    });
  });
}

/// A [MultiMediumPlayer] tester.
///
/// This class provide 3 main family of useful methods:
///
/// * testXxx(): test a common part of the lifecycle, awaiting to
///   tester.pump*().
///
/// * expectXxxWidget(): uses several expect() calls to verify what kind of
///   widget is being shown.
///
/// * expectPlayingStatus(): checks the player status (if it is playing or not,
///   if there were reactions...
class MediaPlayerTester {
  // Taken by the constructor
  final WidgetTester tester;
  final MultiMedium medium;

  // Automatically initialized
  final ControllerRegistry originalRegistry;
  final mainControllers = <FakeSingleMediumController>[];
  Widget player;
  var playerHasStoppedTimes = 0;

  // Constant
  final playerKey = GlobalKey(debugLabel: 'playerKey');

  MediaPlayerTester(this.tester, Medium medium)
      : assert(tester != null),
        assert(medium != null),
        assert(medium is SingleMedium || medium is MultiMedium),
        originalRegistry = ControllerRegistry.instance,
        medium = medium is SingleMedium
            ? MultiMedium.fromSingleMedium(medium)
            : medium as MultiMedium {
    _registerControllers();
    player = _createPlayer();
  }

  void dispose() {
    ControllerRegistry.instance = originalRegistry;
    for (final c in mainControllers) {
      c.dispose();
    }
  }

  void _registerControllers() {
    SingleMediumController createController(SingleMedium medium,
        {void Function(BuildContext) onMediumFinished}) {
      final fakeMedium = medium as FakeSingleMedium;
      final c = FakeSingleMediumController(
          fakeMedium, onMediumFinished, fakeMedium.info.widgetKey);
      mainControllers.add(c);
      return c;
    }

    final registry = ControllerRegistry();
    registry.register(FakeAudibleSingleMedium, createController);
    registry.register(FakeVisualizableSingleMedium, createController);
    registry.register(FakeAudibleVisualizableSingleMedium, createController);
    ControllerRegistry.instance = registry;
  }

  Widget _createPlayer() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MultiMediumPlayer(
        medium: medium,
        backgroundColor: Colors.red,
        onMediaStopped: (context) {
          playerHasStoppedTimes++;
        },
        key: playerKey,
      ),
    );
  }

  FakeSingleMedium getMainMediumAt(int index) {
    assert(index != null && index >= 0);
    return medium.mainTrack.media[index] as FakeSingleMedium;
  }

  FakeSingleMediumController getMainControllerAt(int index) {
    assert(index != null && index >= 0);
    return index < mainControllers.length ? mainControllers[index] : null;
  }

  Future<void> testInitializationDone({int mainMediumIndex = 0}) async {
    final currentMedium = getMainMediumAt(mainMediumIndex);
    // The player should be initializing
    await tester.pumpWidget(player);
    expectInitializationWidget(mainMediumIndex: mainMediumIndex);
    expectPlayingStatus(mainMediumIndex: mainMediumIndex, finished: false);

    // After half of the initialization time, it keeps initializing
    await tester.pump(currentMedium.info.initDelay ~/ 2);
    expectInitializationWidget(mainMediumIndex: mainMediumIndex);
    expectPlayingStatus(mainMediumIndex: mainMediumIndex, finished: false);

    // Wait until it is initialized and it should show the player or the
    // exception
    await tester.pump(currentMedium.info.initDelay ~/ 2);
  }

  Iterable<int> get mainTrackIndexes =>
      Iterable<int>.generate(medium.mainTrack.media.length);

  /// Test that all media in the mainTrack is played, until it finished or some
  /// index.
  ///
  /// If [untilMainIndex] is used, it will play until the media with
  /// [untilMainIndex] exclusively (the medium at that index won't be played, it
  /// will be left when the previous medium was finished playing.
  ///
  /// Either [untilMainIndex] or [untilFinished] must be specified. If
  /// [untilFinished] is used, it must be true and it is an alias for
  /// [untilMainIndex] = mainTrack.media.length.
  Future<void> testMultiTrackPlay(
      {int untilMainIndex, bool untilFinished}) async {
    final mainTrack = List<FakeSingleMedium>.from(medium.mainTrack.media
        .map<FakeSingleMedium>((m) => m as FakeSingleMedium));

    assert(untilMainIndex != null || untilFinished == true);
    if (untilFinished == true) {
      untilMainIndex = mainTrack.length;
    }

    // We pump the player widget, it should be initializing
    await tester.pumpWidget(player);
    expectMultiTrackIsInitialzing();

    // Now pump the time it takes the medium with the maximum initialization
    // time (as initialization is done in parallel, all should have finished
    // initializing after that).
    final maxInit = mainTrack
        .map((m) => m.info.initDelay)
        .reduce((d1, d2) => d1 > d2 ? d1 : d2);
    await tester.pump(maxInit);

    // Now the first medium should have started playing (and only the first
    // medium) but nothing should have finished yet.
    expect(mainControllers.first.isPlaying, isTrue);
    mainTrackIndexes.forEach(
        (n) => expectPlayingStatus(mainMediumIndex: n, finished: false));
    mainTrackIndexes
        .skip(1)
        .forEach((n) => expect(mainControllers[n].isPlaying, isFalse));

    // Now the first media should be playing and we check all media plays in
    // sequence.
    for (var currentIndex = 0; currentIndex < untilMainIndex; currentIndex++) {
      final current = mainTrack[currentIndex];
      final prev = mainTrackIndexes.take(currentIndex);
      final next = mainTrackIndexes.skip(currentIndex + 1);

      // We start when the current medium started playing, so the widget should
      // be showing
      expectPlayerWidget(mainMediumIndex: currentIndex);
      // The previous media should have finished and not be playing.
      prev.forEach((p) => expectPlayingStatus(
          mainMediumIndex: p, finished: true, stoppedTimes: 0));
      prev.forEach((n) => expect(mainControllers[n].isPlaying, isFalse));
      // The current should be playing and not finished.
      expectPlayingStatus(mainMediumIndex: currentIndex, finished: false);
      expect(mainControllers[currentIndex].isPlaying, isTrue);
      // And the following should be neither playing nor finished.
      next.forEach(
          (n) => expectPlayingStatus(mainMediumIndex: n, finished: false));
      next.forEach((n) => expect(mainControllers[n].isPlaying, isFalse));

      // Wait until the current finishes playing
      await tester.pump(current.info.duration);
    }

    // Only check for the last conditions
    if (untilMainIndex == mainTrack.length) {
      // After all media was played, the last medium should still be shown
      expectPlayerWidget(mainMediumIndex: mainTrack.length - 1);
      // All the media should be finished, the MultiMediumPlayer should be
      // stopped.
      mainTrack.asMap().keys.forEach((m) => expectPlayingStatus(
          mainMediumIndex: m, finished: true, stoppedTimes: 1));
    }
  }

  void _expectMediumWidget(FakeSingleMedium expectedMedium) {
    for (final m in medium.mainTrack.media) {
      expect(find.byKey((m as FakeSingleMedium).info.widgetKey),
          identical(m, expectedMedium) ? findsOneWidget : findsNothing);
    }
  }

  void expectMultiTrackIsInitialzing() {
    expectInitializationWidget(mainMediumIndex: 0);
    // All media shouldn't be finished yet
    mainTrackIndexes.forEach(
        (n) => expectPlayingStatus(mainMediumIndex: n, finished: false));
    // and shouldn't be playing
    mainTrackIndexes
        .forEach((n) => expect(mainControllers[n].isPlaying, isFalse));
  }

  void expectInitializationWidget({int mainMediumIndex = 0}) {
    final currentMedium = getMainMediumAt(mainMediumIndex);
    final currentController = getMainControllerAt(mainMediumIndex);
    assert(currentMedium != null);
    assert(currentController != null);
    assert(currentController.medium != null);
    expect(currentController.medium.resource, currentMedium.resource);
    expect(find.byKey(playerKey), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MediaPlayerError), findsNothing);
    expect(
        findSubString(currentMedium.info.exception.toString()), findsNothing);
    expect(find.byType(RotatedBox), findsNothing);
    _expectMediumWidget(null);
  }

  void _expectPlayerInitializationDone({int mainMediumIndex = 0}) {
    final currentMedium = getMainMediumAt(mainMediumIndex);
    final currentController = getMainControllerAt(mainMediumIndex);
    expect(currentController.medium.resource, currentMedium.resource);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(playerKey), findsOneWidget);
  }

  void expectErrorWidget({int mainMediumIndex = 0}) {
    final currentMedium = getMainMediumAt(mainMediumIndex);
    _expectPlayerInitializationDone(mainMediumIndex: mainMediumIndex);
    _expectMediumWidget(null);
    expect(find.byType(MediaPlayerError), findsOneWidget);
    expect(currentMedium.info.size, isNull);
  }

  void expectPlayerWidget({int mainMediumIndex = 0, bool rotated}) {
    final currentMedium = getMainMediumAt(mainMediumIndex);
    _expectPlayerInitializationDone(mainMediumIndex: mainMediumIndex);
    _expectMediumWidget(currentMedium);
    expect(find.byType(MediaPlayerError), findsNothing);
    expect(
        findSubString(currentMedium.info.exception.toString()), findsNothing);
    if (rotated != null) {
      expect(find.byType(RotatedBox), rotated ? findsOneWidget : findsNothing);
    }
  }

  void expectPlayingStatus({
    int mainMediumIndex = 0,
    @required bool finished,
    int stoppedTimes,
    bool paused = false,
  }) {
    // TODO: add check for isPlaying.
    final currentMedium = getMainMediumAt(mainMediumIndex);
    final currentController = getMainControllerAt(mainMediumIndex);
    stoppedTimes = stoppedTimes ?? (finished ? 1 : 0);
    expect(playerHasStoppedTimes, stoppedTimes,
        reason: '  Medium: ${currentMedium.resource}\n  Key: stoppedTimes');
    // If it is null, then it wasn't created yet, so the medium wasn't really
    // played yet and didn't receive any reactions
    expect(currentController?.finishedTimes ?? 0, finished ? 1 : 0,
        reason: '  Medium: ${currentMedium.resource}\n  Key: finishedTimes');
    expect(currentController?.isPaused ?? false, paused,
        reason: '  Medium: ${currentMedium.resource}');
  }
}

class SingleMediumInfo {
  final Size size;
  final Duration duration;
  final Duration initDelay;
  final Exception exception;
  final Key widgetKey;
  SingleMediumInfo(
    String location, {
    this.size,
    this.exception,
    Duration duration,
    Duration initDelay,
  })  : assert(exception != null && size == null ||
            exception == null && size != null),
        initDelay = initDelay ?? const Duration(seconds: 1),
        duration = duration ?? const UnlimitedDuration(),
        widgetKey = GlobalKey(debugLabel: 'widgetKey(${location}');
}

abstract class FakeSingleMedium extends SingleMedium {
  final SingleMediumInfo info;
  FakeSingleMedium(
    String location, {
    Duration maxDuration,
    Size size,
    Exception exception,
    Duration duration,
    Duration initDelay,
  })  : info = SingleMediumInfo(location,
            size: size,
            exception: exception,
            duration: duration,
            initDelay: initDelay),
        super(Uri.parse(location), maxDuration: maxDuration);
}

class FakeAudibleSingleMedium extends FakeSingleMedium implements Audible {
  FakeAudibleSingleMedium(
    String location, {
    Duration maxDuration,
    Size size,
    Exception exception,
    Duration duration,
    Duration initDelay,
  }) : super(location,
            maxDuration: maxDuration,
            size: size,
            exception: exception,
            duration: duration,
            initDelay: initDelay);
}

class FakeVisualizableSingleMedium extends FakeSingleMedium
    implements Visualizable {
  FakeVisualizableSingleMedium(
    String location, {
    Duration maxDuration,
    Size size,
    Exception exception,
    Duration duration,
    Duration initDelay,
  }) : super(location,
            maxDuration: maxDuration,
            size: size,
            exception: exception,
            duration: duration,
            initDelay: initDelay);
}

class FakeAudibleVisualizableSingleMedium extends FakeSingleMedium
    implements Audible, Visualizable {
  FakeAudibleVisualizableSingleMedium(
    String location, {
    Duration maxDuration,
    Size size,
    Exception exception,
    Duration duration,
    Duration initDelay,
  }) : super(location,
            maxDuration: maxDuration,
            size: size,
            exception: exception,
            duration: duration,
            initDelay: initDelay);
}

class FakeSingleMediumController extends Fake
    implements SingleMediumController {
  // Internal state
  Timer _initTimer;
  bool get isInitializing => _initTimer?.isActive ?? false;
  Timer _playingTimer;
  bool get isPlaying => _playingTimer?.isActive ?? false;
  final _initCompleter = Completer<Size>();
  // State to do checks
  bool get initError => medium.info.exception != null;
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;
  int _finishedTimes = 0;
  int get finishedTimes => _finishedTimes;
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void Function(BuildContext) playerOnMediaStopped;

  @override
  FakeSingleMedium medium;

  @override
  Key widgetKey;

  FakeSingleMediumController(
    this.medium,
    this.playerOnMediaStopped,
    this.widgetKey,
  ) : assert(medium != null);

  @override
  Future<Size> initialize(BuildContext context) {
    _initTimer = Timer(medium.info.initDelay, () {
      if (initError) {
        try {
          throw medium.info.exception;
        } catch (e, stack) {
          _initCompleter.completeError(e, stack);
        }
        return;
      }
      _initCompleter.complete(medium.info.size);
    });

    return _initCompleter.future;
  }

  @override
  Future<void> play(BuildContext context) {
    // TODO: test play errors
    // Trigger onFinished after the duration of the media to simulate
    // a natural stop if a duration is set
    if (medium.info.duration is! UnlimitedDuration) {
      _playingTimer = Timer(medium.info.duration, () {
        onMediumFinished(context);
      });
    }
    return Future<void>.value();
  }

  @override
  Future<void> dispose() async {
    _initTimer?.cancel();
    _playingTimer?.cancel();
    _isDisposed = true;
  }

  @override
  Future<void> pause(BuildContext context) async {
    _isPaused = true;
  }

  @override
  void Function(BuildContext) get onMediumFinished => (BuildContext context) {
        _finishedTimes++;
        playerOnMediaStopped(context);
      };

  @override
  Widget build(BuildContext context) => Container(key: widgetKey);
}
