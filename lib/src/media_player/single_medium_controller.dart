import 'dart:async' show Completer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart'
    show AudioCache, AudioPlayer, ReleaseMode;
import 'package:video_player/video_player.dart' as video_player;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show SingleMedium, UnlimitedDuration;
import 'package:pausable_timer/pausable_timer.dart' show PausableTimer;

export 'dart:ui' show Size;

/// A controller for a specific type of media.
///
/// This class is intended to be used as a base class.
abstract class SingleMediumController {
  /// The medium to play by this player controller.
  final SingleMedium medium;

  /// The key to use to create the main [Widget] in [build()].
  final Key? widgetKey;

  /// The callback to be called when the medium finishes playing.
  ///
  /// This callback is called when the medium finishes playing by itself.
  final void Function(BuildContext)? onMediumFinished;

  /// The timer used to finish the medium if it has a maximum duration.
  ///
  /// If [medium.maxDuration] is [UnlimitedDuration] then this timer is null.
  ///
  /// If not, the timer is created by [initialize] (setting the timer to run
  /// [pause] and [onMediumFinished] when it expires) but it's not started until
  /// [play] is called. Then [play] and [pause] will start and pause the timer.
  @protected
  PausableTimer? maxDurationTimer;

  /// {@template ui_player_media_player_medium_player_controller_initialize}
  /// Initializes this controller, getting the size of the media to be played.
  ///
  /// When initialization is done, this function returns the size of the media
  /// being played.
  ///
  /// The [build()] method should never be called before the initialization is
  /// done.
  /// {@endtemplate}
  Future<Size> initialize(BuildContext context);

  /// Initializes the maxDurationTimer.
  ///
  /// This timer is only initialized if the underlying [medium] has a non-null
  /// maxDuration.
  ///
  /// Any subclass wanting to use this timer must initialize it in their own
  /// initialize() method.
  @protected
  void initializeMaxDurationTimer(BuildContext context) {
    if (medium.maxDuration == const UnlimitedDuration()) return;

    maxDurationTimer = PausableTimer(medium.maxDuration, () async {
      await pause(context);
      onMediumFinished?.call(context);
    });
  }

  /// Play the [medium] controlled by this controller.
  @mustCallSuper
  Future<void> play(BuildContext context) async => maxDurationTimer?.start();

  /// Pause the [medium] controlled by this controller.
  @mustCallSuper
  Future<void> pause(BuildContext context) async => maxDurationTimer?.pause();

  /// Builds the [Widget] that plays the medium this controller controls.
  Widget build(BuildContext context);

  /// Disposes this controller.
  @mustCallSuper
  Future<void> dispose() async => maxDurationTimer?.cancel();

  /// {@template ui_player_media_player_medium_player_controller_constructor}
  /// Constructs a controller to play the [medium].
  ///
  /// If a [onMediumFinished] callback is provided, it will be called when the
  /// media finishes playing.
  ///
  /// If a [widgetKey] is provided, it will be used to create the main player
  /// [Widget] in the [build()] function.
  /// {@endtemplate}
  SingleMediumController(this.medium, {this.onMediumFinished, this.widgetKey});
}

/// A video player controller.
class VideoPlayerController extends SingleMediumController {
  /// The video player controller.
  video_player.VideoPlayerController? _controller;

  /// The video player controller.
  @visibleForTesting
  video_player.VideoPlayerController? get controller => _controller;

  /// {@macro ui_player_media_player_medium_player_controller_constructor}
  VideoPlayerController(
    SingleMedium medium, {
    void Function(BuildContext)? onMediumFinished,
    Key? widgetKey,
  }) : super(medium, onMediumFinished: onMediumFinished, widgetKey: widgetKey);

  /// Disposes this controller.
  @override
  Future<void> dispose() => Future.wait<void>([
        _controller?.dispose() ?? Future<void>.value(),
        super.dispose(),
      ]);

  /// Creates a new [video_player.VideoPlayerController].
  ///
  /// This method is provided mostly only for testing, so a fake type of video
  /// player controller can be *injected* by tests.
  @visibleForTesting
  video_player.VideoPlayerController createController() {
    // mixWithOthers is not supported in web yet
    final options =
        kIsWeb ? null : video_player.VideoPlayerOptions(mixWithOthers: true);
    return video_player.VideoPlayerController.asset(medium.resource.toString(),
        videoPlayerOptions: options);
  }

  /// {@macro ui_player_media_player_medium_player_controller_initialize}
  @override
  Future<Size> initialize(BuildContext context) async {
    initializeMaxDurationTimer(context);

    final controller = createController();
    _controller = controller;

    late final VoidCallback listener;
    listener = () {
      final value = controller.value;
      // value.duration can be null during initialization
      // If the position reaches the duration (we use >= just to be extra
      // careful) and it is not playing anymore, we assumed it finished playing.
      // Also this should happen once and only once, as we don't expose any
      // seeking or loop playing.
      if (value.position >= value.duration && !value.isPlaying) {
        onMediumFinished?.call(context);
        controller.removeListener(listener);
      }
    };

    controller.addListener(listener);

    await controller.initialize();

    return controller.value.size;
  }

  /// Play the [medium] controlled by this controller.
  @override
  Future<void> play(BuildContext context) =>
      Future.wait([super.play(context), _controller!.play()]);

