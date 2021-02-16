import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show BuildContext;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show SingleMedium, Audio, Image, Video;

import '../dynamic_dispatch_registry.dart' show DynamicDispatchRegistry;

import 'single_medium_controller.dart';

export 'single_medium_controller.dart' show SingleMediumController;

/// A function used to crate a [SingleMediumController].
///
/// This callback should never return null.
typedef ControllerCreateFunction = SingleMediumController Function(
  SingleMedium medium, {
  void Function(BuildContext) onMediumFinished,
});

/// A registry so [SingleMediumController]s can be created dynamically.
///
/// This registry serves as a way to have dynamic dispatch to create controllers
/// for different kinds of [SingleMedium]s.
class ControllerRegistry
    extends DynamicDispatchRegistry<SingleMedium, ControllerCreateFunction> {
  /// The global instance for the registry.
  ///
  /// This instance is initialized with all known media controllers.
  static var instance = ControllerRegistry.defaults();

  /// Constructs an empty controller registry.
  ControllerRegistry();

  /// Constructs a registry with the default [SingleMediumController] mappings.
  ControllerRegistry.defaults() {
    register(
      Audio,
      (SingleMedium medium, {void Function(BuildContext) onMediumFinished}) =>
          // XXX: This is a hack that should be removed after #15 and #16 are
          // resolved.
          kIsWeb
              ? WebAudioPlayerController(medium,
                  onMediumFinished: onMediumFinished)
              : AudioPlayerController(medium,
                  onMediumFinished: onMediumFinished),
    );

    register(
      Image,
      (SingleMedium medium, {void Function(BuildContext) onMediumFinished}) =>
          ImagePlayerController(medium, onMediumFinished: onMediumFinished),
    );

    register(
      Video,
      (SingleMedium medium, {void Function(BuildContext) onMediumFinished}) =>
          VideoPlayerController(medium, onMediumFinished: onMediumFinished),
    );
  }
}
