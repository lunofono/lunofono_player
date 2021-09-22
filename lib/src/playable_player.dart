import 'package:flutter/material.dart'
    show BuildContext, Navigator, MaterialPageRoute, Colors;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show
        Audio,
        Color,
        Image,
        MultiMedium,
        Playable,
        Playlist,
        SingleMedium,
        Video;

import 'dynamic_dispatch_registry.dart' show DynamicDispatchRegistry;
import 'media_player.dart'
    show MultiMediumPlayer, SingleMediumPlayer, PlaylistPlayer;

/// Register all builtin types
///
/// When new builtin types are added, they should be registered by this
/// function, which is used by [PlayablePlayerRegistry.builtin()].
void _registerBuiltin(PlayablePlayerRegistry registry) {
  // New actions should be registered here
  registry.register(Audio,
      (playable) => SingleMediumPlayablePlayer(playable as SingleMedium));
  registry.register(Image,
      (playable) => SingleMediumPlayablePlayer(playable as SingleMedium));
  registry.register(Video,
      (playable) => SingleMediumPlayablePlayer(playable as SingleMedium));
  registry.register(MultiMedium,
      (playable) => MultiMediumPlayablePlayer(playable as MultiMedium));
  registry.register(
      Playlist, (playable) => PlaylistPlayablePlayer(playable as Playlist));
}

/// A wrapper to manage how a [Playable] is played by the player.
///
/// This class also manages a registry of implementations for the different
/// concrete types of [Playable]. To get a playable wrapper, [PlayablePlayer.wrap()]
/// should be used.
abstract class PlayablePlayer {
  /// The [PlayablePlayerRegistry] used to dispatch the calls.
  static var registry = PlayablePlayerRegistry.builtin();

  /// Dispatches the call dynamically by using the [registry].
  ///
  /// The dispatch is done based on this [runtimeType], so only concrete leaf
  /// types can be dispatched. It asserts if a type is not registered.
  static PlayablePlayer wrap(Playable playable) {
    final wrap = registry.getFunction(playable);
    assert(wrap != null,
        'Unimplemented PlayablePlayer for ${playable.runtimeType}');
    return wrap!(playable);
  }

  /// The underlaying model's [Playable].
  Playable get playable;

  /// Plays this [Playable] with an optional [backgroundColor].
  void play(BuildContext context, [Color? backgroundColor]);
}

class SingleMediumPlayablePlayer extends PlayablePlayer {
  /// The underlaying model's [SingleMedium].
  @override
  final SingleMedium playable;

  /// Creates a [SingleMediumPlayablePlayer] using [playable] as the underlaying
  /// [Playable].
  SingleMediumPlayablePlayer(this.playable);

  /// Plays a [SingleMedium] by pushing a new page with a [SingleMediumPlayer].
  ///
  /// If [backgroundColor] is provided and non-null, it will be used as the
  /// [SingleMediumPlayer.backgroundColor]. Otherwise, [Colors.black] will be
  /// used.
  @override
  void play(BuildContext context, [Color? backgroundColor]) {
    Navigator.push<SingleMediumPlayer>(
      context,
      MaterialPageRoute<SingleMediumPlayer>(
        builder: (BuildContext context) => SingleMediumPlayer(
          medium: playable,
          backgroundColor: backgroundColor ?? Colors.black,
          onMediaStopped: (context) => Navigator.pop(context),
        ),
      ),
    );
  }
}

class PlaylistPlayablePlayer extends PlayablePlayer {
  /// The underlaying model's [SingleMedium].
  @override
  final Playlist playable;

  /// Constructs a [SingleMediumWidget] using [playable] as the underlaying
  /// [Playable].
  PlaylistPlayablePlayer(this.playable);

  /// Plays a [SingleMedium] by pushing a new page with a [PlaylistPlayer].
  ///
  /// If [backgroundColor] is provided and non-null, it will be used as the
  /// [PlaylistPlayer.backgroundColor]. Otherwise, [Colors.black] will be
  /// used.
  @override
  void play(BuildContext context, [Color? backgroundColor]) {
    Navigator.push<PlaylistPlayer>(
      context,
      MaterialPageRoute<PlaylistPlayer>(
        builder: (BuildContext context) => PlaylistPlayer(
          playlist: playable,
          backgroundColor: backgroundColor ?? Colors.black,
          onMediaStopped: (context) => Navigator.pop(context),
        ),
      ),
    );
  }
}

class MultiMediumPlayablePlayer extends PlayablePlayer {
  /// The underlaying model's [SingleMedium].
  @override
  final MultiMedium playable;

  /// Constructs a [SingleMediumWidget] using [playable] as the underlaying
  /// [Playable].
  MultiMediumPlayablePlayer(this.playable);

  /// Plays a [SingleMedium] by pushing a new page with a [MultiMediumPlayer].
  ///
  /// If [backgroundColor] is provided and non-null, it will be used as the
  /// [MultiMediumPlayer.backgroundColor]. Otherwise, [Colors.black] will be
  /// used.
  @override
  void play(BuildContext context, [Color? backgroundColor]) {
    Navigator.push<MultiMediumPlayer>(
      context,
      MaterialPageRoute<MultiMediumPlayer>(
        builder: (BuildContext context) => MultiMediumPlayer(
          medium: playable,
          backgroundColor: backgroundColor ?? Colors.black,
          onMediaStopped: (context) => Navigator.pop(context),
        ),
      ),
    );
  }
}

// From here, it's just boilerplate and it shouldn't be changed unless the
// architecture changes.

/// A function type to play a [Playable].
typedef WrapFunction = PlayablePlayer Function(Playable playable);

/// A registry to map from [Playable] types [PlayFunction].
class PlayablePlayerRegistry
    extends DynamicDispatchRegistry<Playable, WrapFunction> {
  /// Constructs an empty registry.
  PlayablePlayerRegistry();

  /// Constructs a registry with builtin types registered.
  PlayablePlayerRegistry.builtin() {
    _registerBuiltin(this);
  }
}
