@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show BuildContext, Container, Widget;

import 'package:test/test.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show SingleMedium, Audio, Image, Video;
import 'package:lunofono_player/src/media_player/controller_registry.dart';
import 'package:lunofono_player/src/media_player/single_medium_controller.dart';

class _FakeSingleMedium extends SingleMedium {
  _FakeSingleMedium(Uri resource) : super(resource);
}

class _FakeSingleMediumController extends SingleMediumController {
  _FakeSingleMediumController()
      : super(_FakeSingleMedium(Uri.parse('fake-single-medium')));
  @override
  Future<Size> initialize(BuildContext context) => Future.value(Size(0, 0));
  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  group('ControllerRegistry', () {
    test('default constructor', () {
      SingleMediumController f(SingleMedium medium,
              {void Function(BuildContext)? onMediumFinished}) =>
          _FakeSingleMediumController();
      final fakeMedium = _FakeSingleMedium(Uri.parse('fake-medium'));
      final registry = ControllerRegistry();
      expect(registry.isEmpty, isTrue);
      final oldRegisteredFunction = registry.register(_FakeSingleMedium, f);
      expect(oldRegisteredFunction, isNull);
      expect(registry.isEmpty, isFalse);
      final SingleMediumController? Function(SingleMedium,
              {void Function(BuildContext) onMediumFinished})? create =
          registry.getFunction(fakeMedium);
      expect(create, f);
    });

    void testDefaults(ControllerRegistry registry) {
      expect(registry.isEmpty, isFalse);

      final audio = Audio(Uri.parse('fake-audio'));
      var controller = registry.getFunction(audio)!(audio);
      // XXX: This is a hack that should be removed after #15 and #16 are
      // resolved.
      if (kIsWeb) {
        expect(controller, isA<WebAudioPlayerController>());
      } else {
        expect(controller, isA<AudioPlayerController>());
      }
      expect(controller.medium, audio);

      final image = Image(Uri.parse('fake-image'));
      controller = registry.getFunction(image)!(image);
      expect(controller, isA<ImagePlayerController>());
      expect(controller.medium, image);

      final video = Video(Uri.parse('fake-video'));
      controller = registry.getFunction(video)!(video);
      expect(controller, isA<VideoPlayerController>());
      expect(controller.medium, video);
    }

    test('.defaults() constructor', () {
      testDefaults(ControllerRegistry.defaults());
    });

    test('.instance', () {
      final registry = ControllerRegistry.instance;
      testDefaults(registry);
      expect(registry, same(ControllerRegistry.instance));
    });
  });
}
