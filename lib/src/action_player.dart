import 'package:flutter/material.dart' show BuildContext;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Action, PlayContentAction;

import 'button_player.dart' show ButtonPlayer;
import 'dynamic_dispatch_registry.dart' show DynamicDispatchRegistry;
import 'playable_player.dart' show PlayablePlayer;

/// Register all builtin types
///
/// When new builtin types are added, they should be registered by this
/// function, which is used by [ActionPlayerRegistry.builtin()].
void _registerBuiltin(ActionPlayerRegistry registry) {
  // New actions should be registered here
  registry.register(PlayContentAction,
      (action) => PlayContentActionPlayer(action as PlayContentAction));
}

/// A wrapper to manage how an [Action] is played by the player.
///
/// This class also manages a registry of implementations for the different
/// concrete types of [Action]. To get an action wrapper, [ActionPlayer.wrap()]
/// should be used.
abstract class ActionPlayer {
  /// The [ActionPlayerRegistry] used to dispatch the calls.
  static var registry = ActionPlayerRegistry.builtin();

  /// Dispatches the call dynamically by using the [registry].
  ///
  /// The dispatch is done based on this [runtimeType], so only concrete leaf
  /// types can be dispatched. It asserts if a type is not registered.
  static ActionPlayer wrap(Action action) {
    final wrap = registry.getFunction(action);
    assert(
        wrap != null, 'Unimplemented ActionPlayer for ${action.runtimeType}');
    return wrap(action);
  }

  /// Constructs an [ActionPlayer].
  const ActionPlayer();

  /// The underlaying model's [Action].
  Action get action;

  /// Perform the action for this.
  void act(BuildContext context, ButtonPlayer button);
}

/// A wrapper to play a [PlayContentAction].
class PlayContentActionPlayer extends ActionPlayer {
  /// The underlaying model's [Action].
  @override
  final PlayContentAction action;

  /// The [PlayablePlayer] wrapping the [Playable] for this [content].
  final PlayablePlayer content;

  /// Constructs a [PlayContentActionPlayer] using [action] as the underlaying
  /// [Action].
  PlayContentActionPlayer(this.action)
      : assert(action != null),
        content = PlayablePlayer.wrap(action.content);

  /// Plays the [content].
  @override
  void act(BuildContext context, ButtonPlayer button) =>
      content.play(context, button.backgroundColor);
}

/// A function type to act on an [Action].
typedef WrapFunction = ActionPlayer Function(Action action);

/// A registry to map from [Action] types to [WrapFunction].
class ActionPlayerRegistry
    extends DynamicDispatchRegistry<Action, WrapFunction> {
  /// Constructs an empty registry.
  ActionPlayerRegistry();

  /// Constructs a registry with builtin types registered.
  ActionPlayerRegistry.builtin() {
    _registerBuiltin(this);
  }
}
