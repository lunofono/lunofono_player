import 'package:flutter/material.dart' hide Action;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Action, Button, Color, StyledButton;

import 'action_player.dart' show ActionPlayer;
import 'button_player/styled_button_player.dart' show StyledButtonPlayer;
import 'dynamic_dispatch_registry.dart' show DynamicDispatchRegistry;

/// Register all built-in types
///
/// When new built-in types are added, they should be registered by this
/// function, which is used by [ButtonPlayerRegistry.builtin()].
void _registerBuiltin(ButtonPlayerRegistry registry) {
  // New wrappers should be registered here
  registry.register(
      StyledButton, (button) => StyledButtonPlayer(button as StyledButton));
}

/// A wrapper to manage how a [Button] is played by the player.
///
/// This class also manages a registry of implementations for the different
/// concrete types of [Button]. To get a button wrapper, [ButtonPlayer.wrap()]
/// should be used.
abstract class ButtonPlayer {
  /// The [ButtonPlayerRegistry] used to dispatch the calls.
  static var registry = ButtonPlayerRegistry.builtin();

  /// Dispatches the call dynamically by using the [registry].
  ///
  /// The dispatch is done based on this [runtimeType], so only concrete leaf
  /// types can be dispatched. It asserts if a type is not registered.
  static ButtonPlayer wrap(Button button) {
    final wrap = registry.getFunction(button);
    assert(
        wrap != null, 'Unimplemented ButtonPlayer for ${button.runtimeType}');
    return wrap(button);
  }

  /// Constructs a [ButtonPlayer].
  ButtonPlayer(Button button)
      : assert(button != null),
        action = ActionPlayer.wrap(button.action);

  /// The [ActionPlayer] wrapping the [Action] for this [button].
  final ActionPlayer action;

  /// The underlaying model's [Button].
  Button get button;

  /// The [Color] of the underlaying [button].
  ///
  /// Returns null by default, as not all [Button] types have a background
  /// color.
  Color get backgroundColor => null;

  /// Creates a [GridButtonItem] from the underlaying [button].
  ///
  /// The [GridButtonItem.value] must always be assigned to this [ButtonPlayer].
  Widget build(BuildContext context);
}

/// A function type to create a [ButtonPlayer] from a [Button].
typedef WrapFunction = ButtonPlayer Function(Button button);

/// A registry to map from [Button] types to a [WrapFunction].
class ButtonPlayerRegistry
    extends DynamicDispatchRegistry<Button, WrapFunction> {
  /// Constructs an empty registry.
  ButtonPlayerRegistry();

  /// Constructs a registry with builtin types registered.
  ButtonPlayerRegistry.builtin() {
    _registerBuiltin(this);
  }
}
