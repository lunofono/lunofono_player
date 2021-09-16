import 'package:flutter/services.dart'
    show SystemChrome, DeviceOrientation, SystemUiMode;

import 'package:wakelock/wakelock.dart' show Wakelock;

import 'package:lunofono_bundle/lunofono_bundle.dart' show Orientation;

/// Provides services dependent on the platform.
///
/// Usually these services are presented as singletons or global functions,
/// making them hard to integrate with tests.
class PlatformServices {
  /// Creates a new PlatformServices instance.
  const PlatformServices();

  /// Set fullscreen mode on or off.
  Future<void> setFullScreen({required bool on}) async {
    return SystemChrome.setEnabledSystemUIMode(
        on ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  /// Set the preferred screen orientation(s).
  ///
  /// If [Orientation.inherited] is used, we don't do anything, assuming the
  /// current orientation is the preferred one.
  Future<void> setOrientation(Orientation orientation) async {
    Future<void> setTo(List<DeviceOrientation> o) async {
      return SystemChrome.setPreferredOrientations(o);
    }

    switch (orientation) {
      case Orientation.inherited:
        // It doesn't make a lot of sense to call this function with this
        // orientation, but if it happens, we don't do anything, assuming the
        // current orientation is preferred.
        return;

      case Orientation.automatic:
        return setTo(DeviceOrientation.values);

      case Orientation.portrait:
        return setTo([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

      case Orientation.portraitUp:
        return setTo([DeviceOrientation.portraitUp]);

      case Orientation.portraitDown:
        return setTo([DeviceOrientation.portraitDown]);

      case Orientation.landscape:
        return setTo([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);

      case Orientation.landscapeLeft:
        return setTo([DeviceOrientation.landscapeLeft]);

      case Orientation.landscapeRight:
        return setTo([DeviceOrientation.landscapeRight]);
    }
  }

  /// If on, the device will not turn off the screen after some timeout.
  ///
  /// This is also known as "wakelock", when taking the "wakelock" means the
  /// device doesn't go to sleep.
  Future<void> inhibitScreenOff({required bool on}) async {
    // Take wakelock so the device isn't locked after some time inactive
    return on ? Wakelock.enable() : Wakelock.disable();
  }
}
