import 'package:flutter/material.dart' hide Orientation;

import 'package:lunofono_bundle/lunofono_bundle.dart' show Bundle, Orientation;

import 'menu_player.dart' show MenuPlayer;
import 'platform_services.dart' show PlatformServices;

/// A [Bundle] player.
///
/// This widget works as a player for [Bundle]s. It builds the UI for
/// the [Bundle.rootMenu] and from then on, it builds any sub-[Menu]s,
/// trigger actions on buttons and eventually plays the media.
class BundlePlayer extends StatefulWidget {
  /// [Bundle] that will be played by this player.
  final Bundle bundle;

  /// Platform services provider.
  final PlatformServices platformServices;

  /// Creates a new instance to play [bundle].
  ///
  /// If platformServices is null (the default), the global instance
  /// [PlatformServices.instance] will be used.
  ///
  /// [bundle] cannot be null.
  const BundlePlayer(
    this.bundle, {
    PlatformServices? platformServices,
    Key? key,
  })  : platformServices = platformServices ?? const PlatformServices(),
        super(key: key);

  @override
  _BundlePlayerState createState() => _BundlePlayerState();
}

/// A state for a [BundlePlayer].
class _BundlePlayerState extends State<BundlePlayer> {
  /// The [MenuPlayer] used to play this [widget.menu].
  late MenuPlayer rootMenu;

  /// Initialized this [_BundlePlayerState].
  ///
  /// TODO: configure the player based on a default app config, overridden by
  /// the user and the content bundle.
  @override
  void initState() {
    super.initState();

    rootMenu = MenuPlayer.wrap(widget.bundle.rootMenu);

    // Set fullscreen mode
    widget.platformServices.setFullScreen(on: true).then((v) {});

    // Set fixed orientation
    widget.platformServices.setOrientation(Orientation.portrait).then((v) {});

    // Take wakelock so the device isn't locked after some time inactive
    widget.platformServices.inhibitScreenOff(on: true).then((v) {});
  }

  /// Builds the UI of this widget.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: rootMenu.build(context),
    );
  }
}
