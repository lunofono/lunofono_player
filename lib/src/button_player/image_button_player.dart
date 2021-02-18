import 'package:flutter/material.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Button, Color, ImageButton;

import '../button_player.dart' show ButtonPlayer;

/// A wrapper to play a [ImageButton].
class ImageButtonPlayer extends ButtonPlayer {
  /// The underlaying model's [Button].
  @override
  final ImageButton button;

  /// Constructs a [ButtonPlayer] using [button] as the underlaying [Button].
  ImageButtonPlayer(this.button)
      : assert(button != null),
        super(button);

  /// The background [Color] of the underlaying [button].
  ///
  /// TODO: This is very hacky and should be removed.
  ///       https://github.com/lunofono/lunofono_player/issues/25
  @override
  Color get backgroundColor => Colors.white;

  /// The location of the image of the underlaying [button].
  Uri get imageUri => button.imageUri;

  @override
  Widget build(BuildContext context) =>
      ImageButtonWidget(button: this, key: ObjectKey(button));
}

/// A widget to display a [ImageButton].
class ImageButtonWidget extends StatelessWidget {
  /// The button to display.
  final ImageButtonPlayer button;

  /// Creates a new [ImageButtonWidget] to display [button].
  const ImageButtonWidget({@required this.button, Key key})
      : assert(button != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => button.action.act(context, button),
        child: Image.asset(button.imageUri.toString()),
      );
}
