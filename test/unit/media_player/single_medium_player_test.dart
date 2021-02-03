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
  group('SingleMediumPlayer', () {
    _SingleMediumPlayerTester playerTester;

    tearDown(() => playerTester?.dispose());

    test('constructor asserts on null media', () {
      expect(() => SingleMediumPlayer(medium: null), throwsAssertionError);
    });

    Future<void> testUnregisteredMedium(
        WidgetTester tester, _FakeSingleMedium medium) async {
      // TODO: Second medium in a track is unregistered
      final player = SingleMediumPlayer(medium: medium);

      await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: player));
      expect(find.byType(MediaPlayerError), findsOneWidget);
      expect(findSubString('Unsupported type'), findsOneWidget);
    }

    testWidgets(
        'shows a MediaPlayerErrors if audible controller is not registered',
        (WidgetTester tester) async {
      final medium = _FakeAudibleSingleMedium(
        'unregisteredAudibleMedium',
        size: Size(0.0, 0.0),
      );
      await testUnregisteredMedium(tester, medium);
    });

    testWidgets(
        'shows a MediaPlayerErrors if visualizable controller is not registered',
        (WidgetTester tester) async {
      final medium = _FakeVisualizableSingleMedium(
        'unregisteredVisualizableMedium',
        size: Size(10.0, 10.0),
      );
      await testUnregisteredMedium(tester, medium);
    });

    testWidgets('tap stops while initializing', (WidgetTester tester) async {
      final tapInitMedium = _FakeVisualizableSingleMedium(
        'tapInitMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
        initDelay: Duration(milliseconds: 100),
      );
      playerTester = _SingleMediumPlayerTester(tester, tapInitMedium);

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
      final tapPlayMedium = _FakeVisualizableSingleMedium(
        'tapPlayMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );
      playerTester = _SingleMediumPlayerTester(tester, tapPlayMedium);

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
      final tapPlayDoneMedium = _FakeVisualizableSingleMedium(
        'tapPlayDoneMedium',
        size: Size(10.0, 10.0),
        duration: Duration(seconds: 1),
      );
      playerTester = _SingleMediumPlayerTester(tester, tapPlayDoneMedium);

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
      playerTester.expectPlayingStatus(
          finished: true, paused: true, stoppedTimes: 2);
    });
  });
}

/// A [SingleMediumPlayer] tester.
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
class _SingleMediumPlayerTester {
  // Taken by the constructor
  final WidgetTester tester;
  final _FakeSingleMedium medium;

  // Automatically initialized
  final ControllerRegistry originalRegistry;
  _FakeSingleMediumController controller;
  Widget player;
  var playerHasStoppedTimes = 0;

  // Constant
  final playerKey = GlobalKey(debugLabel: 'playerKey');

  _SingleMediumPlayerTester(this.tester, this.medium)
      : assert(tester != null),
        assert(medium != null),
        originalRegistry = ControllerRegistry.instance {
    _registerController();
    player = _createPlayer();
  }

  void dispose() {
    controller?.dispose();
    ControllerRegistry.instance = originalRegistry;
  }

  void _registerController() {
    SingleMediumController createController(SingleMedium medium,
        {void Function(BuildContext) onMediumFinished}) {
      final fakeMedium = medium as _FakeSingleMedium;
      final c = _FakeSingleMediumController(
          fakeMedium, onMediumFinished, fakeMedium.info.widgetKey);
      controller = c;
      return c;
    }

    final registry = ControllerRegistry();
    registry.register(_FakeAudibleSingleMedium, createController);
    registry.register(_FakeVisualizableSingleMedium, createController);
    registry.register(_FakeAudibleVisualizableSingleMedium, createController);
    ControllerRegistry.instance = registry;
  }

  Widget _createPlayer() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SingleMediumPlayer(
        medium: medium,
        backgroundColor: Colors.red,
        onMediaStopped: (context) {
          playerHasStoppedTimes++;
        },
        key: playerKey,
      ),
    );
  }

  Future<void> testInitializationDone() async {
    // The player should be initializing
    await tester.pumpWidget(player);
    expectInitializationWidget();
    expectPlayingStatus(finished: false);

    // After half of the initialization time, it keeps initializing
    await tester.pump(medium.info.initDelay ~/ 2);
    expectInitializationWidget();
    expectPlayingStatus(finished: false);

    // Wait until it is initialized and it should show the player or the
    // exception
    await tester.pump(medium.info.initDelay ~/ 2);
  }

  void expectInitializationWidget() {
    assert(medium != null);
    assert(controller != null);
    assert(controller.medium != null);
    expect(controller.medium.resource, medium.resource);
    expect(find.byKey(playerKey), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MediaPlayerError), findsNothing);
    expect(findSubString(medium.info.exception.toString()), findsNothing);
    expect(find.byType(RotatedBox), findsNothing);
    expect(find.byKey(medium.info.widgetKey), findsNothing);
  }

  void _expectPlayerInitializationDone() {
    expect(controller.medium.resource, medium.resource);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(playerKey), findsOneWidget);
  }

  void expectPlayerWidget({int mainMediumIndex = 0, bool rotated}) {
    _expectPlayerInitializationDone();
    expect(find.byKey(medium.info.widgetKey), findsOneWidget);
    expect(find.byType(MediaPlayerError), findsNothing);
    expect(findSubString(medium.info.exception.toString()), findsNothing);
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
    stoppedTimes = stoppedTimes ?? (finished ? 1 : 0);
    expect(playerHasStoppedTimes, stoppedTimes,
        reason: '  Medium: ${medium.resource}\n  Key: stoppedTimes');
    // If it is null, then it wasn't created yet, so the medium wasn't really
    // played yet and didn't receive any reactions
    expect(controller?.finishedTimes ?? 0, finished ? 1 : 0,
        reason: '  Medium: ${medium.resource}\n  Key: finishedTimes');
    expect(controller?.isPaused ?? false, paused,
        reason: '  Medium: ${medium.resource}');
  }
}

class _SingleMediumInfo {
  final Size size;
  final Duration duration;
  final Duration initDelay;
  final Exception exception;
  final Key widgetKey;
  _SingleMediumInfo(
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

abstract class _FakeSingleMedium extends SingleMedium {
  final _SingleMediumInfo info;
  _FakeSingleMedium(
    String location, {
    Duration maxDuration,
    Size size,
    Exception exception,
    Duration duration,
    Duration initDelay,
  })  : info = _SingleMediumInfo(location,
            size: size,
            exception: exception,
            duration: duration,
            initDelay: initDelay),
        super(Uri.parse(location), maxDuration: maxDuration);
}

class _FakeAudibleSingleMedium extends _FakeSingleMedium implements Audible {
  _FakeAudibleSingleMedium(
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

class _FakeVisualizableSingleMedium extends _FakeSingleMedium
    implements Visualizable {
  _FakeVisualizableSingleMedium(
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

class _FakeAudibleVisualizableSingleMedium extends _FakeSingleMedium
    implements Audible, Visualizable {
  _FakeAudibleVisualizableSingleMedium(
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

class _FakeSingleMediumController extends Fake
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
  _FakeSingleMedium medium;

  @override
  Key widgetKey;

  _FakeSingleMediumController(
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
