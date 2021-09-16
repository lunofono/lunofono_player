@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Orientation, Action;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show GridMenu, Button, Action;
import 'package:lunofono_player/src/action_player.dart'
    show ActionPlayer, ActionPlayerRegistry;
import 'package:lunofono_player/src/button_player.dart'
    show ButtonPlayer, ButtonPlayerRegistry;

import 'package:lunofono_player/src/menu_player/grid_menu_player.dart';

void main() {
  final oldActionRegistry = ActionPlayer.registry;
  final oldButtonRegistry = ButtonPlayer.registry;

  _FakeButton fakeButtonRed;
  _FakeButton fakeButtonBlue;
  late GridMenu menu;
  GridMenuPlayer? menuPlayer;

  setUp(() {
    ActionPlayer.registry = ActionPlayerRegistry();
    ActionPlayer.registry.register(
        _FakeAction, (action) => _FakeActionPlayer(action as _FakeAction));

    ButtonPlayer.registry = ButtonPlayerRegistry();
    ButtonPlayer.registry
        .register(_FakeButton, (b) => _FakeButtonPlayer(b as _FakeButton));

    fakeButtonRed = _FakeButton(Colors.red);
    fakeButtonBlue = _FakeButton(Colors.blue);
    menu = GridMenu(
      rows: 2,
      columns: 1,
      buttons: [
        fakeButtonRed,
        fakeButtonBlue,
      ],
    );
    menuPlayer = GridMenuPlayer(menu);
  });

  tearDown(() {
    ActionPlayer.registry = oldActionRegistry;
    ButtonPlayer.registry = oldButtonRegistry;
  });

  group('GridMenuPlayer', () {
    setUp(() {});

    testWidgets('build() builds the right widgets',
        (WidgetTester tester) async {
      // Matches the underlaying menu
      expect(menuPlayer!.rows, menu.rows);
      expect(menuPlayer!.columns, menu.columns);
      expect(menuPlayer!.buttons.first.button, menu.buttonAt(0, 0));

      // Build returns a GridMenuWidget
      final menuWidget = menuPlayer!.build(_FakeContext());
      expect(menuWidget, isA<GridMenuWidget>());
      expect((menuWidget as GridMenuWidget).menu, same(menuPlayer));
    });
  });

  group('GridMenuWidget', () {
    testWidgets('shows all buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            child: Builder(
              builder: (context) => menuPlayer!.build(context),
            ),
          ),
        ),
      );
      expect(find.byType(GridMenuWidget), findsOneWidget);
      expect(find.byType(GridMenuRowWidget), findsNWidgets(2));
      expect(find.byKey(ObjectKey(menu.buttons.first)), findsOneWidget);
      expect(find.byKey(ObjectKey(menu.buttons.last)), findsOneWidget);
    });
  });

  group('GridMenuRowWidget', () {
    testWidgets('shows all buttons in the row', (WidgetTester tester) async {
      Widget fakeApp(Widget row) => MaterialApp(
            home: Column(
              children: <Widget>[row],
            ),
          );

      await tester
          .pumpWidget(fakeApp(GridMenuRowWidget(menu: menuPlayer!, row: 0)));
      expect(find.byKey(ObjectKey(menu.buttons.first)), findsOneWidget);
      expect(find.byKey(ObjectKey(menu.buttons.last)), findsNothing);

      await tester
          .pumpWidget(fakeApp(GridMenuRowWidget(menu: menuPlayer!, row: 1)));
      expect(find.byKey(ObjectKey(menu.buttons.first)), findsNothing);
      expect(find.byKey(ObjectKey(menu.buttons.last)), findsOneWidget);
    });
  });
}

class _FakeContext extends Fake implements BuildContext {}

class _FakeAction extends Action {
  final actCalls = <ButtonPlayer>[];
  @override
  String toString() => '$runtimeType($actCalls)';
}

class _FakeActionPlayer extends ActionPlayer {
  @override
  final _FakeAction action;
  _FakeActionPlayer(this.action);
  @override
  void act(BuildContext context, ButtonPlayer button) =>
      action.actCalls.add(button);
  @override
  String toString() => '$runtimeType($action)';
}

class _FakeButton extends Button {
  final Color color;
  _FakeButton(this.color) : super(_FakeAction());
  final createCalls = <Widget>[];
  List<ButtonPlayer> get actCalls => (action as _FakeAction).actCalls;
  @override
  String toString() => '$runtimeType($color, $createCalls)';
}

class _FakeButtonPlayer extends ButtonPlayer {
  @override
  final _FakeButton button;
  @override
  Widget build(BuildContext context) {
    final widget = TextButton(
      key: ObjectKey(button),
      onPressed: () => action.act(context, this),
      child: const Text(''),
    );
    button.createCalls.add(widget);
    return widget;
  }

  _FakeButtonPlayer(this.button) : super(button);
}
