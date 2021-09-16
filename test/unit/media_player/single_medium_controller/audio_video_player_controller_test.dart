@Tags(['unit', 'player'])

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;
import 'package:pedantic/pedantic.dart' show unawaited;

import 'package:video_player/video_player.dart' as video_player;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show SingleMedium, Audio, Video;
import 'package:lunofono_player/src/media_player/single_medium_controller.dart';

import 'single_medium_controller_common.dart';
import '../../../util/finders.dart' show findSubString;

FakeVideoInfo? globalFakeInfo;

class _FakeContext extends Fake implements BuildContext {}

void main() {
  group('VideoPlayerController', () {
    final video = Video(Uri.parse('fake-video.avi'));

    late TestVideoPlayerController controller;
    tearDown(() async => await controller.dispose());

    test('can instantiate a video_player.VideoPlayerController', () async {
      controller = TestVideoPlayerController(video, null);
      final internalController = controller.testCreateVideoPlayerController();
      expect(internalController, isA<video_player.VideoPlayerController>());
      expect(internalController.dataSource, video.resource.toString());
    });

    testWidgets(
      'errors in initialize()',
      (WidgetTester tester) async {
        var hasFinished = false;
        controller = TestVideoPlayerController(
          video,
          FakeVideoInfo.initError('Initialization error'),
          onMediumFinished: (context) => hasFinished = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, false);

        await tester.pumpAndSettle();
        expectInitError(tester, widget);
        expect(findSubString(globalFakeInfo!.initError), findsOneWidget);
        expect(controller.value.isPlaying, false);
        expect(hasFinished, false);
      },
    );

    testWidgets(
      'errors in play()',
      (WidgetTester tester) async {
        var hasFinished = false;
        final videoInfo = FakeVideoInfo.playError();
        controller = TestVideoPlayerController(
          video,
          videoInfo,
          onMediumFinished: (context) => hasFinished = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);
        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, false);

        await tester.pumpAndSettle();
        expectPlayError(tester, widget);
        expect(globalSize, videoInfo.size);
        expect(findSubString(globalFakeInfo!.playError), findsOneWidget);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, false);
      },
    );

    testWidgets(
      'initializes and plays a video until the end',
      (WidgetTester tester) async {
        final videoInfo = FakeVideoInfo(
          Duration(milliseconds: 1000),
          Size(10.0, 20.0),
        );
        var hasFinished = false;
        controller = TestVideoPlayerController(
          video,
          videoInfo,
          onMediumFinished: (context) => hasFinished = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, false);

        // Since loading is emulated, in the next frame it should be ready.
        // Video should start playing.
        final fakeController =
            controller.controller as _FakeVideoPlayerController;
        await tester.pump(fakeController.initDelay);
        expectSuccess(tester, widget,
            size: videoInfo.size, findWidget: video_player.VideoPlayer);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, true);

        // Emulate the video almost ended playing
        final seekPosition = Duration(
            milliseconds: globalFakeInfo!.duration!.inMilliseconds - 1);
        fakeController.fakeSeekTo(seekPosition);
        await tester.pump(seekPosition);
        expectSuccess(tester, widget,
            size: videoInfo.size, findWidget: video_player.VideoPlayer);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, true);

        // Emulate video completed playing.
        fakeController.fakeSeekToEnd();

        // Advance frames until there are no more changes, so the video should
        // have stopped and the onMediumFinished callback should have been
        // called.
        await tester.pumpAndSettle();
        expectSuccess(tester, widget, findWidget: video_player.VideoPlayer);
        expect(hasFinished, true);
        expect(controller.value.isPlaying, false);
      },
    );

    testWidgets(
      'initializes and plays a video with a maxDuration until the end',
      (WidgetTester tester) async {
        final videoInfo = FakeVideoInfo(
          Duration(milliseconds: 1000),
          Size(10.0, 20.0),
        );
        var hasFinished = false;
        final limitedVideo = Video(
          Uri.parse('fake-video.avi'),
          maxDuration: Duration(milliseconds: 600),
        );
        controller = TestVideoPlayerController(
          limitedVideo,
          videoInfo,
          onMediumFinished: (context) => hasFinished = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, false);

        final fakeController =
            controller.controller as _FakeVideoPlayerController;
        await tester.pump(fakeController.initDelay);
        expectSuccess(tester, widget,
            size: videoInfo.size, findWidget: video_player.VideoPlayer);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, true);

        // Emulate the video playing for almost maxDuration
        var seekPosition =
            Duration(milliseconds: limitedVideo.maxDuration.inMilliseconds - 1);
        fakeController.fakeSeekTo(seekPosition);
        await tester.pump(seekPosition);
        expectSuccess(tester, widget,
            size: videoInfo.size, findWidget: video_player.VideoPlayer);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, true);

        // Now go past the maxDuration
        seekPosition =
            Duration(milliseconds: limitedVideo.maxDuration.inMilliseconds + 1);
        fakeController.fakeSeekTo(seekPosition);
        await tester.pump(Duration(milliseconds: 2));

        // The video should be paused and onMediumFinished called
        expectSuccess(tester, widget, findWidget: video_player.VideoPlayer);
        expect(hasFinished, true);
        expect(controller.value.isPlaying, false);
      },
    );

    testWidgets(
      'initializes and plays a video until the user reacts',
      (WidgetTester tester) async {
        final videoInfo = FakeVideoInfo(
          Duration(milliseconds: 1000),
          Size(1024.0, 768.0),
        );
        var hasFinished = false;
        controller = TestVideoPlayerController(
          video,
          videoInfo,
          onMediumFinished: (context) => hasFinished = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, false);

        // Since loading is emulated, in the next frame it should be ready.
        // Video should start playing.
        final fakeController =
            controller.controller as _FakeVideoPlayerController;
        await tester.pump(fakeController.initDelay);
        expectSuccess(tester, widget,
            size: videoInfo.size, findWidget: video_player.VideoPlayer);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, true);

        // Emulate the video played halfway
        final seekPosition = Duration(
            milliseconds: globalFakeInfo!.duration!.inMilliseconds ~/ 2);
        fakeController.fakeSeekTo(seekPosition);
        await tester.pump(seekPosition);
        expectSuccess(tester, widget,
            size: videoInfo.size, findWidget: video_player.VideoPlayer);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, true);

        // Pause the video
        // XXX: we have to not await for it because the future is delayed and
        // the passage of time is emulated, so it will never called unless we
        // pump() some time.
        unawaited(controller.pause(_FakeContext()));

        // Advance the time it takes to pause the video controller, the
        // onMediumFinished callback should not have been called since the video
        // didn't finished playing and the controller should be paused.
        await tester.pump(fakeController.pauseDelay);
        expectSuccess(tester, widget, findWidget: video_player.VideoPlayer);
        expect(hasFinished, false);
        expect(controller.value.isPlaying, false);

        await tester.idle(); // Make sure the pause() timer is done
      },
    );
  });

  group('WebAudioPlayerController', () {
    final audio = Audio(Uri.parse('fake-audio.avi'));

    test('is a subclass of VideoPlayerController', () async {
      final controller = WebAudioPlayerController(audio);
      expect(controller, isA<VideoPlayerController>());
      await controller.dispose();
    });

    testWidgets('initializes and plays showing an empty container',
        (WidgetTester tester) async {
      final videoInfo = FakeVideoInfo(Duration(seconds: 1), Size(0.0, 0.0));
      final controller = TestAudioPlayerController(audio, videoInfo,
          widgetKey: globalSuccessKey);
      final widget = TestWidget(controller);

      await tester.pumpWidget(widget);
      expectLoading(tester, widget);
      expect(controller.value.isPlaying, false);

      // Since loading is emulated, in the next frame it should be ready.
      // Video should start playing.
      final fakeController =
          controller.controller as _FakeVideoPlayerController;
      await tester.pump(fakeController.initDelay);
      final foundWidget = expectSuccess(tester, widget,
          size: videoInfo.size, findWidget: Container)!;
      expect((foundWidget as Container).child, isNull);
      expect(controller.value.isPlaying, true);
      addTearDown(() async => await controller.dispose());
    });
  });
}

