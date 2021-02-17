import 'package:flutter/material.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Button, Color, StyledButton;

import '../button_player.dart' show ButtonPlayer;

/// A wrapper to play a [StyledButton].
class StyledButtonPlayer extends ButtonPlayer {
  /// The underlaying model's [Button].
  @override
  final StyledButton button;

  /// Constructs a [ButtonPlayer] using [button] as the underlaying [Button].
  StyledButtonPlayer(this.button)
      : assert(button != null),
        super(button);

  /// The [Color] of the underlaying [button].
  @override
  Color get backgroundColor => button.backgroundColor;

  /// Creates a [GridButtonItem].
  ///
  /// It uses [color] as the [GridButtonItem.color] and [this] as the
  /// [GridButtonItem.value] and as a [ValueKey] for [GridButtonItem.key].
  @override
  Widget build(BuildContext context) =>
      StyledButtonWidget(button: this, key: ObjectKey(button));
}

/// A widget to display a [StyledButton].
class StyledButtonWidget extends StatelessWidget {
  /// The button to display.
  final StyledButtonPlayer button;

  /// Creates a new [StyledButtonWidget] to display [button].
  const StyledButtonWidget({@required this.button, Key key})
      : assert(button != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => button.action.act(context, button),
        child: const Text(''),
        style: TextButton.styleFrom(
          backgroundColor: button.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      );
}