  /// Pause the [medium] controlled by this controller.
  @override
  Future<void> pause(BuildContext context) =>
      Future.wait([super.pause(context), _controller!.pause()]);

  /// Builds the [Widget] that plays the medium this controller controls.
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: video_player.VideoPlayer(_controller!),
      key: widgetKey,
    );
  }
}

/// An audio player controller for the web.
///
/// XXX: This is just a temporary hack because audioplayers doesn't support web
/// for playing assets (#16) and just_audio is affected by the ExoPlayer bug
/// (#15).
///
/// Since audio is not really visible, this player will return an empty
/// [Container] in the [build()] method. Users are free to omit using the
/// [build()] method at all.
class WebAudioPlayerController extends VideoPlayerController {
  /// {@macro ui_player_media_player_medium_player_controller_constructor}
  WebAudioPlayerController(
    SingleMedium medium, {
    void Function(BuildContext)? onMediumFinished,
    Key? widgetKey,
  }) : super(medium, onMediumFinished: onMediumFinished, widgetKey: widgetKey);

  /// Builds the [Widget] that plays the medium this controller controls.
  ///
  /// Since audio is not really visible, this player will return an empty
  /// [Container]. Users are free to omit using this method.
  @override
  Widget build(BuildContext context) {
    // Audios are invisible, so there is nothing to show
    return Container(key: widgetKey);
  }
}

/// An audio player controller.
///
/// Since audio is not really visible, this player will return an empty
/// [Container] in the [build()] method. Users are free to omit using the
/// [build()] method at all.
class AudioPlayerController extends SingleMediumController {
  /// {@macro ui_player_media_player_medium_player_controller_constructor}
  AudioPlayerController(
    SingleMedium medium, {
    void Function(BuildContext)? onMediumFinished,
    Key? widgetKey,
  }) : super(medium, onMediumFinished: onMediumFinished, widgetKey: widgetKey);

  /// The video player controller.
  AudioCache? _controller;

  /// The video player controller.
  @visibleForTesting
  AudioCache? get controller => _controller;

  /// True if playing was started, false otherwise.
  ///
  /// This is needed because once it is started, if it was paused, resume()
  /// should be used instead of play().
  bool _playStarted = false;

  /// Disposes this controller.
  @override
  Future<void> dispose() {
    return Future.wait([
      _controller?.fixedPlayer?.dispose() ?? Future<void>.value(),
      super.dispose(),
    ]);
  }

  /// Creates a new [video_player.VideoPlayerController].
  ///
  /// This method is provided mostly only for testing, so a fake type of video
  /// player controller can be *injected* by tests.
  @visibleForTesting
  AudioCache createController() => AudioCache(prefix: '');

  /// {@macro ui_player_media_player_medium_player_controller_initialize}
  @override
  Future<Size> initialize(BuildContext context) async {
    initializeMaxDurationTimer(context);

    final controller = createController();
    _controller = controller;

    final player = AudioPlayer();
    player.onPlayerCompletion.listen((_) {
      onMediumFinished?.call(context);
    });

    controller.fixedPlayer = player;

    await player
        .setReleaseMode(ReleaseMode.STOP)
        .then((_) => controller.load(medium.resource.toString()));

    return Size.zero;
  }

  /// Play the [medium] controlled by this controller.
  @override
  Future<void> play(BuildContext context) {
    final controllerPlayFuture = _playStarted
        ? _controller!.fixedPlayer!.resume()
        : _controller!.play(medium.resource.toString());
    _playStarted = true;
    return Future.wait([super.play(context), controllerPlayFuture]);
  }

  /// Pause the [medium] controlled by this controller.
  @override
  Future<void> pause(BuildContext context) {
    return Future.wait(
        [super.pause(context), _controller!.fixedPlayer!.pause()]);
  }

  /// Builds the [Widget] that plays the medium this controller controls.
  ///
  /// Since audio is not really visible, this player will return an empty
  /// [Container]. Users are free to omit using this method.
  @override
  Widget build(BuildContext context) {
    // Audios are invisible, so there is nothing to show
    return Container(key: widgetKey);
  }
}

/// An image player controller.
class ImagePlayerController extends SingleMediumController {
  /// The image that this controller will [build()].
  late final Image _image;

  /// The image that this controller will [build()].
  Image get image => _image;

  /// {@macro ui_player_media_player_medium_player_controller_constructor]
  ImagePlayerController(
    SingleMedium medium, {
    void Function(BuildContext)? onMediumFinished,
    Key? widgetKey,
  }) : super(medium, onMediumFinished: onMediumFinished, widgetKey: widgetKey);

  /// {@macro ui_player_media_player_medium_player_controller_initialize]
  @override
  Future<Size> initialize(BuildContext context) async {
    initializeMaxDurationTimer(context);

    final completer = Completer<void>();
    late final Size size;

    _image = Image.asset(
      medium.resource.toString(),
      bundle: DefaultAssetBundle.of(context),
      key: widgetKey,
    );

    _image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (ImageInfo info, bool _) {
              size = Size(
                  info.image.width.toDouble(), info.image.height.toDouble());
              completer.complete();
            },
            onError: (Object error, StackTrace? stackTrace) {
              completer.completeError(error, stackTrace);
            },
          ),
        );

    await completer.future;

    return size;
  }

  /// Builds the [Widget] that plays the medium this controller controls.
  @override
  Widget build(BuildContext context) {
    return _image;
  }
}
