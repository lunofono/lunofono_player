import 'package:flutter/material.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart' show GridMenu;

import '../button_player.dart' show ButtonPlayer;
import '../menu_player.dart' show MenuPlayer;

class GridMenuPlayer extends MenuPlayer {
  /// The [GridMenu] that this widget represents.
  @override
  final GridMenu menu;

  /// The number of rows in the underlaying [menu].
  int get rows => menu.rows;

  /// The number of columns in the underlaying [menu].
  int get columns => menu.columns;

  /// The list of [ButtonPlayer]s wrapping this [menu.buttons].
  final List<ButtonPlayer> buttons;

  /// Gets the [Button] at position ([row], [column]) in the grid.
  ///
  /// TODO: Swap rows and cols if the orientation is forced?
  ButtonPlayer buttonAt(int row, int column) => buttons[row * columns + column];

  /// Constructs a [GridMenuPlayer] from a [GridMenu].
  ///
  /// This also wrap all the [menu.buttons] to store [ButtonPlayer]s instead.
  GridMenuPlayer(this.menu)
      : buttons = List<ButtonPlayer>.from(
            menu.buttons.map<ButtonPlayer>((b) => ButtonPlayer.wrap(b)));

  /// Builds the UI for this [menu].
  @override
  Widget build(BuildContext context) {
    return GridMenuWidget(menu: this);
  }
}

/// A Widget to play a [GridMenu].
class GridMenuWidget extends StatelessWidget {
  /// The [GridMenu] that this widget represents.
  final GridMenuPlayer menu;

  /// The padding to leave between buttons and this widget's container.
  final double padding;

  /// Creates a new [GridMenuWidget] for [menu].
  const GridMenuWidget({
    required this.menu,
    this.padding = 10.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: List<Widget>.generate(
          menu.rows,
          (row) => GridMenuRowWidget(row: row, menu: menu, padding: padding),
          growable: false,
        ),
      ),
    );
  }
}

/// A Widget to display a [GridMenuWidget] row of buttons.
class GridMenuRowWidget extends StatelessWidget {
  /// The row this widget is displaying.
  final int row;

  /// The menu this widget is displaying.
  final GridMenuPlayer menu;

  /// The padding to leave around the buttons.
  final double padding;

  /// Creates a new [GridMenuRowWidget] to display the [row] row from [menu].
  const GridMenuRowWidget({
    required this.row,
    required this.menu,
    this.padding = 10.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List<Widget>.generate(
            menu.columns,
            (column) => Expanded(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: menu.buttonAt(row, column).build(context),
              ),
            ),
            growable: false,
          ),
        ),
      );
}