class FakeVideoInfo {
  Duration? duration;
  Size? size;
  String? initError;
  String? playError;
  FakeVideoInfo(this.duration, this.size, {this.initError, this.playError});
  FakeVideoInfo.initError(String errorDescription)
      : this(null, null, initError: errorDescription);
  FakeVideoInfo.playError(
      {this.playError = 'Play error',
      this.duration = const Duration(milliseconds: 1000),
      this.size = const Size(10.0, 20.0)});
}

// Only one instance can live at each time
class _FakeVideoPlayerController extends Fake
    implements video_player.VideoPlayerController {
  Duration initDelay = Duration.zero;
  Duration playDelay = Duration.zero;
  Duration pauseDelay = Duration.zero;
  var listeners = <VoidCallback>[];
  @override
  final String dataSource;
  @override
  var value = video_player.VideoPlayerValue.uninitialized();
  @override
  int get textureId => 1;

  _FakeVideoPlayerController(this.dataSource);

  @override
  void addListener(VoidCallback listener) => listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => listeners.remove(listener);

  @override
  void notifyListeners() {
    // do a copy of the list before iterating so we can remove elementes from
    // listeners.
    for (final listener in listeners.toList()) {
      listener();
    }
  }

  @override
  Future<void> initialize() {
    return Future<void>.delayed(initDelay, () {
      if (globalFakeInfo!.initError != null) {
        throw Exception(globalFakeInfo!.initError);
      }
      value = value.copyWith(
        duration: globalFakeInfo!.duration,
        size: globalFakeInfo!.size,
      );
      expect(listeners, isNotEmpty);
      notifyListeners();
    });
  }

  @override
  Future<void> play() {
    return Future<void>.delayed(playDelay, () {
      if (globalFakeInfo!.playError != null) {
        throw Exception(globalFakeInfo!.playError);
      }
      value = value.copyWith(isPlaying: true);
      expect(listeners, isNotEmpty);
      notifyListeners();
    });
  }

  @override
  Future<void> pause() {
    return Future<void>.delayed(pauseDelay, () {
      value = value.copyWith(isPlaying: false);
      // XXX: we need to call expectSync() because this is called when
      // await tester.pump() is called
      expectSync(listeners, isNotEmpty);
      notifyListeners();
    });
  }

  @override
  Future<void> dispose() {
    // TODO: error?
    return Future<void>.value();
  }

  void fakeSeekTo(Duration position) {
    expect(position, lessThanOrEqualTo(value.duration));
    if (position == value.duration) {
      value = value.copyWith(isPlaying: false);
    }
    value = value.copyWith(position: position);
    expect(listeners, isNotEmpty);
    notifyListeners();
  }

  void fakeSeekToEnd() => fakeSeekTo(value.duration);
}

class TestVideoPlayerController extends VideoPlayerController {
  TestVideoPlayerController(
    SingleMedium medium,
    FakeVideoInfo? info, {
    void Function(BuildContext)? onMediumFinished,
    Key? widgetKey,
  }) : super(medium, onMediumFinished: onMediumFinished, widgetKey: widgetKey) {
    globalFakeInfo = info;
  }

  video_player.VideoPlayerValue get value => controller!.value;

  @override
  video_player.VideoPlayerController createController() {
    return _FakeVideoPlayerController(medium.toString());
  }

  video_player.VideoPlayerController testCreateVideoPlayerController() {
    return super.createController();
  }
}

class TestAudioPlayerController extends WebAudioPlayerController {
  TestAudioPlayerController(
    SingleMedium medium,
    FakeVideoInfo info, {
    void Function(BuildContext)? onMediumFinished,
    Key? widgetKey,
  }) : super(medium, onMediumFinished: onMediumFinished, widgetKey: widgetKey) {
    globalFakeInfo = info;
  }

  video_player.VideoPlayerValue get value => controller!.value;

  @override
  video_player.VideoPlayerController createController() {
    return _FakeVideoPlayerController(medium.resource.toString());
  }
}
