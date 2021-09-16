import 'package:flutter/material.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart' show Menu, GridMenu;

import 'dynamic_dispatch_registry.dart' show DynamicDispatchRegistry;

import 'menu_player/grid_menu_player.dart' show GridMenuPlayer;

/// Register all builtin types
///
/// When new builtin types are added, they should be registered by this
/// function, which is used by [MenuPlayerRegistry.builtin()].
void _registerBuiltin(MenuPlayerRegistry registry) {
  // New menus should be registered here
  registry.register(GridMenu, (menu) => GridMenuPlayer(menu as GridMenu));
}

/// A wrapper to manage how a [Menu] is played by the player.
///
/// This class also manages a registry of implementations for the different
/// concrete types of [Menu]. To get an menu wrapper, [MenuPlayer.wrap()]
/// should be used.
abstract class MenuPlayer {
  /// The [MenuPlayerRegistry] used to dispatch the calls.
  static var registry = MenuPlayerRegistry.builtin();

  /// Dispatches the call dynamically by using the [registry].
  ///
  /// The dispatch is done based on this [runtimeType], so only concrete leaf
  /// types can be dispatched. It asserts if a type is not registered.
  static MenuPlayer wrap(Menu menu) {
    final wrap = registry.getFunction(menu);
    assert(wrap != null, 'Unimplemented MenuPlayer for ${menu.runtimeType}');
    return wrap!(menu);
  }

  /// The underlaying model's [Menu].
  Menu get menu;

  /// Builds the UI for this [menu].
  Widget build(BuildContext context);
}

/// A function type to build the UI of a [Menu].
typedef WrapFunction = MenuPlayer Function(Menu menu);

/// A registry to map from [Menu] types to [BuildFunction].
class MenuPlayerRegistry extends DynamicDispatchRegistry<Menu, WrapFunction> {
  /// Constructs an empty registry.
  MenuPlayerRegistry();

  /// Constructs a registry with builtin types registered.
  MenuPlayerRegistry.builtin() {
    _registerBuiltin(this);
  }
}
