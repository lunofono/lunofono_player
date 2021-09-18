@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Orientation, Action;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show GridMenu, Button, Action, Menu;
import 'package:lunofono_player/src/action_player.dart'
    show ActionPlayer, ActionPlayerRegistry;
import 'package:lunofono_player/src/button_player.dart'
    show ButtonPlayer, ButtonPlayerRegistry;
import 'package:lunofono_player/src/menu_player/grid_menu_player.dart';

import 'package:lunofono_player/src/menu_player.dart';

void main() {
  group('MenuPlayer', () {
    final oldActionRegistry = ActionPlayer.registry;
    final oldButtonRegistry = ButtonPlayer.registry;

    setUp(() {
      ActionPlayer.registry = ActionPlayerRegistry();
      ActionPlayer.registry.register(
          _FakeAction, (action) => _FakeActionPlayer(action as _FakeAction));

      ButtonPlayer.registry = ButtonPlayerRegistry();
      ButtonPlayer.registry
          .register(_FakeButton, (b) => _FakeButtonPlayer(b as _FakeButton));
    });

    tearDown(() {
      ActionPlayer.registry = oldActionRegistry;
      ButtonPlayer.registry = oldButtonRegistry;
    });

    group('MenuPlayerRegistry', () {
      final oldMenuRegistry = MenuPlayer.registry;
      _FakeContext? fakeContext;
      late _FakeMenu fakeMenu;

      setUp(() {
        fakeContext = _FakeContext();
        fakeMenu = _FakeMenu();
      });

      tearDown(() => MenuPlayer.registry = oldMenuRegistry);

      test('empty', () {
        MenuPlayer.registry = MenuPlayerRegistry();
        expect(MenuPlayer.registry, isEmpty);
        expect(() => MenuPlayer.wrap(fakeMenu), throwsAssertionError);
      });

      test('registration and calling from empty', () {
        MenuPlayer.registry = MenuPlayerRegistry();
        MenuPlayer.registry
            .register(_FakeMenu, (m) => _FakeMenuPlayer(m as _FakeMenu));

        final builtWidget = MenuPlayer.wrap(fakeMenu).build(fakeContext!);
        expect(fakeMenu.buildCalls.length, 1);
        expect(fakeMenu.buildCalls.last.context, same(fakeContext));
        expect(fakeMenu.buildCalls.last.returnedWidget, same(builtWidget));
      });

      test('builtins are registered', () {
        final fakeButtonRed = _FakeButton(Colors.red);
        final fakeButtonBlue = _FakeButton(Colors.blue);
        Menu menu = GridMenu(
          rows: 1,
          columns: 2,
          buttons: [
            fakeButtonRed,
            fakeButtonBlue,
          ],
        );
        expect(MenuPlayer.wrap(menu), isA<GridMenuPlayer>());
      });
    });
  });
}

class _FakeContext extends Fake implements BuildContext {}

class _BuildCall {
  final BuildContext context;
  final Widget returnedWidget;
  _BuildCall(this.context, this.returnedWidget);
}

class _FakeMenu extends Menu {
  final buildCalls = <_BuildCall>[];
}

class _FakeMenuPlayer extends MenuPlayer {
  @override
  final _FakeMenu menu;
  _FakeMenuPlayer(this.menu);
  static Key globalKey = GlobalKey(debugLabel: 'FakeMenuPlayerKey');
  @override
  Widget build(BuildContext context) {
    final widget = Container(child: const Text('FakeMenu'), key: globalKey);
    menu.buildCalls.add(_BuildCall(context, widget));
    return widget;
  }
}

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
